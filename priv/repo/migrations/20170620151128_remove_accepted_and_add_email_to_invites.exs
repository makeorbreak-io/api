defmodule Api.Repo.Migrations.RemoveAcceptedAndAddEmailToInvites do
  use Ecto.Migration

  def change do
    alter table(:invites) do
      add :email, :string
      remove :accepted
    end
  end
end
