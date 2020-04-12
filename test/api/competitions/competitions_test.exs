defmodule Api.CompetitionsTest do
  use Api.DataCase
  use Bamboo.Test, shared: true

  alias Api.Competitions
  alias Api.Competitions.{Competition, Attendance}
  alias Api.Notifications.Emails

  setup do
    c1 = create_competition()
    c2 = create_competition()
    user = create_user()
    attendance = create_competition_attendance(c1, user)

    {
      :ok,
      %{
        c1: c1,
        c2: c2,
        user: user,
        attendance: attendance,
      },
    }
  end

  test "list competitions", %{c1: c1, c2: c2} do
    competitions = Competitions.list_competitions()

    assert competitions == [c1, c2]
    assert length(competitions) == 2
  end

  test "default competition" do
    {:ok, competition} = Competitions.create_competition(%{name: "new competition", is_default: true})

    assert competition.id == Competitions.default_competition().id
  end

  test "get competition", %{c1: c1} do
    competition = Competitions.get_competition(c1.id)

    assert competition
    assert competition.id == c1.id
  end

  test "create competition" do
    {:ok, competition} = Competitions.create_competition(%{name: "new competition"})

    assert Repo.get(Competition, competition.id)
  end

  test "update competition", %{c1: c1} do
    Competitions.update_competition(c1.id, %{name: "updated competition"})
    competition = Repo.get(Competition, c1.id)

    assert competition.name == "updated competition"
  end

  test "delete competition" do
    competition = create_competition()
    Competitions.delete_competition(competition.id)

    refute Repo.get(Competition, competition.id)
  end

  test "get attendance by id", %{attendance: attendance} do
    assert Competitions.get_attendance(attendance.id)
  end

  test "get attendance by competition id and attendee", %{c1: c1, user: u1} do
    assert Competitions.get_attendance(c1.id, u1.id)
  end

  test "create attendance", %{c2: c2, user: u1} do
    {:ok, attendance} = Competitions.create_attendance(c2.id, u1.id)

    assert Repo.get(Attendance, attendance.id)
  end

  test "can't create duplicate attendance", %{c1: c1, user: u1} do
    {:error, changeset} = Competitions.create_attendance(c1.id, u1.id)

    assert changeset.errors != nil
  end

  test "delete attendance by id", %{attendance: attendance} do
    Competitions.delete_attendance(attendance.id)

    refute Repo.get(Attendance, attendance.id)
  end

  test "delete attendance by competition id and attendee", %{c1: c1, user: u1} do
    {:ok, attendance} = Competitions.delete_attendance(c1.id, u1.id)

    refute Repo.get(Attendance, attendance.id)
  end

  test "toggle checkin works", %{c1: c1, user: user} do
    Competitions.toggle_checkin(c1.id, user.id, true)

    a1 = Competitions.get_attendance(c1.id, user.id)

    assert a1.checked_in == true
    assert_delivered_email Emails.checkin_email(user)

    Competitions.toggle_checkin(c1.id, user.id, false)

    a2 = Competitions.get_attendance(c1.id, user.id)

    assert a2.checked_in == false
  end
end
