defmodule Api.AICompetition.GameTemplate do
  use Ecto.Schema
  import Ecto.Changeset
  alias Api.AICompetition.GameTemplate

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "ai_competition_game_templates" do
    field :initial_state, :map
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(%GameTemplate{} = game_template, attrs) do
    game_template
    |> cast(attrs, [:initial_state, :slug])
    |> validate_required([:initial_state, :slug])
  end
end
