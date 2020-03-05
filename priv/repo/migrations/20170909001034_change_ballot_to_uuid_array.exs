defmodule Api.Repo.Migrations.ChangeBallotToUuidArray do
  use Ecto.Migration

  def change do
    alter table(:votes) do
      modify :ballot, {:array, :binary_id}
    end
  end
end
