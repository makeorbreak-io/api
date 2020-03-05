defmodule Api.Repo.Migrations.CreateAICompetitionBots do
  use Ecto.Migration

  def change do
    create table(:ai_competition_bots, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :string, null: false
      add :sdk, :string, null: false
      add :source_code, :text, null: false
      add :status, :string, null: false, default: "submitted"
      add :revision, :integer, null: false, default: 1
      add :compilation_output, :string
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:ai_competition_bots, [:user_id])
  end
end
