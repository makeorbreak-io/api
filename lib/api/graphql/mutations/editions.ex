defmodule Api.GraphQL.Mutations.Editions do
  use Absinthe.Schema.Notation

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Editions

  object :editions_mutations do
    @desc "Creates an edition"
    field :create_edition, :edition do
      arg :edition, non_null(:edition_input)

      middleware RequireAdmin

      resolve fn %{edition: edition}, _info ->
        Editions.create_edition(edition)
      end
    end

    @desc "Updates an edition"
    field :update_edition, :edition do
      arg :id, non_null(:string)
      arg :edition, non_null(:edition_input)

      middleware RequireAdmin

      resolve fn %{id: id, edition: edition}, _info ->
        Editions.update_edition(id, edition)
      end
    end

    @desc "Deletes an edition"
    field :delete_edition, :string do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Editions.delete_edition(id)
        {:ok, nil}
      end
    end

    @desc "Sets an edition as default"
    field :set_edition_as_default, :edition do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Editions.set_as_default(id)
      end
    end

    @desc "Toggles edition check in status for user"
    field :toggle_user_checkin, :user do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Editions.toggle_checkin(Editions.default_edition.id, id)
      end
    end
  end
end
