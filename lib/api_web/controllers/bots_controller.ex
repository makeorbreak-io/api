defmodule ApiWeb.BotsController do
  use ApiWeb, :controller

  alias Api.Repo
  alias Api.AICompetition.{Bot, Bots}

  def callback(conn, %{"id" => id, "status" => status, "result" => result}) do
    bot = Bots.get_bot(id)

    changeset = Bot.changeset(bot, %{
      status: status,
      compilation_output: result,
    })

    Repo.update(changeset)

    send_resp(conn, 200, "")
  end

end
