defmodule Api.GraphQL.Mutations.Flybys do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Flybys

  object :flybys_mutations do
    @desc "Creates a paper plane competition entry"
    field :create_flyby, :flyby do
      arg :flyby, non_null(:flyby_input)

      middleware RequireAdmin

      resolve fn %{flyby: flyby}, _info ->
        Flybys.create(flyby)
      end
    end

    @desc "Deletes a paper plane competition entry"
    field :delete_flyby, :flyby do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Flybys.delete(id)
      end
    end
  end
end

