defmodule Api.Repo.Migrations.MoreGdpr do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :spam_consent, :boolean, default: false
      add :share_consent, :boolean, default: false
    end
  end
end
