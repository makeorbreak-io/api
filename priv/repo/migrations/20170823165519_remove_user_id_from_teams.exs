defmodule Api.Repo.Migrations.RemoveUserIdFromTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      remove :user_id
    end
  end
end
