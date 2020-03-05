defmodule Api.Repo.Migrations.RemoveHmacSecretFromPaperVote do
  use Ecto.Migration

  def change do
    alter table(:paper_votes) do
      remove :hmac_secret
    end
  end
end
