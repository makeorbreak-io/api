defmodule Api.Flyby do
  use Ecto.Schema
  import Ecto.Changeset

  @valid_attrs ~w(
    name
    email
    time
  )a

  @required_attrs ~w(
    name
    email
    time
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "flybys" do
    field :name, :string
    field :email, :string
    field :time, :integer

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:email)
  end
end
