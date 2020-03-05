defmodule Api.GraphQL.Mutations.Session do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn}
  alias Api.GraphQL.Resolvers

  alias Api.Accounts

  object :session_mutations do
    @desc "Authenticates a user and returns a JWT"
    field :authenticate, type: :string do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve Resolvers.run_with_args(
        &Accounts.create_session/2,
        [
          [:args, :email],
          [:args, :password],
        ]
      )
    end

    @desc "Registers an user and returns a JWT"
    field :register, type: :string do
      arg :email, non_null(:string)
      arg :password, non_null(:string)

      resolve Resolvers.run(&Accounts.create_user/1)
    end

    @desc "Updates the current user"
    field :update_me, type: :user do
      arg :user, non_null(:user_input)

      middleware RequireAuthn

      resolve fn %{user: params}, %{context: %{current_user: current_user}} ->
        Accounts.update_user(current_user, current_user.id, params)
      end
    end

    @desc "Deletes account"
    field :delete_account, type: :user do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        Accounts.delete_user(current_user, current_user.id)
      end
    end
  end
end
