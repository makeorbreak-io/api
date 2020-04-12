defmodule Api.Repo.Migrations.RenameWorkshops do
  use Ecto.Migration

  def change do
    drop constraint(:users_workshops, "users_workshops_pkey")
    drop unique_index(:users_workshops, [:user_id, :workshop_id])
    drop unique_index(:workshops, [:slug])
    execute("ALTER TABLE workshops DROP CONSTRAINT workshops_pkey CASCADE")
    rename table(:workshops), to: table(:events)

    execute("create type event_type as enum ('workshop', 'talk')")

    alter table(:events) do
      add :type, :event_type, null: false, default: "workshop"
      # recreate primary key constraint
      modify :id, :uuid, primary_key: true
    end

    create unique_index(:events, [:slug])

    rename table(:users_workshops), to: table(:users_events)

    rename table(:users_events), :workshop_id, to: :event_id

    # recreate primary key constraint
    alter table(:users_events) do
      modify :id, :uuid, primary_key: true
    end

    create unique_index(:users_events, [:user_id, :event_id])
  end
end
