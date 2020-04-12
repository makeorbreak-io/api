defmodule Api.EventsTest do
  use Api.DataCase

  alias Api.Events
  alias Api.Events.{Attendance, Event}

  @valid_attrs %{name: "awesome event", slug: "awesome-event"}
  @invalid_attrs %{slug: nil}

  setup do
    w1 = create_event()

    {:ok, %{w1: w1}}
  end

  test "list events", %{w1: w1} do
    w2 = create_event()
    events = Events.all()

    assert events == [w1, w2]
    assert length(events) == 2
  end

  test "get event", %{w1: w1} do
    assert Events.get(w1.slug) == w1
  end

  test "get nonexistent event" do
    assert Events.get("inexistent_slug") == nil
  end

  test "join event if there are vacancies", %{w1: w1} do
    u1 = create_user()
    assert w1.participants_counter == 0

    {:ok, event} = Events.join(u1, w1.slug)

    w2 = Events.get(event.slug)
    assert event.id == w1.id

    assert w2.participants_counter == 1
  end

  test "join event if there are no vacancies", %{w1: w1} do
    u1 = create_user()
    u2 = create_user()
    create_event_attendance(w1, u1)
    assert Events.join(u2, w1.slug) == {:error, :event_full}
  end

  test "leave event if attending", %{w1: w1} do
    u1 = create_user()
    create_event_attendance(w1, u1)

    w2 = Events.get(w1.slug)

    assert w2.participants_counter == 1

    Events.leave(u1, w1.slug)

    w3 = Events.get(w1.slug)
    assert w3.participants_counter == 0
  end

  test "leave event if not attending", %{w1: w1} do
    u1 = create_user()

    assert Events.leave(u1, w1.slug) == {:error, :not_event_attendee}
  end

  test "create valid event" do
    {:ok, event} = Events.create(@valid_attrs)

    assert Repo.get(Event, event.id)
  end

  test "create invalid event" do
    {:error, changeset} = Events.create(@invalid_attrs)

    assert changeset.valid? == false
  end

  test "update event with valid data", %{w1: w1} do
    {:ok, event} = Events.update(w1.slug, @valid_attrs)

    assert Repo.get(Event, event.id)
  end

  test "update event with invalid data", %{w1: w1} do
    {:error, changeset} = Events.update(w1.slug, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "delete event", %{w1: w1} do
    {:ok, event} = Events.delete(w1.slug)

    refute Repo.get(Event, event.id)
  end

  test "toggle checkin", %{w1: w1} do
    u1 = create_user()
    create_event_attendance(w1, u1)

    {:ok, _} = Events.toggle_checkin(w1.slug, u1.id, true)

    a1 = Repo.get_by(Attendance, user_id: u1.id, event_id: w1.id)
    assert a1.checked_in == true

    {:ok, _} = Events.toggle_checkin(w1.slug, u1.id, false)

    a2 = Repo.get_by(Attendance, user_id: u1.id, event_id: w1.id)
    assert a2.checked_in == false
  end

  # test "checkin twice", %{w1: w1} do
  #   u1 = create_user()
  #   attendance = create_event_attendance(w1, u1)

  #   {:ok, _} = Events.toggle_checkin(w1.slug, u1.id, true)
  #   assert Events.toggle_checkin(w1.slug, u1.id, true) == :remove_checkin
  # end

  # test "checkout twice", %{w1: w1} do
  #   u1 = create_user()
  #   attendance = create_event_attendance(w1, u1)

  #   assert Events.toggle_checkin(w1.slug, u1.id, false) == :checkin
  # end
end
