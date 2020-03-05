defmodule Api.Repo.Migrations.AddFlybys do
  use Ecto.Migration

  def change do
    create table(:flybys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :email, :string
      add :time, :integer

      timestamps()
    end

    create index(:flybys, [:email], unique: true)
  end
end
