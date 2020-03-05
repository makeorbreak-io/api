defmodule Api.Repo.Migrations.AddVoterIdentityToCompetitionAttendance do
  use Ecto.Migration

  def change do
    alter table(:competition_attendance) do
      add :voter_identity, :string, null: false
    end

    create unique_index(:competition_attendance, [:voter_identity])
  end
end
