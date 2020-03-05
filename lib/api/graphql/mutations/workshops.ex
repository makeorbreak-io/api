defmodule Api.GraphQL.Mutations.Workshops do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}

  alias Api.Workshops

  object :workshops_mutations do
    @desc "Joins a workshop"
    field :join_workshop, :workshop do
      arg :slug, non_null(:string)

      middleware RequireAuthn

      resolve fn %{slug: slug}, %{context: %{current_user: current_user}} ->
        Workshops.join(current_user, slug)
      end
    end

    @desc "Leaves a workshop"
    field :leave_workshop, :workshop do
      arg :slug, non_null(:string)

      middleware RequireAuthn

      resolve fn %{slug: slug}, %{context: %{current_user: current_user}} ->
        Workshops.leave(current_user, slug)
      end
    end

    @desc "Creates a workshop (admin only)"
    field :create_workshop, :workshop do
      arg :workshop, non_null(:workshop_input)

      middleware RequireAdmin

      resolve fn %{workshop: workshop}, _info ->
        Workshops.create(workshop)
      end
    end

    @desc "Updates a workshop (admin only)"
    field :update_workshop, :workshop do
      arg :slug, non_null(:string)
      arg :workshop, non_null(:workshop_input)

      middleware RequireAdmin

      resolve fn %{workshop: workshop, slug: slug}, _info ->
        Workshops.update(slug, workshop)
      end
    end

    @desc "Deletes a workshop (admin only)"
    field :delete_workshop, :workshop do
      arg :slug, non_null(:string)

      middleware RequireAdmin

      resolve fn %{slug: slug}, _info ->
        Workshops.delete(slug)
      end
    end

    @desc "Toggle workshop check in status for user"
    field :toggle_workshop_checkin, :workshop do
      arg :slug, non_null(:string)
      arg :user_id, non_null(:string)
      arg :value, non_null(:boolean)

      middleware RequireAdmin

      resolve fn %{slug: slug, user_id: user_id, value: value}, _info ->
        Workshops.toggle_checkin(slug, user_id, value)
      end
    end
  end
end
