defmodule Api.WorkshopsTest do
  use Api.DataCase

  alias Api.Workshops
  alias Api.Workshops.{Attendance, Workshop}

  @valid_attrs %{name: "awesome workshop", slug: "awesome-workshop"}
  @invalid_attrs %{slug: nil}

  setup do
    w1 = create_workshop()

    {:ok, %{w1: w1}}
  end

  test "list workshops", %{w1: w1} do
    w2 = create_workshop()
    workshops = Workshops.all()

    assert workshops == [w1, w2]
    assert length(workshops) == 2
  end

  test "get workshop", %{w1: w1} do
    assert Workshops.get(w1.slug) == w1
  end

  test "get nonexistent workshop" do
    assert Workshops.get("inexistent_slug") == nil
  end

  test "join workshop if there are vacancies", %{w1: w1} do
    u1 = create_user()
    assert w1.participants_counter == 0

    {:ok, workshop} = Workshops.join(u1, w1.slug)

    w2 = Workshops.get(workshop.slug)
    assert workshop.id == w1.id

    assert w2.participants_counter == 1
  end

  test "join workshop if there are no vacancies", %{w1: w1} do
    u1 = create_user()
    u2 = create_user()
    create_workshop_attendance(w1, u1)
    assert Workshops.join(u2, w1.slug) == {:error, :workshop_full}
  end

  test "leave workshop if attending", %{w1: w1} do
    u1 = create_user()
    create_workshop_attendance(w1, u1)

    w2 = Workshops.get(w1.slug)

    assert w2.participants_counter == 1

    Workshops.leave(u1, w1.slug)

    w3 = Workshops.get(w1.slug)
    assert w3.participants_counter == 0
  end

  test "leave workshop if not attending", %{w1: w1} do
    u1 = create_user()

    assert Workshops.leave(u1, w1.slug) == {:error, :not_workshop_attendee}
  end

  test "create valid workshop" do
    {:ok, workshop} = Workshops.create(@valid_attrs)

    assert Repo.get(Workshop, workshop.id)
  end

  test "create invalid workshop" do
    {:error, changeset} = Workshops.create(@invalid_attrs)

    assert changeset.valid? == false
  end

  test "update workshop with valid data", %{w1: w1} do
    {:ok, workshop} = Workshops.update(w1.slug, @valid_attrs)

    assert Repo.get(Workshop, workshop.id)
  end

  test "update workshop with invalid data", %{w1: w1} do
    {:error, changeset} = Workshops.update(w1.slug, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "delete workshop", %{w1: w1} do
    {:ok, workshop} = Workshops.delete(w1.slug)

    refute Repo.get(Workshop, workshop.id)
  end

  test "toggle checkin", %{w1: w1} do
    u1 = create_user()
    create_workshop_attendance(w1, u1)

    {:ok, _} = Workshops.toggle_checkin(w1.slug, u1.id, true)

    a1 = Repo.get_by(Attendance, user_id: u1.id, workshop_id: w1.id)
    assert a1.checked_in == true

    {:ok, _} = Workshops.toggle_checkin(w1.slug, u1.id, false)

    a2 = Repo.get_by(Attendance, user_id: u1.id, workshop_id: w1.id)
    assert a2.checked_in == false
  end

  # test "checkin twice", %{w1: w1} do
  #   u1 = create_user()
  #   attendance = create_workshop_attendance(w1, u1)

  #   {:ok, _} = Workshops.toggle_checkin(w1.slug, u1.id, true)
  #   assert Workshops.toggle_checkin(w1.slug, u1.id, true) == :remove_checkin
  # end

  # test "checkout twice", %{w1: w1} do
  #   u1 = create_user()
  #   attendance = create_workshop_attendance(w1, u1)

  #   assert Workshops.toggle_checkin(w1.slug, u1.id, false) == :checkin
  # end
end
