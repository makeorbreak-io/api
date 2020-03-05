defmodule Api.Repo.Migrations.AddParticipantsCounterToWorkshops do
  use Ecto.Migration

  def change do
    alter table(:workshops) do
      add :participants_counter, :integer, default: 0
    end
  end
end
