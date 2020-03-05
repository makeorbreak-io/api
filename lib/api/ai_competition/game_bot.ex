defmodule Api.AICompetition.GameBot do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.AICompetition.{Game, GameBot, Bot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_competition_game_bots" do
    field :score, :integer

    belongs_to :bot, Bot, foreign_key: :ai_competition_bot_id
    belongs_to :game, Game, foreign_key: :ai_competition_game_id

    timestamps()
  end

  @doc false
  def changeset(%GameBot{} = ai_game_bot, attrs) do
    ai_game_bot
    |> cast(attrs, [:score])
    |> cast_assoc(:bot)
    |> cast_assoc(:game)
  end
end
