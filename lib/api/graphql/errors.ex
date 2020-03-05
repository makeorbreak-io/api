defmodule Api.GraphQL.Errors do
  alias Ecto.Changeset

  def graphqlize(fun) when is_function(fun, 2) or is_function(fun, 3) do
    fn source, args, info ->
      fun
      |> case do
        f when is_function(f, 2) -> apply(f, [args, info])
        f when is_function(f, 3) -> apply(f, [source, args, info])
      end
      |> case do
        {:error, {code, %{}} = et} when is_atom(code) ->
          {:error, et |> from_error_tuple}

        {:error, %Changeset{} = cs} ->
          {:error, cs |> extract_error_from_changeset |> from_error_tuple}

        other -> other
      end
    end
  end

  defp from_error_tuple({code, %{} = args}) when is_atom(code) do
    [exception: %{code: code} |> Map.merge(args), message: code]
  end

  defp extract_error_from_changeset(%Changeset{} = changeset) do
    changeset
    |> Changeset.traverse_errors(fn {msg, opts} ->
      cond do
        Enum.empty?(opts) ->
          # Refactor to remove credo disable below
          # Nested modules could be aliased at the top of the invoking module.
          # credo:disable-for-next-line
          case msg do
            "has already been taken" -> {:already_taken, %{}}
          end

        val = Keyword.get(opts, :validation) ->
          {val, %{}}

        true ->
          {:unknown_reason, %{}}
      end
    end)
    |> Map.to_list
    |> Enum.flat_map(fn {k, values} ->
      values
      |> Enum.map(fn {e, m} ->
        {e, m |> Map.put(:param, k)}
      end)
    end)
    |> List.first
  end
end
