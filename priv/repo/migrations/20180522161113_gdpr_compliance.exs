defmodule Api.Repo.Migrations.GdprCompliance do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :data_usage_consent, :boolean, default: false
      add :deleted_at, :naive_datetime

      remove :birthday
      remove :bio
      remove :twitter_handle
      remove :linkedin_url
      remove :company
      remove :college
      remove :employment_status
    end
  end
end
