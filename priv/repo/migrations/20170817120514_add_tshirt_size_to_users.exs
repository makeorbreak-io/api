defmodule Api.Repo.Migrations.AddTshirtSizeToUsers do
  use Ecto.Migration

  def change do
    execute("create type tshirt_size as enum('XL', 'L', 'M', 'S')")

    alter table(:users) do
      add :tshirt_size, :tshirt_size
    end
  end
end
