defmodule Api.GraphQL.Queries.Workshops do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Resolvers

  alias Api.Workshops
  alias Api.Workshops.Workshop

  object :workshops_queries do
    @desc "Single workshop details"
    field :workshop, :workshop do
      arg :slug, non_null(:string)

      resolve Resolvers.by_attr(Workshop, :slug)
    end

    @desc "workshops list"
    field :workshops, list_of(:workshop) do
      resolve fn _args, _info ->
        {:ok, Workshops.all}
      end
    end
  end
end
