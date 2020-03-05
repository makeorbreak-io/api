defmodule Api.Emails.Email do
  use Ecto.Schema
  import Ecto.Changeset
  alias Api.Emails.Email


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "emails" do
    field :name, :string
    field :subject, :string
    field :title, :string
    field :content, :string

    timestamps()
  end

  @doc false
  def changeset(%Email{} = email, attrs) do
    email
    |> cast(attrs, [:name, :subject, :title, :content])
    |> validate_required([:name, :subject])
  end
end
