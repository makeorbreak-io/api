defmodule Api.Repo.Migrations.CreateTeamProjectFavorites do
  use Ecto.Migration

  def change do
    create table(:project_favorites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, on_delete: :nothing, type: :binary_id)
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create unique_index(:project_favorites, [:team_id, :user_id], name: :no_duplicate_project_favorites)
  end
end
