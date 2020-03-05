defmodule Api.GraphQL.EctoExtensions do
  import Ecto.Query
  alias Ecto.Queryable

  defp string_in_atoms(source, target, _ex_args) do
    if target not in Enum.map(source, &to_string/1) do
      # raise Exception, ex_args
      raise "Graphql.EctoExtensions computer says no"
    end

    String.to_existing_atom(target)
  end

  @spec orderable(Queryable.t, %{order_by: String.t}) :: Ecto.Query.t
  def orderable(queryable, %{order_by: order_arg}) do
    {field_key, assocs} =
      order_arg
      |> String.split(".")
      |> List.pop_at(-1)

    {query, last_target} =
      assocs
      |> Enum.reduce(
        {
          queryable,
          Queryable.to_query(queryable).from |> elem(1)
        },
        fn assoc_key, {query, last_target} ->
          assoc_atom =
            :associations
            |> last_target.__schema__
            |> string_in_atoms(
              assoc_key,
              detail: "invalid assoc `#{assoc_key}`"
            )

          {
            from(
              [..., l] in query,
              left_join: a in assoc(l, ^assoc_atom)
            ),
            last_target.__schema__(:association, assoc_atom).related,
          }
        end
      )

    field_atom =
      :fields
      |> last_target.__schema__
      |> string_in_atoms(
        field_key,
        detail: "invalid field `#{field_key}`"
      )

    order_by(
      query,
      [..., l],
      asc: field(l, ^field_atom)
    )
  end

  def orderable(query, _), do: query
end
