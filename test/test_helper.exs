ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Api.Repo, :manual)

defmodule ApiWeb.TestHelper do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Events.{Event, Attendance}
  alias Api.Teams.{Team, Membership, Invite}
  alias Api.Competitions
  alias Api.Competitions.Competition
  alias Api.Teams
  alias Api.Suffrages.{Suffrage, Vote, PaperVote}
  alias Api.Competitions.Attendance, as: CompAttendance

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

  @valid_competition_attrs %{
    name: "awesome competition",
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

  def create_attendee(competition) do
    user = create_user()
    create_competition_attendance(competition, user)

    user
  end

  def create_attendance_with_user(competition) do
    user = create_user()

    create_competition_attendance(competition, user)
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

  def create_team(user, competition, params \\ %{}) do
    params = Map.merge(params, %{name: "awesome team #{to_string(:rand.uniform())}"})
    team = %Team{competition_id: competition.id}
    |> Team.changeset(params)
    |> Repo.insert!

    create_membership(team, user)

    team
  end

  def create_competition(params \\ @valid_competition_attrs) do
    %Competition{}
    |> Competition.changeset(params)
    |> Repo.insert!
  end

  def create_competition_attendance(competition, user) do
    %CompAttendance{}
    |> CompAttendance.changeset(%{competition_id: competition.id, attendee: user.id})
    |> Repo.insert!
  end

  def create_event(params \\ @valid_event_attrs) do
    %Event{}
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

  def create_suffrage(competition_id) do
    %Suffrage{}
    |> Suffrage.changeset(
      %{
        name: "awesome #{to_string(:rand.uniform())}",
        slug: "awesome #{to_string(:rand.uniform())}",
        competition_id: competition_id
      }
    )
    |> Repo.insert!
  end

  def check_in_everyone(competition_id, people \\ nil) do
    people = people || Repo.all(from u in User, where: u.role == "participant")

    people
    |> Enum.map(fn user ->
      Competitions.toggle_checkin(competition_id, user.id)
    end)
  end

  def make_teams_eligible(competition_id, teams \\ nil) do
    teams = teams || Repo.all(from t in Team, where: t.competition_id == ^competition_id)

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
