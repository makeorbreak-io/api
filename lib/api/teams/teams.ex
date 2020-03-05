defmodule Api.Teams do
  import Ecto.Query, warn: false

  @slack_token Application.get_env(:api, :slack_token)
  @team_user_limit Application.get_env(:api, :team_user_limit)
  @http Application.get_env(:api, :http_lib)

  alias Api.{Mailer, Repo}
  alias Api.Accounts.User
  alias Api.Competitions
  alias Api.Teams.{Invite, Membership, Team}
  alias Api.Notifications.Emails
  alias Ecto.{Changeset}

  def list_teams do
    Repo.all(Team)
  end

  def with_project do
    from(t in Team,
      where: not is_nil(t.project_name),
      where: not is_nil(t.project_desc)
    )
    |> Repo.all
  end

  def get_team(id) do
    Repo.get!(Team, id)
  end

  def create_team(current_user, team_params) do
    changeset = Team.changeset(%Team{}, team_params)

    IO.inspect Repo.insert(changeset)

    case Repo.insert(changeset) do
      {:ok, team} ->
        Repo.insert! %Membership{
          id: nil,
          user_id: current_user.id,
          team_id: team.id,
          role: "owner"
        }

        {:ok, team}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update_team(current_user, id, team_params) do
    team = get_team(id)

    if is_team_member?(team, current_user) do
      Team.changeset(team, team_params)
      |> email_if_applying(team)
      |> Repo.update
    else
      {:unauthorized, :unauthorized}
    end
  end

  def update_any_team(id, team_params) do
    team = get_team(id)

    Team.admin_changeset(team, team_params)
    |> email_if_applying(team)
    |> email_if_accepted(team)
    |> Repo.update
  end

  def accept_team(id) do
    team = get_team(id)

    changeset = Team.admin_changeset(team, %{accepted: true})
    |> email_if_accepted(team)

    case Repo.update(changeset) do
      {:ok, team} ->
        members = Repo.all Ecto.assoc(team, :members)
        Enum.map(members, fn(member) ->
          Competitions.create_attendance(team.competition_id, member.id)
        end)

        {:ok, team}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_team(current_user, id) do
    team = Repo.get!(Team, id)

    case is_team_member?(team, current_user) do
      true -> Repo.delete(team)
      false -> {:unauthorized, :unauthorized}
    end
  end

  def delete_any_team(id) do
    Repo.get!(Team, id) |> Repo.delete
  end

  def remove_membership(current_user, team_id, user_id) do
    team = Repo.get!(Team, team_id)
    user = Repo.get(User, user_id) || throw :user_not_found

    if !is_team_member?(team, current_user) do
      throw {:unauthorized, :unauthorized}
    end

    if team.applied do
      throw :team_locked
    end

    case Repo.delete_all(from(
        t in Membership,
        where: t.user_id == ^user.id and t.team_id == ^team.id
    )) do
      {1, _} -> :ok
      {0, _} -> :membership_not_found
    end
  catch
    e -> e
  end

  def remove_any_membership(team_id, user_id) do
    user = Repo.get(User, user_id) || throw :user_not_found
    case Repo.delete_all(from(
        t in Membership,
        where: t.user_id == ^user.id and t.team_id == ^team_id
    )) do
      {1, _} -> {:ok, get_team(team_id)}
      {0, _} -> {:error, :membership_not_found}
    end
  catch
    e -> e
  end

  def list_user_invites(user) do
    Invite
    |> where(invitee_id: ^user.id)
    |> Repo.all
  end

  def get_invite(id) do
    Repo.get(Invite, id)
  end

  def create_invite(user_id, team_id, invite_params) do
    user = Repo.get(User, user_id)
    team = Repo.get(Team, team_id)

    if is_team_member?(team, user) do
      create_invite_if_vacant(user, team, invite_params)
    else
      :unauthorized
    end
  end

  def accept_invite(current_user, id) do
    invite = Repo.get(Invite, id)

    case invite do
      nil -> :invite_not_found
      invite ->
        if current_user.id == invite.invitee_id do
          create_membership(invite)
          {:ok, Repo.get(User, current_user.id)}
        else
          {:error, :unauthorized}
        end
    end
  end

  def reject_invite(current_user, id) do
    invite = Repo.get(Invite, id)

    case invite do
      nil -> :invite_not_found
      invite ->
        if current_user.id == invite.invitee_id do
          Repo.delete(invite)
          {:ok, Repo.get(User, current_user.id)}
        else
          {:error, :unauthorized}
        end
    end
  end

  def delete_invite(current_user, id) do
    invite = Repo.get!(Invite, id)
    team = (invite |> Repo.preload(:team)).team

    if is_team_member?(team, current_user) do
      Repo.delete(invite)
      {:ok, team}
    else
      {:error, :unauthorized}
    end
  end

  def associate_invites_with_user(email, id) do
    from(i in Invite, where: i.email == ^email, update: [
      set: [invitee_id: ^id]
    ]) |> Repo.update_all([])
  end

  def invite_to_slack(email) do
    base_url = "https://makeorbreak-io.slack.com/api/users.admin.invite"
    params = URI.encode_query(%{token: @slack_token, email: email})
    url = base_url <> "?" <> params
    headers = %{"Content-Type" => "application/x-www-form-urlencoded"}

    with {:ok, response} <- @http.post(url, "", headers), do: process_slack_invite(response)
  end

  defp is_team_member?(team, user) do
    members = Repo.all Ecto.assoc(team, :members)

    Enum.any?(members, fn(member) ->
      member.id == user.id
    end)
  end

  defp email_if_applying(changeset, team) do
    applied_change = Map.has_key?(changeset.changes, :applied)
    applied_true = Map.get(changeset.changes, :applied) == true

    if applied_change and applied_true do
      members = Repo.all Ecto.assoc(team, :members)
      Enum.map(members, fn(member) ->
        Emails.joined_hackathon_email(member, team) |> Mailer.deliver_later
      end)
    end

    changeset
  end

  defp email_if_accepted(changeset, team) do
    accepted_change = Map.has_key?(changeset.changes, :accepted)
    accepted_true = Map.get(changeset.changes, :accepted) == true

    if accepted_change and accepted_true do
      members = Repo.all Ecto.assoc(team, :members)
      Enum.map(members, fn(member) ->
        Emails.team_acceptance(member) |> Mailer.deliver_later
      end)
    end

    changeset
  end

  defp create_invite_if_vacant(user, team, invite_params) do
    team = Repo.preload(team, :invites)
    members = Repo.all Ecto.assoc(team, :members)

    team_size = Enum.count(team.invites) + Enum.count(members)

    if team_size < @team_user_limit do
      changeset = Invite.changeset(%Invite{
        host_id: user.id,
        team_id: team.id,
      }, invite_params)
      |> maybe_associate_user()
      |> process_email(user)

      Repo.insert(changeset)
    else
      :team_user_limit
    end
  end

  defp maybe_associate_user(changeset) do
    if Map.has_key?(changeset.changes, :email) do
      case Repo.get_by(User, email: Map.get(changeset.changes, :email)) do
        nil -> changeset
        user ->
          Changeset.delete_change(changeset, :email)
          |> Changeset.put_change(:invitee_id, user.id)
      end
    else
      changeset
    end
  end

  defp process_email(changeset, host) do
    cond do
      Map.has_key?(changeset.changes, :email) -> send_invite_email(changeset, host)
      Map.has_key?(changeset.changes, :invitee_id) -> send_notification_email(changeset, host)
      true -> nil
    end
  end

  defp create_membership(invite) do
    user = Repo.get!(User, invite.invitee_id)

    changeset = Membership.changeset(
      %Membership{},
      %{user_id: invite.invitee_id, team_id: invite.team_id}
    )

    if User.can_apply_to_hackathon(user) do
      case Repo.insert(changeset) do
        {:ok, membership} ->
          Repo.delete(invite)
          {:ok, membership}
        {:error, _} -> {:error, "Unable to create membership"}
      end
    else
      :user_cant_apply
    end
  end

  defp send_invite_email(changeset, host) do
    Map.get(changeset.changes, :email)
    |> Emails.invite_email(host)
    |> Mailer.deliver_later

    changeset
  end

  defp send_notification_email(changeset, host) do
    Repo.get(User, Map.get(changeset.changes, :invitee_id))
    |> Emails.invite_notification_email(host)
    |> Mailer.deliver_later

    changeset
  end

  defp process_slack_invite(response) do
    case Poison.decode! response.body do
      %{"ok" => true} -> {:ok, true}
      %{"ok" => false, "error" => error} ->
        message = message(String.to_atom(error))
        {:error, %Ecto.Changeset{
          valid?: false,
          types: %{email: :string},
          errors: [email: {message, []}],
        }}
    end
  end

  defp message(:already_invited), do: "was already invited"
  defp message(:already_in_team), do: "is already in the team"
  defp message(:missing_scope), do: "couldn't be invited at this time"
  defp message(:invalid_email), do: "isn't valid"
  defp message(:channel_not_found), do: "couldn't join inexistent channel"
  defp message(:user_disabled), do: "account has been deactivated"
  defp message(:sent_recently), do: "was invited recently"
  defp message(:not_authed), do: "not authorized"
end
