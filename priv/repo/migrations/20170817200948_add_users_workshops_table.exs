defmodule Api.Repo.Migrations.AddUsersWorkshopsTable do
  use Ecto.Migration

  def change do
    create table(:users_workshops, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :workshop_id, references(:workshops, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create index(:users_workshops, [:user_id])
    create index(:users_workshops, [:workshop_id])
  end
end
