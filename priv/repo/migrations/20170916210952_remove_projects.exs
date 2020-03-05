defmodule Api.Repo.Migrations.RemoveProjects do
  use Ecto.Migration

  def change do
    drop table(:projects)

    alter table(:teams) do
      add :project_name, :string
      add :project_desc, :text
      add :technologies, {:array, :string}
    end
  end
end
