defmodule ApiWeb.UserController do
  use ApiWeb, :controller

  alias Api.Accounts

  alias ApiWeb.{ErrorController}

  action_fallback ErrorController

  def get_token(conn, %{"email" => email}) do
    with {:ok, _} <- Accounts.get_pwd_token(email),
      do: send_resp(conn, :no_content, "")
  end

  def recover_password(conn, %{"token" => t, "password" => p}) do
    with {:ok, _} <- Accounts.recover_password(t, p),
      do: send_resp(conn, :no_content, "")
  end
end
