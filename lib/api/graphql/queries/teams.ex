defmodule Api.GraphQL.Queries.Teams do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}
  alias Api.GraphQL.Resolvers

  alias Api.Teams
  alias Api.Teams.Team

  object :teams_queries do
    @desc "Single team details"
    field :team, :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve Resolvers.by_id(Team)
    end

    field :projects, list_of(:team) do
      resolve fn _args, _info ->
        {:ok, Teams.with_project}
      end
    end

    @desc "All teams"
    # connection field :teams, node_type: :team do
    field :teams, list_of(:team) do
      arg :order_by, :string

      middleware RequireAdmin

      resolve Resolvers.all(Team)
    end
  end
end
