defmodule Api.Teams.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Accounts.User
alias Api.Teams.Team

  @valid_attrs ~w(
    user_id
    team_id
  )a

  @required_attrs ~w(
    user_id
    team_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_teams" do
    field :role, :string, default: "member"

    belongs_to :user, User
    belongs_to :team, Team
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> foreign_key_constraint(:user_id)
  end
end
