defmodule Api.GraphQL.Queries.AdminResources do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAdmin}
  alias Api.GraphQL.Resolvers

  alias Api.Accounts.User
  alias Api.Competitions.Competition
  alias Api.Emails
  alias Api.Emails.Email
  alias Api.Stats
  alias Api.Teams.Team

  object :admin_resources do
    @desc "DB stats"
    field :admin_stats, :admin_stats do
      middleware RequireAdmin

      resolve fn _args, _info ->
        {:ok, Stats.get()}
      end
    end

    @desc "All teams (admin)"
    field :teams, list_of(:team) do
    # connection field :teams, node_type: :team do
      arg :order_by, :string

      middleware RequireAdmin

      resolve Resolvers.all(Team)
    end

    @desc "All users (admin)"
    # connection field :users, node_type: :user do
    field :users, list_of(:user) do
      arg :order_by, :string

      middleware RequireAdmin

      resolve Resolvers.all(User)
    end

    @desc "All competitions (admin)"
    field :competitions, list_of(:competition) do
      arg :order_by, :string

      middleware RequireAdmin

      resolve fn _, _ ->
        competitions = Api.Competitions.list_competitions
        |> Api.Repo.preload(:suffrages)

        {:ok, competitions}
      end
    end

    @desc "All emails (admin)"
    # connection field :emails, node_type: :email do
    field :emails, list_of(:email) do
      arg :order_by, :string

      middleware RequireAdmin

      resolve Resolvers.all(Email)
    end

    @desc "Single email (admin)"
    field :email, type: :email do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        {:ok, Emails.get_email!(id)}
      end
    end
  end
end

