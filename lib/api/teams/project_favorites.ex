defmodule Api.Teams.ProjectFavorites do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Teams.ProjectFavorite

  def user_favorites(user) do
    q = from pf in ProjectFavorite,
      where: pf.user_id == ^user.id

    q
    |> Repo.preload([:user, :team])
    |> Repo.all
  end

  def team_favorites(team) do
    q = from pf in ProjectFavorite,
      where: pf.team_id == ^team.id

    q
    |> Repo.preload([:user, :team])
    |> Repo.all
  end

  def toggle_favorite(user_id, team_id) do
    q = from pf in ProjectFavorite,
      where: pf.user_id == ^user_id,
      where: pf.team_id == ^team_id

    pf = Repo.one(q)
    if pf do
      Repo.delete(pf)
      {:ok, %ProjectFavorite{}}
    else
      Repo.insert(%ProjectFavorite{team_id: team_id, user_id: user_id})
    end
  end

end
