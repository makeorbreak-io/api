defmodule Api.Repo.Migrations.RemoveDataFromTeam do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      remove :eligible
      remove :disqualified_at
      remove :disqualified_by_id
      remove :prize_preference
      remove :prize_preference_hmac_secret
      remove :tie_breaker
      add :accepted, :boolean, default: false
    end
  end
end
