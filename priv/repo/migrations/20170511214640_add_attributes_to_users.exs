defmodule Api.Repo.Migrations.AddAttributesToUsers do
  use Ecto.Migration

  def change do
    execute("create type employment_status as enum ('employed', 'looking', 'student')")

    alter table(:users) do
      add :employment_status, :employment_status
      add :birthday, :date
      add :college, :string
      add :company, :string
      add :github_handle, :string
      add :twitter_handle, :string
      add :bio, :string
    end
  end
end
