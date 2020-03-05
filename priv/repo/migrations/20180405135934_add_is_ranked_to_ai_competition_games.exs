defmodule Api.Repo.Migrations.AddIsRankedToAiCompetitionGames do
  use Ecto.Migration

  def change do
    alter table(:ai_competition_games) do
      add :is_ranked, :bool, default: false
      add :run, :string
    end
  end
end
