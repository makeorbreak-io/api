defmodule Api.EventTest do
  use Api.DataCase

  alias Api.Events.Event

  @valid_attrs %{name: "awesome event", slug: "awesome-event"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Event.changeset(%Event{}, @valid_attrs)
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
