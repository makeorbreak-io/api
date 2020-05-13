defmodule Api.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Events.Attendance
  alias Api.Editions.Edition

  @valid_attrs ~w(
    name
    slug
    summary
    description
    speaker
    participant_limit
    participants_counter
    year
    speaker_image
    banner_image
    short_date
    short_speaker
    type
    edition_id
  )a

  @required_attrs ~w(
    name
    slug
    edition_id
  )a

  @derive {Phoenix.Param, key: :slug}
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "events" do
    field :name, :string
    field :slug, :string
    field :summary, :string
    field :description, :string
    field :speaker, :string
    field :participant_limit, :integer
    field :participants_counter, :integer, default: 0
    field :year, :integer
    field :speaker_image, :string
    field :banner_image, :string
    field :short_speaker, :string
    field :short_date, :string
    field :type, :string, default: "workshop"

    timestamps()

    belongs_to :edition, Edition
    has_many :attendances, Attendance, foreign_key: :event_id, on_delete: :delete_all
    has_many :users, through: [:attendances, :user]
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @valid_attrs)
    |> validate_required(@required_attrs)
    |> unique_constraint(:slug)
  end
end
