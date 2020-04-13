defmodule Api.GraphQL.Mutations.Emails do
  use Absinthe.Schema.Notation

  alias Api.GraphQL.Middleware.{RequireAdmin}

  alias Api.Accounts
  alias Api.Emails
  alias Api.Mailer

  object :emails_mutations do
    @desc "Creates an email (admin only)"
    field :create_email, :email do
      arg :email, non_null(:email_input)

      middleware RequireAdmin

      resolve fn %{email: email}, _info ->
        Emails.create_email(email)
      end
    end

    @desc "Updates an email (admin only)"
    field :update_email, :email do
      arg :id, non_null(:string)
      arg :email, non_null(:email_input)

      middleware RequireAdmin

      resolve fn %{id: id, email: email}, _info ->
        Emails.update_email(id, email)
      end
    end

    @desc "Sends an email (admin only)"
    field :send_email, :string do
      arg :id, non_null(:string)
      arg :recipients, non_null(list_of(:string))

      middleware RequireAdmin

      resolve fn %{id: id, recipients: recipients}, _info ->
        email = Emails.get_email!(id)

        recipients
        |> Enum.each(
          fn user_id ->
            user = Accounts.get_user(user_id)
            Api.Notifications.Emails.send_email(email, user)
            |> Mailer.deliver_later
          end
        )

        {:ok, nil}
      end
    end

    @desc "Deletes an email (admin only)"
    field :delete_email, :email do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Emails.delete_email(id)
      end
    end
  end
end
