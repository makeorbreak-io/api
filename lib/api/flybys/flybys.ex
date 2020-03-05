defmodule Api.Flybys do
  import Ecto.Query, warn: false

  alias Api.{Flyby, Repo}

  def all do
    Repo.all(Flyby)
  end

  def get(id) do
    Repo.get!(Flyby, id)
  end

  def create(flyby_params) do
    changeset = Flyby.changeset(%Flyby{}, flyby_params)

    Repo.insert(changeset)
  end

  def delete(id) do
    flyby = get(id)
    Repo.delete(flyby)
  end
end
