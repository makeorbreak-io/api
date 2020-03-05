defmodule Api.Teams.ProjectFavorite do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Accounts.User
  alias Api.Teams.Team

  @valid_attrs ~w(
    team_id
    user_id
  )a

  @required_attrs ~w(
    team_id
    user_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "project_favorites" do
    belongs_to :user, User
    belongs_to :team, Team

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:no_duplicate_project_favorites, name: :no_duplicate_project_favorites)
  end
end
