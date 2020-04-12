defmodule Api.GraphQL.Queries.Events do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Resolvers

  alias Api.Events
  alias Api.Events.Event

  object :events_queries do
    @desc "Single event details"
    field :event, :event do
      arg :slug, non_null(:string)

      resolve Resolvers.by_attr(Event, :slug)
    end

    @desc "events list"
    field :events, list_of(:event) do
      resolve fn _args, _info ->
        {:ok, Events.all}
      end
    end
  end
end
