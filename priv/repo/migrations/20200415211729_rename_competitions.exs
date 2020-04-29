defmodule Api.Repo.Migrations.RenameCompetitions do
  use Ecto.Migration

  defp fk(table, on_delete \\ :nilify_all, type \\ :uuid) do
    references(table, on_delete: on_delete, type: type)
  end

  def change do
    # drop indexes
    drop unique_index(:competition_attendance, [:attendee, :competition_id])

    # drop foreign keys
    drop constraint(:votes, "votes_voter_identity_fkey")
    drop constraint(:competition_attendance, "competition_attendance_competition_id_fkey")
    drop constraint(:teams, "teams_competition_id_fkey")
    drop constraint(:suffrages, "suffrages_competition_id_fkey")

    # this index need to be dropped here because it depends on the voter_identity fk
    drop unique_index(:competition_attendance, [:voter_identity])

    # drop primary keys
    drop constraint(:competition_attendance, "competition_attendance_pkey")
    drop constraint(:competitions, "competition_pkey")

    rename table(:competitions), to: table(:editions)

    # recreate edition primary key constraint
    alter table(:editions) do
      modify :id, :uuid, primary_key: true
    end

    # rename competition_attendance table
    rename table(:competition_attendance), to: table(:edition_attendance)

    # rename foreign keys
    rename table(:edition_attendance), :competition_id, to: :edition_id
    rename table(:suffrages), :competition_id, to: :edition_id
    rename table(:teams), :competition_id, to: :edition_id

    # recreate constraints
    alter table(:edition_attendance) do
      modify :id, :uuid, primary_key: true
      modify :edition_id, fk(:editions, :delete_all)
    end

    alter table(:teams) do
      modify :edition_id, fk(:editions, :delete_all)
    end

    alter table(:suffrages) do
      modify :edition_id, fk(:editions, :delete_all)
    end

    # recreate unique indexes
    create unique_index(:edition_attendance, [:attendee, :edition_id])
    create unique_index(:edition_attendance, [:voter_identity])

    alter table(:votes) do
      modify(:voter_identity,
        references(
          :edition_attendance,
          column: :voter_identity,
          type: :string,
          on_delete: :delete_all,
          on_update: :update_all
        ),
        null: false
      )
    end
  end
end
