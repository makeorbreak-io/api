defmodule Api.EditionsTest do
  use Api.DataCase
  use Bamboo.Test, shared: true

  alias Api.Editions
  alias Api.Editions.{Edition, Attendance}
  alias Api.Notifications.Emails

  setup do
    c1 = create_edition()
    c2 = create_edition()
    user = create_user()
    attendance = create_edition_attendance(c1, user)

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

  test "list editions", %{c1: c1, c2: c2} do
    editions = Editions.list_editions()

    assert editions == [c1, c2]
    assert length(editions) == 2
  end

  test "default edition" do
    {:ok, edition} = Editions.create_edition(%{name: "new edition", is_default: true})

    assert edition.id == Editions.default_edition().id
  end

  test "get edition", %{c1: c1} do
    edition = Editions.get_edition(c1.id)

    assert edition
    assert edition.id == c1.id
  end

  test "create edition" do
    {:ok, edition} = Editions.create_edition(%{name: "new edition"})

    assert Repo.get(Edition, edition.id)
  end

  test "update edition", %{c1: c1} do
    Editions.update_edition(c1.id, %{name: "updated edition"})
    edition = Repo.get(Edition, c1.id)

    assert edition.name == "updated edition"
  end

  test "delete edition" do
    edition = create_edition()
    Editions.delete_edition(edition.id)

    refute Repo.get(Edition, edition.id)
  end

  test "get attendance by id", %{attendance: attendance} do
    assert Editions.get_attendance(attendance.id)
  end

  test "get attendance by edition id and attendee", %{c1: c1, user: u1} do
    assert Editions.get_attendance(c1.id, u1.id)
  end

  test "create attendance", %{c2: c2, user: u1} do
    {:ok, attendance} = Editions.create_attendance(c2.id, u1.id)

    assert Repo.get(Attendance, attendance.id)
  end

  test "can't create duplicate attendance", %{c1: c1, user: u1} do
    {:error, changeset} = Editions.create_attendance(c1.id, u1.id)

    assert changeset.errors != nil
  end

  test "delete attendance by id", %{attendance: attendance} do
    Editions.delete_attendance(attendance.id)

    refute Repo.get(Attendance, attendance.id)
  end

  test "delete attendance by edition id and attendee", %{c1: c1, user: u1} do
    {:ok, attendance} = Editions.delete_attendance(c1.id, u1.id)

    refute Repo.get(Attendance, attendance.id)
  end

  test "toggle checkin works", %{c1: c1, user: user} do
    Editions.toggle_checkin(c1.id, user.id, true)

    a1 = Editions.get_attendance(c1.id, user.id)

    assert a1.checked_in == true
    assert_delivered_email Emails.checkin_email(user)

    Editions.toggle_checkin(c1.id, user.id, false)

    a2 = Editions.get_attendance(c1.id, user.id)

    assert a2.checked_in == false
  end
end
