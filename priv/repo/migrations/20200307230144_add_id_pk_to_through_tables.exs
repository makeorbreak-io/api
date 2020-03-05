defmodule Api.Repo.Migrations.AddIdPkToThroughTables do
  use Ecto.Migration

  def up do
    Ecto.Adapters.SQL.query!(
      Api.Repo, """
      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
      """
    )

    Ecto.Adapters.SQL.query!(
      Api.Repo, """
      ALTER TABLE "users_teams"
      ADD COLUMN "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
      ADD PRIMARY KEY ("id");
      """
    )

    Ecto.Adapters.SQL.query!(
      Api.Repo, """
      ALTER TABLE "users_workshops"
      ADD COLUMN "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
      ADD PRIMARY KEY ("id");
      """
    )
  end
end
