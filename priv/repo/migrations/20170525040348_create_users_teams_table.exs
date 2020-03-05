defmodule Api.Repo.Migrations.CreateUsersTeamsTable do
  use Ecto.Migration

  def change do
    create table(:users_teams, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :team_id, references(:teams, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create index(:users_teams, [:user_id])
    create index(:users_teams, [:team_id])
  end
end
