defmodule Api.Repo.Migrations.AddCheckedInToUsersWorkshops do
  use Ecto.Migration

  def change do
    alter table(:users_workshops) do
      add :checked_in, :boolean, default: false
    end
  end
end
