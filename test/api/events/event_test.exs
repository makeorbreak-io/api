defmodule Api.EventTest do
  use Api.DataCase

  alias Api.Events.Event

  @valid_attrs %{name: "awesome event", slug: "awesome-event"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    c = create_edition()

    changeset = Event.changeset(
      %Event{},
      Map.merge(@valid_attrs, %{edition_id: c.id})
    )
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Event.changeset(%Event{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset with no attributes" do
    changeset = Event.changeset(%Event{})
    refute changeset.valid?
  end
end
