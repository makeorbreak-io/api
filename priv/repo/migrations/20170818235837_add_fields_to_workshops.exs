defmodule Api.Repo.Migrations.AddFieldsToWorkshops do
  use Ecto.Migration

  def change do
    alter table(:workshops) do
      add :short_speaker, :string
      add :short_date, :string
    end
  end
end
