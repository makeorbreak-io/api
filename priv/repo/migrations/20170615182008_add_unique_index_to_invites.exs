defmodule Api.Repo.Migrations.AddUniqueIndexToInvites do
  use Ecto.Migration

  def change do
    create unique_index(:invites, [:team_id, :invitee_id])
  end
end
