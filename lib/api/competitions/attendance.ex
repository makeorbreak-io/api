defmodule Api.Competitions.Attendance do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Accounts.User
  alias Api.Competitions.Competition
  alias ApiWeb.{EctoHelper, Crypto}

  @valid_attrs ~w(
    attendee
    competition_id
    checked_in
  )a

  @required_attrs ~w(
    attendee
    voter_identity
    competition_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "competition_attendance" do
    field :attendee, :binary_id
    field :checked_in, :boolean, default: false
    field :voter_identity, :string

    belongs_to :competition, Competition

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> EctoHelper.if_missing(:voter_identity, Crypto.random_hmac())
    |> validate_required(@required_attrs)
    |> unique_constraint(:voter_identity)
    |> unique_constraint(:attendee_competition_id)
  end
end
