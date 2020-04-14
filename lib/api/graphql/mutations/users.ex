defmodule Api.GraphQL.Mutations.Users do
  use Absinthe.Schema.Notation

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Accounts

  object :users_mutations do
    @desc "Makes a user admin (admin only)"
    field :make_admin, :user do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Accounts.update_any_user(id, %{role: "admin"})
      end
    end

    @desc "Makes a user participant (admin only)"
    field :make_participant, :user do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Accounts.update_any_user(id, %{role: "participant"})
      end
    end

    @desc "Removes a user (admin only)"
    field :remove_user, :string do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Accounts.delete_any_user(id)
        id
      end
    end
  end
end
