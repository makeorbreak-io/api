defmodule Api.Suffrages.PaperVote do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Accounts.User
  alias Api.Teams.Team
  alias Api.Suffrages.Suffrage
  alias ApiWeb.EctoHelper

  @valid_attrs ~w(
    suffrage_id
    created_by_id
    redeemed_at
    redeeming_admin_id
    redeeming_member_id
    team_id
    annulled_at
    annulled_by_id
  )a

  @required_attrs ~w(
    suffrage_id
    created_by_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "paper_votes" do
    belongs_to :suffrage, Suffrage
    belongs_to :created_by, User

    field :redeemed_at, :utc_datetime
    belongs_to :redeeming_admin, User
    belongs_to :redeeming_member, User
    belongs_to :team, Team

    field :annulled_at, :utc_datetime
    belongs_to :annulled_by, User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> assoc_constraint(:suffrage)
    |> assoc_constraint(:created_by)
    |> EctoHelper.on_any_present(
      [
        :redeemed_at,
        :redeeming_admin_id,
        :redeeming_member_id,
        :team_id,
      ],
      [
        &validate_required/2,
        &assoc_constraint(&1, :redeeming_admin),
        &assoc_constraint(&1, :redeeming_member),
        &assoc_constraint(&1, :team)
      ]
    )
    |> EctoHelper.on_any_present(
      [
        :annulled_by_id,
        :annulled_at,
      ],
      [
        &validate_required/2,
        &assoc_constraint(&1, :annulled_by)
      ]
    )
  end
end
