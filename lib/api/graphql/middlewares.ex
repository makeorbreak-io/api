defmodule Api.GraphQL.Middleware do
  alias Absinthe.Resolution

  alias Api.Accounts.User

  defmodule RequireAuthn do
    @behaviour Absinthe.Middleware

    def call(%{context: %{current_user: %User{}}} = resolution, _config) do
      resolution
    end

    def call(%{context: %{current_user: nil}} = resolution, _config) do
      resolution
      |> Resolution.put_result({:error, %{
        message: "using this field requires authentication",
      }})
    end
  end

  defmodule RequireAdmin do
    @behaviour Absinthe.Middleware

    def call(%{context: %{current_user: %User{role: "admin"}}} = resolution, _config) do
      resolution
    end

    def call(%{context: %{current_user: %User{role: "participant"}}} = resolution, _config) do
      resolution
      |> Resolution.put_result({:error, %{
        message: "you do not have permission to access this field",
      }})
    end

    def call(%{context: %{current_user: nil}} = resolution, _config) do
      resolution
      |> Resolution.put_result({:error, %{
        message: "using this field requires authentication",
      }})
    end
  end
end
