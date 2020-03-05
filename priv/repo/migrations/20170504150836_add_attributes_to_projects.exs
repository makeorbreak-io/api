defmodule Api.Repo.Migrations.AddAttributesToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :team_name, :string
      add :user_id, references(:users, on_delete: :delete_all, type: :uuid)
      add :repo, :string
      add :server, :string
      add :student_team, :boolean
      add :applied_at, :utc_datetime
      add :completed_at, :utc_datetime
    end
  end
end
