defmodule ApiWeb.EditionTest do
  use Api.DataCase

  alias Api.Editions.Edition

  @valid_attrs %{
  }

  test "changeset with valid attributes" do
    changeset = Edition.changeset(%Edition{}, @valid_attrs)
    assert changeset.valid?
  end
end
