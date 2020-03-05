defmodule Api.Repo.Migrations.DecoupleTeamFromProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      remove :technologies
      add :technologies, {:array, :string}
      modify :description, :text
      remove :team_name
      remove :student_team
      remove :applied_at
      remove :user_id
      add :team_id, references(:teams, on_delete: :delete_all, type: :uuid)
    end

    alter table(:users) do
      modify :bio, :text
    end
  end
end
