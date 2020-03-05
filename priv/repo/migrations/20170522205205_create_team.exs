defmodule Api.Repo.Migrations.CreateTeam do
  use Ecto.Migration

  def change do
    create table(:teams, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)

      timestamps()
    end
    create index(:teams, [:user_id])

  end
end
