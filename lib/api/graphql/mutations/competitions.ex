defmodule Api.GraphQL.Mutations.Competitions do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Competitions

  object :competitions_mutations do
    @desc "Creates a competition"
    field :create_competition, :competition do
      arg :competition, non_null(:competition_input)

      middleware RequireAdmin

      resolve fn %{competition: competition}, _info ->
        Competitions.create_competition(competition)
      end
    end

    @desc "Updates a a competition"
    field :update_competition, :competition do
      arg :id, non_null(:string)
      arg :competition, non_null(:competition_input)

      middleware RequireAdmin

      resolve fn %{id: id, competition: competition}, _info ->
        Competitions.update_competition(id, competition)
      end
    end

    @desc "Deletes a competition"
    field :delete_competition, :string do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Competitions.delete_competition(id)
        {:ok, nil}
      end
    end

    @desc "Sets a competition as default"
    field :set_competition_as_default, :competition do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Competitions.set_as_default(id)
      end
    end

    @desc "Toggles competition check in status for user"
    field :toggle_user_checkin, :user do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Competitions.toggle_checkin(Competitions.default_competition.id, id)
      end
    end
  end
end
