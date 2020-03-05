defmodule Api.Repo.Migrations.CreateEmails do
  use Ecto.Migration

  def change do
    create table(:emails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :title, :string
      add :subject, :string
      add :content, :text

      timestamps()
    end

  end
end
