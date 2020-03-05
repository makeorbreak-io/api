defmodule Api.Repo.Migrations.CreateAiGameTemplates do
  use Ecto.Migration

  def change do
    create table(:ai_competition_game_templates, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string
      add :initial_state, :map

      timestamps()
    end

  end
end
