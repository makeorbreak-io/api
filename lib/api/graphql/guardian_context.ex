defmodule Api.GraphQL.GuardianContext do
  @behaviour Plug

  import Plug.Conn

  alias Api.Accounts.User

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, current_user, _claims} <- ApiWeb.Guardian.resource_from_token(token) do
      %{current_user: current_user}
    else
      _ -> %{}
    end
  end
end
