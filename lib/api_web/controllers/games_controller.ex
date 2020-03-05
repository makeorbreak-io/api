defmodule ApiWeb.GamesController do
  use ApiWeb, :controller

  alias Api.Repo
  alias Api.AICompetition.{Game, Games}

  def callback(conn, %{"id" => id, "status" => "processed", "result" => result}) do
    game = Games.get_game(id)

    changeset = Game.changeset(game, %{
      status: "processed",
      final_state: Poison.decode!(result),
    })
    Repo.update!(changeset)
    Games.set_result(game.id)

    send_resp(conn, 200, "")
  end

  def callback(conn, %{"id" => id, "status" => status}) do
    game = Games.get_game(id)

    changeset = Game.changeset(game, %{
      status: status,
    })
    Repo.update!(changeset)

    send_resp(conn, 200, "")
  end

end
