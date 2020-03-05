defmodule Api.AICompetition.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.AICompetition.{Game, GameTemplate, GameBot}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_competition_games" do
    field :initial_state, :map
    field :final_state, :map
    field :status, :string
    field :is_ranked, :boolean
    field :run, :string

    belongs_to :game_template, GameTemplate, foreign_key: :ai_competition_game_template_id
    has_many :game_bots, GameBot, foreign_key: :ai_competition_game_id
    has_many :bots, through: [:game_bots, :bot]

    timestamps()
  end

  @doc false
  def changeset(%Game{} = ai_game, attrs) do
    ai_game
    |> cast(attrs, [:status, :initial_state, :final_state, :is_ranked, :run])
    |> validate_required([:status, :initial_state, :is_ranked])
  end
end
