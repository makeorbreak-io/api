defmodule Api.GraphQL.Queries.Flybys do
  use Absinthe.Schema.Notation

  alias Api.Flybys

  object :flybys_queries do
    @desc "MoB 2018 FLY paper plane competition entries"
    field :flybys, list_of(:flyby) do
      resolve fn _args, _info ->
        {:ok, Flybys.all}
      end
    end
  end
end
