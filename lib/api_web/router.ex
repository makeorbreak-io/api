defmodule ApiWeb.Router do
  use ApiWeb, :router

  alias Absinthe

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth do
    plug Api.AuthPipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :graphql do
    plug :accepts, ["json", "graphql"]
  end

  scope "/", ApiWeb do
    pipe_through :api

    get "/", PageController, :index
  end

  scope "/" do
    pipe_through [:graphql, :auth]

    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: ApiWeb.Graphql.Schema, interface: :simple
    forward "/graphql", Absinthe.Plug, schema: ApiWeb.Graphql.Schema
  end

  # Other scopes may use custom stacks.
  # scope "/api", ApiWeb do
  #   pipe_through :api
  # end
end
