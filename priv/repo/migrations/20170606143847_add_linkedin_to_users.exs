defmodule Api.Repo.Migrations.AddLinkedinToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :linkedin_url, :string
    end
  end
end
