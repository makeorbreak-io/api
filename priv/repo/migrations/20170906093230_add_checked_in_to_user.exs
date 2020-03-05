defmodule Api.Repo.Migrations.AddCheckedInToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :checked_in, :boolean, default: false
    end
  end
end
