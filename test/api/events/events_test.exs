defmodule Api.EventsTest do
  use Api.DataCase

  alias Api.Events
  alias Api.Events.{Attendance, Event}

  @valid_attrs %{name: "awesome event", slug: "awesome-event"}
  @invalid_attrs %{slug: nil}

  setup do
    c1 = create_edition()
    e1 = create_event(c1)

    {:ok, %{e1: e1, c1: c1}}
  end

  test "list events", %{c1: c1, e1: e1} do
    e2 = create_event(c1)
    events = Events.all()

    assert events == [e1, e2]
    assert length(events) == 2
  end

  test "get event", %{e1: e1} do
    assert Events.get(e1.slug) == e1
  end

  test "get nonexistent event" do
    assert Events.get("inexistent_slug") == nil
  end

  test "join event if there are vacancies", %{e1: e1} do
    u1 = create_user()
    assert e1.participants_counter == 0

    {:ok, event} = Events.join(u1, e1.slug)

    e2 = Events.get(event.slug)
    assert event.id == e1.id

    assert e2.participants_counter == 1
  end

  test "join event if there are no vacancies", %{e1: e1} do
    u1 = create_user()
    u2 = create_user()
    create_event_attendance(e1, u1)
    assert Events.join(u2, e1.slug) == {:error, :event_full}
  end

  test "leave event if attending", %{e1: e1} do
    u1 = create_user()
    create_event_attendance(e1, u1)

    e2 = Events.get(e1.slug)

    assert e2.participants_counter == 1

    Events.leave(u1, e1.slug)

    e3 = Events.get(e1.slug)
    assert e3.participants_counter == 0
  end

  test "leave event if not attending", %{e1: e1} do
    u1 = create_user()

    assert Events.leave(u1, e1.slug) == {:error, :not_event_attendee}
  end

  test "create valid event", %{c1: c1} do
    params = Map.merge(@valid_attrs, %{edition_id: c1.id})

    {:ok, event} = Events.create(params)

    assert Repo.get(Event, event.id)
  end

  test "create invalid event" do
    {:error, changeset} = Events.create(@invalid_attrs)

    assert changeset.valid? == false
  end

  test "update event with valid data", %{e1: e1} do
    {:ok, event} = Events.update(e1.slug, @valid_attrs)

    assert Repo.get(Event, event.id)
  end

  test "update event with invalid data", %{e1: e1} do
    {:error, changeset} = Events.update(e1.slug, @invalid_attrs)

    assert changeset.valid? == false
  end

  test "delete event", %{e1: e1} do
    {:ok, event} = Events.delete(e1.slug)

    refute Repo.get(Event, event.id)
  end

  test "toggle checkin", %{e1: e1} do
    u1 = create_user()
    create_event_attendance(e1, u1)

    {:ok, _} = Events.toggle_checkin(e1.slug, u1.id, true)

    a1 = Repo.get_by(Attendance, user_id: u1.id, event_id: e1.id)
    assert a1.checked_in == true

    {:ok, _} = Events.toggle_checkin(e1.slug, u1.id, false)

    a2 = Repo.get_by(Attendance, user_id: u1.id, event_id: e1.id)
    assert a2.checked_in == false
  end

  # test "checkin twice", %{e1: e1} do
  #   u1 = create_user()
  #   attendance = create_event_attendance(e1, u1)

  #   {:ok, _} = Events.toggle_checkin(e1.slug, u1.id, true)
  #   assert Events.toggle_checkin(e1.slug, u1.id, true) == :remove_checkin
  # end

  # test "checkout twice", %{e1: e1} do
  #   u1 = create_user()
  #   attendance = create_event_attendance(e1, u1)

  #   assert Events.toggle_checkin(e1.slug, u1.id, false) == :checkin
  # end
end
