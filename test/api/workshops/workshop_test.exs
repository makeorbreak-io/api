defmodule Api.WorkshopTest do
  use Api.DataCase

  alias Api.Workshops.Workshop

  @valid_attrs %{name: "awesome workshop", slug: "awesome-workshop"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Workshop.changeset(%Workshop{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Workshop.changeset(%Workshop{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset with no attributes" do
    changeset = Workshop.changeset(%Workshop{})
    refute changeset.valid?
  end
end
