defmodule Api.GraphQL.Queries.Editions do
  use Absinthe.Schema.Notation

  alias Api.Repo

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Editions

  object :editions_queries do
    @desc "Default edition"
    field :default_edition, :edition do
      resolve fn _args, _info ->
        {:ok, Editions.default_edition}
      end
    end

    @desc "Gets an edition"
    field :edition, :edition do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        comps = Editions.get_edition(id)
        |> Repo.preload(:teams)

        {:ok, comps}
      end
    end
  end
end
