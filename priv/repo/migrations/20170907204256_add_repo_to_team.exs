defmodule Api.Repo.Migrations.AddRepoToTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :repo, :map
    end
  end
end
