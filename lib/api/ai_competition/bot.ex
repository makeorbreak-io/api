defmodule Api.AICompetition.Bot do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.AICompetition.{Bot, GameBot}
  alias Api.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_competition_bots" do
    field :sdk, :string
    field :source_code, :string
    field :status, :string
    field :title, :string
    field :compilation_output, :string
    field :revision, :integer

    timestamps()

    # Associations
    belongs_to :user, User
    has_many :game_bots, GameBot, foreign_key: :ai_competition_bot_id
    has_many :games, through: [:game_bots, :game]
  end

  @doc false
  def changeset(%Bot{} = bot, attrs) do
    bot
    |> cast(attrs, [:title, :sdk, :source_code, :status, :compilation_output, :user_id, :revision])
    |> validate_required([:title, :sdk, :source_code, :revision])
  end
end
