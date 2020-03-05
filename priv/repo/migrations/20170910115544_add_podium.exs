defmodule Api.Repo.Migrations.AddPodium do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :podium, {:array, :binary_id}
    end
  end
end
