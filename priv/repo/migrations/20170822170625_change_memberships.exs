defmodule Api.Repo.Migrations.ChangeMemberships do
  use Ecto.Migration

  def change do
    alter table(:users_teams) do
      add :role, :string, default: "member"
    end
  end
end
