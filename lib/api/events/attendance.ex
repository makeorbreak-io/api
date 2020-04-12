defmodule Api.Events.Attendance do
  use Ecto.Schema
  import Ecto.Changeset
  alias Api.Accounts.User
  alias Api.Events.Event

  @valid_attrs ~w(
    user_id
    event_id
    checked_in
  )a

  @required_attrs ~w(
    user_id
    event_id
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_events" do
    field :checked_in, :boolean, default: false

    belongs_to :user, User
    belongs_to :event, Event
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
  end
end
