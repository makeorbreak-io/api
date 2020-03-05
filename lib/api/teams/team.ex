defmodule Api.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Teams.{Membership, Invite, ProjectFavorite}
  alias Api.Suffrages.Candidate
  alias Api.Competitions.Competition

  @valid_attrs ~w(
    name
    applied
    project_name
    project_desc
    eligible
    prize_preference
    prize_preference_hmac_secret
    technologies
    competition_id
  )a

  @admin_attrs @valid_attrs ++ ~w(repo accepted eligible)a

  @required_attrs ~w(
    name
    competition_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "teams" do
    field :name, :string
    field :repo, :map
    field :applied, :boolean, default: false
    field :accepted, :boolean, default: false
    field :eligible, :boolean, default: false
    field :prize_preference_hmac_secret, :string
    field :prize_preference, {:array, :string}
    field :project_name, :string
    field :project_desc, :string
    field :technologies, {:array, :string}

    timestamps()

    # Associations
    has_many :invites, Invite, on_delete: :delete_all
    has_many :memberships, Membership, foreign_key: :team_id, on_delete: :delete_all
    has_many :members, through: [:memberships, :user]
    has_many :project_favorites, ProjectFavorite
    has_many :candidates, Candidate
    has_many :suffrages, through: [:candidates, :suffrage]
    belongs_to :competition, Competition
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params), do: _cs(struct, params, @valid_attrs)
  def admin_changeset(struct, params), do: _cs(struct, params, @admin_attrs)
  defp _cs(struct, params, attrs) do
    struct
    |> cast(params, attrs)
    |> validate_required(@required_attrs)
  end
end
