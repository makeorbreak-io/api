defmodule Api.Repo.Migrations.FixIndexes do
  use Ecto.Migration

  def change do
    drop unique_index(:users_teams, [:user_id])
    drop unique_index(:users_teams, [:team_id])
    create unique_index(:users_teams, [:user_id, :team_id])

    drop unique_index(:users_workshops, [:user_id])
    drop unique_index(:users_workshops, [:workshop_id])
    create unique_index(:users_workshops, [:user_id, :workshop_id])
  end
end
