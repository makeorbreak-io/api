defmodule Api.Repo.Migrations.CreateAICompetitionGameBots do
  use Ecto.Migration

  def change do
    create table(:ai_competition_game_bots, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :score, :integer
      add :ai_competition_bot_id, references(:ai_competition_bots, on_delete: :nothing, type: :binary_id)
      add :ai_competition_game_id, references(:ai_competition_games, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:ai_competition_game_bots, [:ai_competition_bot_id])
    create index(:ai_competition_game_bots, [:ai_competition_game_id])
  end
end
