defmodule Api.GraphQL.Mutations.Events do
  use Absinthe.Schema.Notation

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}

  alias Api.Events

  object :events_mutations do
    @desc "Joins a event"
    field :join_event, :event do
      arg :slug, non_null(:string)

      middleware RequireAuthn

      resolve fn %{slug: slug}, %{context: %{current_user: current_user}} ->
        Events.join(current_user, slug)
      end
    end

    @desc "Leaves a event"
    field :leave_event, :event do
      arg :slug, non_null(:string)

      middleware RequireAuthn

      resolve fn %{slug: slug}, %{context: %{current_user: current_user}} ->
        Events.leave(current_user, slug)
      end
    end

    @desc "Creates a event (admin only)"
    field :create_event, :event do
      arg :event, non_null(:event_input)

      middleware RequireAdmin

      resolve fn %{event: event}, _info ->
        Events.create(event)
      end
    end

    @desc "Updates a event (admin only)"
    field :update_event, :event do
      arg :slug, non_null(:string)
      arg :event, non_null(:event_input)

      middleware RequireAdmin

      resolve fn %{event: event, slug: slug}, _info ->
        Events.update(slug, event)
      end
    end

    @desc "Deletes a event (admin only)"
    field :delete_event, :event do
      arg :slug, non_null(:string)

      middleware RequireAdmin

      resolve fn %{slug: slug}, _info ->
        Events.delete(slug)
      end
    end

    @desc "Toggle event check in status for user"
    field :toggle_event_checkin, :event do
      arg :slug, non_null(:string)
      arg :user_id, non_null(:string)
      arg :value, non_null(:boolean)

      middleware RequireAdmin

      resolve fn %{slug: slug, user_id: user_id, value: value}, _info ->
        Events.toggle_checkin(slug, user_id, value)
      end
    end
  end
end
