defmodule Api.Repo.Migrations.AddPrizePreferenceToTeams do
  use Ecto.Migration

  def change do
    alter table(:teams) do
      add :prize_preference, {:array, :string}
    end
  end
end
