defmodule Api.GraphQL.Queries.Competitions do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.Repo

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Competitions

  object :competitions_queries do
    @desc "Default competition"
    field :default_competition, :competition do
      resolve fn _args, _info ->
        {:ok, Competitions.default_competition}
      end
    end

    @desc "Gets a competition"
    field :competition, :competition do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        comps = Competitions.get_competition(id)
        |> Repo.preload(:teams)

        {:ok, comps}
      end
    end
  end
end
