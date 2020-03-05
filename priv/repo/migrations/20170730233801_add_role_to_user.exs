defmodule Api.Repo.Migrations.AddRoleToUser do
  use Ecto.Migration

  def change do
    # creating the database type
    execute("create type role as enum ('admin', 'participant')")

    alter table(:users) do
      add :role, :role, null: false, default: "participant"
    end
  end
end
