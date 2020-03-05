defmodule Api.Guardian do
  use Guardian, otp_app: :api

  alias Api.Repo
  alias Api.Accounts.User

  def subject_for_token(%User{} = user, _claims), do: {:ok, "User:#{user.id}"}
  def subject_for_token(_sub, _claims), do: {:error, "Unknown resource type"}

  def resource_from_claims(%{"sub" => "User:" <> id}) do
    {:ok, Repo.get(User, id)}
  end
  def resource_from_claims(claims), do: {:error, "Unknown resource type"}
end
