defmodule Api.Repo.Migrations.AddEditionIdToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :edition_id, references(:editions, on_delete: :delete_all, type: :uuid)
    end
  end
end
