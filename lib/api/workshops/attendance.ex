defmodule Api.Workshops.Attendance do
  use Ecto.Schema
  import Ecto.Changeset
  alias Api.Accounts.User
  alias Api.Workshops.Workshop

  @valid_attrs ~w(
    user_id
    workshop_id
    checked_in
  )a

  @required_attrs ~w(
    user_id
    workshop_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_workshops" do
    field :checked_in, :boolean, default: false

    belongs_to :user, User
    belongs_to :workshop, Workshop
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
  end
end
