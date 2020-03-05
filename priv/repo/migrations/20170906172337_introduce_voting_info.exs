defmodule Api.Repo.Migrations.IntroduceVotingInfo do
  use Ecto.Migration

  #alias Api.Competitions.Category
  alias Api.Repo

  defp fk(table, on_delete \\ :nilify_all, type \\ :uuid) do
    references(table, on_delete: on_delete, type: type)
  end

  def change do
    alter table(:users) do
      add :voter_identity, :string
    end
    flush()

    create unique_index(:users, [:voter_identity])
    alter table(:users) do
      modify :voter_identity, :string, null: false
    end
    flush()

    alter table(:teams) do
      add :disqualified_at, :utc_datetime, default: nil
      add :disqualified_by_id, fk(:users), default: nil
      add :eligible, :boolean, default: false
      add :prize_preference_hmac_secret, :string
      add :tie_breaker, :integer
    end

    create unique_index(:teams, [:prize_preference_hmac_secret])
    create unique_index(:teams, [:tie_breaker])
    alter table(:teams) do
      modify :prize_preference_hmac_secret, :string, null: false
      modify :tie_breaker, :integer, null: false
    end
    flush()

    create table(:categories, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      timestamps()
    end
    create unique_index(:categories, [:name])
    flush()
    # Enum.map(
    #   ~w(useful funny hardcore),
    #   &Repo.insert!(%Category{name: &1})
    # )

    create table(:competition, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :voting_started_at, :utc_datetime, default: nil
      add :voting_ended_at, :utc_datetime, default: nil
    end

    create table(:paper_votes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :hmac_secret, :string, null: false
      add :category_id, fk(:categories), null: false
      add :created_by_id, fk(:users), null: false

      add :redeemed_at, :utc_datetime, default: nil
      add :redeeming_admin_id, fk(:users), default: nil
      add :redeeming_member_id, fk(:users), default: nil
      add :team_id, fk(:teams), default: nil

      add :annulled_at, :utc_datetime, default: nil
      add :annulled_by_id, fk(:users), default: nil

      timestamps()
    end
    create unique_index(:paper_votes, [:hmac_secret])

    create table(:votes, primary_key: false) do
      add :id, :uuid, primary_key: true
      add(
        :voter_identity,
        references(
          :users,
          column: :voter_identity,
          type: :string,
          on_delete: :nothing,
          on_update: :update_all
        ),
        null: false
      )
      add :category_id, fk(:categories), null: false
      add :ballot, {:array, :uuid}, null: false
      timestamps()
    end
    create unique_index(:votes, [:voter_identity])
  end
end
