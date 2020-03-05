defmodule Api.Repo.Migrations.AddAppliedToTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :applied, :boolean, default: false
    end
  end
end
