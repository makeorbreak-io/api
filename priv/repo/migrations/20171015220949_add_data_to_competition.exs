defmodule Api.Repo.Migrations.AddDataToCompetition do
  use Ecto.Migration

  def change do
    execute("create type competition_status as enum ('created', 'started', 'ended')")

    alter table(:competition) do
      add :status, :competition_status, default: "created"
      add :name, :string
    end
  end
end
