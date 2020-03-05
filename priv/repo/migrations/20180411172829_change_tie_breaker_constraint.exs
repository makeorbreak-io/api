defmodule Api.Repo.Migrations.ChangeTieBreakerConstraint do
  use Ecto.Migration

  def change do
    drop unique_index(:teams_suffrages, [:tie_breaker])
    create unique_index(:teams_suffrages, [:suffrage_id, :tie_breaker])
  end
end
