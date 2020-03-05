defmodule Api.Mailer do
  use Bamboo.Mailer, otp_app: :api

  alias Api.Accounts.User

  defimpl Bamboo.Formatter, for: User do
    def format_email_address(user, _opts) do
      {user.name, user.email}
    end
  end
end
