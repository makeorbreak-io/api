defmodule Api.Repo.Migrations.AddSuffrageInfo do
  use Ecto.Migration

  defp fk(table, on_delete \\ :nilify_all, type \\ :uuid) do
    references(table, on_delete: on_delete, type: type)
  end

  def change do
    alter table(:competitions) do
      remove :voting_started_at
      remove :voting_ended_at
    end

    create table(:suffrages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :voting_started_at, :utc_datetime, default: nil
      add :voting_ended_at, :utc_datetime, default: nil
      add :category_id, fk(:categories)
      add :competition_id, fk(:competitions), null: false
      add :podium, {:array, :binary_id}

      timestamps()
    end

    flush()

    alter table(:categories) do
      remove :podium
      add :suffrage_id, fk(:suffrages)
    end

    create table(:teams_suffrages, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :disqualified_at, :utc_datetime, default: nil
      add :disqualified_by_id, fk(:users), default: nil
      add :eligible, :boolean, default: false
      add :prize_preference_hmac_secret, :string
      add :prize_preference, {:array, :string}
      add :tie_breaker, :integer
      add :team_id, fk(:teams), null: false
      add :suffrage_id, fk(:suffrages), null: false

      timestamps()
    end

    create unique_index(:teams_suffrages, [:prize_preference_hmac_secret])
    create unique_index(:teams_suffrages, [:tie_breaker])
    create unique_index(:teams_suffrages, [:team_id, :suffrage_id])

    alter table(:votes) do
      add(:voter_identity,
        references(
          :competition_attendance,
          column: :voter_identity,
          type: :string,
          on_delete: :nothing,
          on_update: :update_all
        ),
        null: false
      )
      add :suffrage_id, fk(:suffrages), null: false
      remove :category_id
    end

    create unique_index(:votes, [:voter_identity, :suffrage_id])

    alter table(:paper_votes) do
      remove :category_id
      add :suffrage_id, fk(:suffrages), null: false
    end
  end
end
