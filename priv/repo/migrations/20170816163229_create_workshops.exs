defmodule Api.Repo.Migrations.CreateWorkshops do
  use Ecto.Migration

  def change do
    create table(:workshops, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :name, :string
      add :summary, :text
      add :description, :text
      add :speaker, :text
      add :participant_limit, :integer
      add :year, :integer
      add :speaker_image, :text
      add :banner_image, :text

      timestamps()
    end

    create index(:workshops, [:slug], unique: true)
  end
end
