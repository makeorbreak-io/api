defmodule Api.Repo.Migrations.AddPasswordRecoveryToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pwd_recovery_token, :string, default: nil
      add :pwd_recovery_token_expiration, :utc_datetime, default: nil
    end

    create unique_index(:users, [:pwd_recovery_token])
  end
end
