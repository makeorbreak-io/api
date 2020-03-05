defmodule Api.Repo.Migrations.CreateProject do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
    	add :id, :uuid, primary_key: true
      add :name, :string
      add :description, :string
      add :technologies, :string

      timestamps()
    end

  end
end
