defmodule Api.Suffrages.Candidate do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Suffrages.Suffrage
  alias Api.Accounts.User
  alias Api.Teams.Team

  @attrs ~w(
    disqualified_at
    disqualified_by_id
    tie_breaker
    team_id
    suffrage_id
  )a

  @required_attrs ~w()a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "teams_suffrages" do
    field :disqualified_at, :utc_datetime
    field :tie_breaker, :integer

    belongs_to :disqualified_by, User
    belongs_to :suffrage, Suffrage
    belongs_to :team, Team

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @attrs)
    |> validate_required(@required_attrs)
    |> assoc_constraint(:suffrage)
  end
end
