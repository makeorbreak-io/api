defmodule Api.Repo.Migrations.AddCompetitionIdToTeam do
  use Ecto.Migration

  def change do
    rename table(:competition), to: table(:competitions)

    alter table(:teams) do
      add :competition_id, references(:competitions, on_delete: :delete_all, type: :uuid)
    end
  end
end
