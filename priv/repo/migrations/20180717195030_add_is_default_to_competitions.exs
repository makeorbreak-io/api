defmodule Api.Repo.Migrations.AddIsDefaultToCompetitions do
  use Ecto.Migration

  def change do
    alter table(:competitions) do
      add :is_default, :bool, null: false, default: false
    end
  end
end
