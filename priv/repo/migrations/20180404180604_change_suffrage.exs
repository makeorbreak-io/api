defmodule Api.Repo.Migrations.ChangeSuffrage do
  use Ecto.Migration

  def up do
    alter table(:suffrages) do
      add :name, :string
      add :slug, :string
      remove :category_id
    end
  end

  def down do
    alter table(:suffrages) do
      remove :name
      remove :slug
      add :category_id, :string
    end
  end
end
