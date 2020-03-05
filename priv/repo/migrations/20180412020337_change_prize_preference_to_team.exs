defmodule Api.Repo.Migrations.ChangePrizePreferenceToTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :prize_preference_hmac_secret, :string
      add :prize_preference, {:array, :string}
    end

    alter table(:teams_suffrages) do
      remove :prize_preference_hmac_secret
      remove :prize_preference
    end

    create unique_index(:teams, [:prize_preference_hmac_secret])
  end
end
