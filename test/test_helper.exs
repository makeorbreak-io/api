ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule ApiWeb.TestHelper do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Events.{Event, Attendance}
  alias Api.Teams.{Team, Membership, Invite}
  alias Api.Editions
  alias Api.Editions.Edition
  alias Api.Teams
  alias Api.Suffrages.{Suffrage, Vote, PaperVote}
  alias Api.Editions.Attendance, as: EditionAttendance

  @valid_user_attrs %{
    name: "john doe",
    password: "thisisapassword",
    github_handle: "https://github.com/nunopolonia"
  }

  @valid_event_attrs %{
    name: "awesome event",
    participant_limit: 1,
    short_date: "SUNDAY 10TH — 10:30",
    type: "workshop"
  }

  @valid_edition_attrs %{
    name: "awesome edition",
  }

  defp add_email(params) do
    Map.merge(
      %{email: "#{to_string(:rand.uniform())}@email.com"},
      params
    )
  end

  defp add_slug(params) do
    Map.merge(%{slug: "event-#{to_string(:rand.uniform())}"}, params)
  end

  def create_user(params \\ @valid_user_attrs) do
    %User{}
    |> User.registration_changeset(
      params
      |> add_email
    )
    |> Repo.insert!
  end

  def create_attendee(edition) do
    user = create_user()
    create_edition_attendance(edition, user)

    user
  end

  def create_attendance_with_user(edition) do
    user = create_user()

    create_edition_attendance(edition, user)
  end

  def create_admin(params \\ @valid_user_attrs) do
    %User{}
    |> User.admin_changeset(
      params
      |> add_email
      |> Map.merge(%{role: "admin"})
    )
    |> Repo.insert!
  end

  def create_team(user, edition, params \\ %{}) do
    params = Map.merge(params, %{name: "awesome team #{to_string(:rand.uniform())}"})
    team = %Team{edition_id: edition.id}
    |> Team.changeset(params)
    |> Repo.insert!

    create_membership(team, user)

    team
  end

  def create_edition(params \\ @valid_edition_attrs) do
    %Edition{}
    |> Edition.changeset(params)
    |> Repo.insert!
  end

  def create_edition_attendance(edition, user) do
    %EditionAttendance{}
    |> EditionAttendance.changeset(%{edition_id: edition.id, attendee: user.id})
    |> Repo.insert!
  end

  def create_event(edition, params \\ @valid_event_attrs) do
    %Event{edition_id: edition.id}
    |> Event.changeset(params |> add_slug)
    |> Repo.insert!
  end

  def create_event_attendance(event, user) do
    Repo.insert! %Attendance{event_id: event.id, user_id: user.id}
    Event.changeset(event, %{participants_counter: event.participants_counter + 1})
    |> Repo.update()
  end

  def create_id_invite(team, host, user) do
    %Invite{}
    |> Invite.changeset(%{
      invitee_id: user.id,
      team_id: team.id,
      host_id: host.id
    })
    |> Repo.insert!
  end

  def create_email_invite(team, host, email) do
    %Invite{}
    |> Invite.changeset(%{
      email: email,
      team_id: team.id,
      host_id: host.id
    })
    |> Repo.insert!
  end

  def create_membership(team, user) do
    %Membership{}
    |> Membership.changeset(%{
      user_id: user.id,
      team_id: team.id,
    })
    |> Repo.insert!
  end

  def create_suffrage(edition_id) do
    %Suffrage{}
    |> Suffrage.changeset(
      %{
        name: "awesome #{to_string(:rand.uniform())}",
        slug: "awesome #{to_string(:rand.uniform())}",
        edition_id: edition_id
      }
    )
    |> Repo.insert!
  end

  def check_in_everyone(edition_id, people \\ nil) do
    people = people || Repo.all(from u in User, where: u.role == "participant")

    people
    |> Enum.map(fn user ->
      Editions.toggle_checkin(edition_id, user.id)
    end)
  end

  def make_teams_eligible(edition_id, teams \\ nil) do
    teams = teams || Repo.all(from t in Team, where: t.edition_id == ^edition_id)

    teams
    |> Enum.map(fn team ->
      {:ok, team} = Teams.update_any_team(team.id, %{eligible: true})
      team
    end)
  end

  def create_vote(attendance, suffrage, ballot) do
    %Vote{}
    |> Vote.changeset(
      %{
        voter_identity: attendance.voter_identity,
        suffrage_id: suffrage.id,
        ballot: ballot
      }
    )
    |> Repo.insert!
  end

  def create_paper_vote(suffrage, admin) do
    %PaperVote{}
    |> PaperVote.changeset(
      %{
        created_by_id: admin.id,
        suffrage_id: suffrage.id
      }
    )
    |> Repo.insert!
  end

  def annul_paper_vote(paper_vote, admin) do
    pv = Repo.get!(PaperVote, paper_vote.id)

    PaperVote.changeset(pv,
      %{
        annulled_by_id: admin.id,
        annulled_at: DateTime.utc_now,
      }
    )
    |> Repo.update!
  end

  def redeem_paper_vote(paper_vote, team, member, admin) do
    pv = Repo.get!(PaperVote, paper_vote.id)

    PaperVote.changeset(pv,
      %{
        redeemed_admin_id: admin.id,
        redeemed_at: DateTime.utc_now,
        redeeming_member_id: member.id,
        team_id: team.id
      }
    )
    |> Repo.update!
    pv
  end
end
