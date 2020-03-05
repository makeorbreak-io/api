defmodule Api.Repo.Migrations.ChangeVoteUniqueIndex do
  use Ecto.Migration

  def change do
    drop unique_index(:votes, [:voter_identity])
    create unique_index(:votes, [:voter_identity, :category_id])
  end
end
