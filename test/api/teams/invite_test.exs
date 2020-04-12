defmodule Api.InviteTest do
  use Api.DataCase

  alias Api.Teams.Invite

  @valid_attrs %{
    host_id: Ecto.UUID.generate(),
    team_id: Ecto.UUID.generate(),
    invitee_id: Ecto.UUID.generate()
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Invite.changeset(%Invite{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Invite.changeset(%Invite{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset with no attributes" do
    changeset = Invite.changeset(%Invite{})
    refute changeset.valid?
  end
end
