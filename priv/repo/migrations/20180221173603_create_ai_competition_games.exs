defmodule Api.Repo.Migrations.CreateAICompetitionGames do
  use Ecto.Migration

  def change do
    create table(:ai_competition_games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string
      add :initial_state, :map
      add :final_state, :map
      add :ai_competition_game_template_id, references(:ai_competition_game_templates, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

  end
end
