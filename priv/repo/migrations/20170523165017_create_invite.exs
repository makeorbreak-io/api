defmodule Api.Repo.Migrations.CreateInvite do
  use Ecto.Migration

  def change do
    create table(:invites, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :open, :boolean, default: false, null: false
      add :accepted, :boolean, default: false, null: false
      add :description, :text
      add :invitee_id, references(:users, on_delete: :nothing, type: :uuid)
      add :host_id, references(:users, on_delete: :nothing, type: :uuid)
      add :team_id, references(:teams, on_delete: :nothing, type: :uuid)

      timestamps()
    end

    create index(:invites, [:invitee_id])
    create index(:invites, [:host_id])
    create index(:invites, [:team_id])
  end
end
