defmodule ApiWeb.EctoHelperTests do
  use ExUnit.Case, async: true

  alias Api.Teams.Team
  alias ApiWeb.EctoHelper
  alias Ecto.{Changeset}

  test "if_missing absent" do
    field = :name
    fallback_value = "my cool name"

    cs =
      changeset(%Team{})
      |> EctoHelper.if_missing(field, fallback_value)

    {:ok, ^fallback_value} = Changeset.fetch_change(cs, field)
  end

  test "if_missing present" do
    field = :name
    fallback_value = "my cool name"
    original_value = "something else, idk dude"

    cs =
      Changeset.change(%Team{}, [{field, original_value}])
      |> EctoHelper.if_missing(field, fallback_value)

    {:ok, ^original_value} = Changeset.fetch_change(cs, field)
  end

  defp changeset(o, opts \\ []) do
    Changeset.change(o, opts)
    |> EctoHelper.on_any_present(
      [
        :disqualified_at,
        :disqualified_by_id,
      ],
      [
        &Changeset.validate_required/2,
      ]
    )
  end

  test "on_any_present none" do
    assert changeset(%Team{}).valid?
  end

  # test "on_any_present not all" do
  #   refute changeset(%Team{}, disqualified_at: 1).valid?
  # end

  # test "on_any_present all" do
  #   assert changeset(%Team{}, disqualified_at: 1, disqualified_by_id: 1).valid?
  # end
end
