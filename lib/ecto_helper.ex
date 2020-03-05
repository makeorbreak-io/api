defmodule ApiWeb.EctoHelper do
  alias Ecto.{Changeset}

  def if_missing(changeset, field, value) do
    if Changeset.get_field(changeset, field) do
      changeset
    else
      Changeset.put_change(changeset, field, value)
    end
  end

  def on_any_present(changeset, fields, transforms) do
    presence_count =
      fields
      |> Enum.map(&Changeset.fetch_change(changeset, &1))
      |> Enum.reject(&(&1 == :error))
      |> Enum.count

    # Credo made me extract this.
    applier = fn
      f, cs ->
        fi = :erlang.fun_info(f)
        case fi[:arity] do
          2 -> f.(cs, fields)
          1 -> f.(cs)
          arity -> raise ArgumentError, "Functions provided in the transforms " +
            "must be of arity 1 or 2, got #{fi.module}.#{fi.name}/#{arity}"
        end
    end

    case presence_count do
      0 -> changeset
      _ ->
        Enum.reduce(
          transforms,
          changeset,
          applier
        )
    end
  end
end
