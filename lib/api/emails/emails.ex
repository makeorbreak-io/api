defmodule Api.Emails do
  import Ecto.Query, warn: false
  alias Api.Repo

  alias Api.Emails.Email

  def list_emails do
    Repo.all(Email)
  end

  def get_email!(id), do: Repo.get!(Email, id)

  def create_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  def update_email(id, params) do
    email = get_email!(id)
    changeset = Email.changeset(email, params)

    Repo.update(changeset)
  end

  def delete_email(id) do
    email = get_email!(id)
    Repo.delete(email)
  end

  # def change_email(%Email{} = email) do
  #   Email.changeset(email, %{})
  # end
end
