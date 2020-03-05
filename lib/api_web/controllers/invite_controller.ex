defmodule ApiWeb.InviteController do
  use ApiWeb, :controller

  alias Api.Teams

  def invite_to_slack(conn, %{"email" => email}) do
    res = Teams.invite_to_slack(email)

    case res do
      {:ok, _} -> send_resp(conn, :created, "")
      {:error, _} -> send_resp(conn, :forbidden, "already_in_team")
    end
  end
end
