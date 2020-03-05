defmodule Api.Repo.Migrations.ContainUsers do
  use Ecto.Migration

  def change do
    alter table(:votes) do
      remove :voter_identity
    end

    alter table(:users) do
      add :name, :string
      remove :first_name
      remove :last_name
      remove :voter_identity
      remove :checked_in
    end

    create table(:competition_attendance, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :attendee, :uuid
      add :checked_in, :boolean, default: false
      add :competition_id, references(:competition, on_delete: :delete_all, type: :uuid)

      timestamps()
    end

    create unique_index(:competition_attendance, [:attendee, :competition_id])
  end
end
