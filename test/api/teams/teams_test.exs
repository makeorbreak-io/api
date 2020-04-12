defmodule Api.TeamsTest do
  use Api.DataCase
  use Bamboo.Test, shared: true

  alias Api.Teams
  alias Api.Teams.{Team, Invite, Membership}
  alias Api.Competitions
  alias Api.Notifications.Emails

  @valid_attrs %{name: "awesome team"}

  @invalid_attrs %{name: nil}

  setup do
    u1 = create_user()
    c1 = create_competition()
    t1 = create_team(u1, c1)

    {:ok, %{u1: u1, c1: c1, t1: t1}}
  end

  test "list teams", %{u1: u1, c1: c1, t1: t1} do
    t2 = create_team(u1, c1)
    teams = Teams.list_teams()

    assert teams == [t1, t2]
    assert length(teams) == 2
  end

  test "get team", %{t1: t1} do
    assert Teams.get_team(t1.id) == t1
  end

  test "create valid team", %{u1: u1, c1: c1} do
    params = Map.merge(@valid_attrs, %{competition_id: c1.id})
    {:ok, team} = Teams.create_team(u1, params)

    assert Repo.get(Team, team.id)
  end

  test "create invalid team", %{u1: u1} do
    {:error, changeset} = Teams.create_team(u1, @invalid_attrs)
    assert changeset.valid? == false
  end

  test "update team with valid data", %{u1: u1, t1: t1} do
    {:ok, _} = Teams.update_team(u1, t1.id, @valid_attrs)

    assert Repo.get_by(Team, name: "awesome team")
  end

  test "update team with invalid data", %{u1: u1, t1: t1} do
    {:error, changeset} = Teams.update_team(u1, t1.id, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "update team if user not authorized", %{t1: t1} do
    u2 = create_user()

    result = Teams.update_team(u2, t1.id, @valid_attrs)
    assert result == {:unauthorized, :unauthorized}
  end

  test "apply team to competition", %{u1: u1, t1: t1} do
    u2 = create_user()
    create_membership(t1, u2)

    {:ok, team} = Teams.update_team(u1, t1.id, Map.merge(@valid_attrs, %{applied: true}))

    assert team.applied == true
    assert_delivered_email Emails.joined_hackathon_email(u1, t1)
  end

  test "update any team with valid data", %{t1: t1} do
    {:ok, _} = Teams.update_any_team(t1.id, @valid_attrs)

    assert Repo.get_by(Team, name: "awesome team")
  end

  test "update any team with invalid data", %{t1: t1} do
    {:error, changeset} = Teams.update_any_team(t1.id, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "accept team into competition", %{t1: t1, u1: u1} do
    {:ok, t2} = Teams.accept_team(t1.id)

    assert t2.accepted == true
    assert Competitions.get_attendance(t2.competition_id, u1.id)

  end

  test "delete team", %{u1: u1, t1: t1} do
    {:ok, team} = Teams.delete_team(u1, t1.id)

    refute Repo.get_by(Team, name: team.name)
  end

  test "delete team if user not authorized", %{t1: t1} do
    u2 = create_user()

    result = Teams.delete_team(u2, t1.id)
    assert result == {:unauthorized, :unauthorized}
  end

  test "delete any team", %{t1: t1} do
    {:ok, team} = Teams.delete_any_team(t1.id)

    refute Repo.get_by(Team, name: team.name)
  end

  test "remove membership by authorized user", %{u1: u1, t1: t1} do
    u2 = create_user()
    create_membership(t1, u2)

    assert Teams.remove_membership(u1, t1.id, u2.id) == :ok
    refute Repo.get_by(Membership, team_id: t1.id, user_id: u2.id)
  end

  test "remove membership by unauthorized user", %{t1: t1} do
    u2 = create_user()
    u3 = create_user()
    create_membership(t1, u2)

    assert Teams.remove_membership(u3, t1.id, u2.id) == {:unauthorized, :unauthorized}
  end

  test "remove membership of applied team", %{u1: u1, c1: c1} do
    t2 = create_team(u1, c1, %{name: "awesome team", applied: true})
    u2 = create_user()
    create_membership(t2, u2)

    assert Teams.remove_membership(u1, t2.id, u2.id) == :team_locked
  end

  test "remove membership of nonexistent user", %{u1: u1, t1: t1} do
    u2 = create_user()
    create_membership(t1, u2)

    assert Teams.remove_membership(u1, t1.id, Ecto.UUID.generate()) == :user_not_found
  end

  test "remove nonexistent membership", %{u1: u1, t1: t1} do
    u2 = create_user()

    assert Teams.remove_membership(u1, t1.id, u2.id) == :membership_not_found
  end

  test "remove any membership", %{t1: t1} do
    u2 = create_user()
    create_membership(t1, u2)

    assert Teams.remove_any_membership(t1.id, u2.id) == {:ok, t1}
    refute Repo.get_by(Membership, team_id: t1.id, user_id: u2.id)
  end

  test "remove any membership of nonexistent user", %{t1: t1} do
    assert Teams.remove_any_membership(t1.id, Ecto.UUID.generate()) == :user_not_found
  end

  test "remove any nonexistent membership", %{t1: t1} do
    u2 = create_user()
    assert Teams.remove_any_membership(t1.id, u2.id) == {:error, :membership_not_found}
  end

  test "list user invites", %{u1: u1, c1: c1, t1: t1} do
    t2 = create_team(u1, c1)
    u2 = create_user()

    i1 = create_id_invite(t1, u1, u2)
    i2 = create_id_invite(t2, u1, u2)

    invites = Teams.list_user_invites(u2)

    assert Enum.sort(invites) == Enum.sort([i2, i1])
    assert length(invites) == 2
  end

  test "get invite", %{u1: u1, t1: t1} do
    u2 = create_user()
    i1 = create_id_invite(t1, u1, u2)

    assert Teams.get_invite(i1.id) == i1
  end

  test "get nonexistent invite" do
    assert Teams.get_invite("11111111-1111-1111-1111-111111111111") == nil
  end

  test "create invite by ID", %{u1: u1, t1: t1} do
    u2 = create_user()

    {:ok, invite} = Teams.create_invite(u1.id, t1.id, %{invitee_id: u2.id})

    assert Repo.get(Invite, invite.id)
    assert_delivered_email Emails.invite_notification_email(u2, u1)
  end

  test "create invite by email of registered user", %{u1: u1, t1: t1} do
    u2 = create_user()

    {:ok, invite} = Teams.create_invite(u1.id, t1.id, %{email: u2.email})

    assert invite.invitee_id == u2.id
    assert Repo.get(Invite, invite.id)
    assert_delivered_email Emails.invite_notification_email(u2, u1)
  end

  test "create invite by email of unregistered user", %{u1: u1, t1: t1} do
    {:ok, invite} = Teams.create_invite(u1.id, t1.id, %{email: "unregistered@example.com"})

    assert invite.invitee_id == nil
    assert Repo.get(Invite, invite.id)
    assert_delivered_email Emails.invite_email("unregistered@example.com", u1)
  end

  test "create invite if host isn't team member", %{u1: u1, t1: t1} do
    u2 = create_user()

    assert Teams.create_invite(u2.id, t1.id, %{invitee_id: u1.id}) == :unauthorized
  end

  test "create invite if user limit is reached", %{u1: u1, t1: t1} do
    u2 = create_user()
    create_membership(t1, create_user())
    create_membership(t1, create_user())
    create_email_invite(t1, u1, "unregistered@example.com")

    assert Teams.create_invite(u1.id, t1.id, %{invitee_id: u2.id}) == :team_user_limit
  end

  test "create duplicate invite", %{u1: u1, t1: t1} do
    u2 = create_user()

    create_id_invite(t1, u1, u2)

    {:error, changeset} = Teams.create_invite(u1.id, t1.id, %{invitee_id: u2.id})

    assert changeset.valid? == false
  end

  test "accept invite", %{u1: u1, t1: t1} do
    u2 = create_user()
    i1 = create_id_invite(t1, u1, u2)

    {:ok, user} = Teams.accept_invite(u2, i1.id)

    assert user.id == u2.id

    team = Repo.get(Team, t1.id)
    members = Repo.all Ecto.assoc(team, :members)

    assert Enum.count(members) == 2
  end

  test "accept nonexistent invite", %{u1: u1} do
    assert Teams.accept_invite(u1, Ecto.UUID.generate()) == :invite_not_found
  end

  test "delete invite", %{u1: u1, t1: t1} do
    u2 = create_user()
    i1 = create_id_invite(t1, u1, u2)

    {:ok, invite} = Teams.delete_invite(u1, i1.id)

    refute Repo.get(Invite, invite.id)
  end

  test "associate invites with user", %{u1: u1, t1: t1} do
    user = create_user(%{email: "user@example.com", password: "thisisapassword"})
    create_email_invite(t1, u1, "user@example.com")
    Teams.associate_invites_with_user(user.email, user.id)

    assert Repo.get_by(Invite, invitee_id: user.id)
  end

  test "invite to slack with valid email" do
    assert Teams.invite_to_slack("valid@example.com") == {:ok, true}
  end

  test "invite to slack with invalid email" do
    {:error, changeset} = Teams.invite_to_slack("error@example.com")

    assert changeset.valid? == false
  end
end
