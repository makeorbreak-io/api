defmodule Api.Editions.Edition do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Editions.Attendance
  alias Api.Teams.Team
  alias Api.Suffrages.Suffrage
  alias Api.Events.Event

  @valid_attrs ~w(
    name
    status
    is_default
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "editions" do
    field :name, :string
    # Enum - "created", "started", "ended"
    field :status, :string, default: "created"
    field :is_default, :boolean, default: false

    has_many :suffrages, Suffrage
    has_many :teams, Team
    has_many :attendances, Attendance
    has_many :events, Event
    has_many :users, through: [:attendances, :attendee]
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
  end
end
