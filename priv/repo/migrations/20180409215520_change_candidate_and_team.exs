defmodule Api.Repo.Migrations.ChangeCandidateAndTeam do
  use Ecto.Migration

  def change do
    alter table(:teams_suffrages) do
      remove :eligible
    end

    alter table(:teams) do
      add :eligible, :boolean, default: false
    end
  end
end
