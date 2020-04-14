defmodule Api.GraphQL.Resolvers do
  alias Api.Repo
  alias Api.GraphQL.Errors
  alias Api.GraphQL.EctoExtensions

  def by_id(type) when is_atom(type) do
    fn %{id: id}, _info ->
      {:ok, type |> Repo.get(id)}
    end
  end

  def by_attr(type, _attr) when is_atom(type) do
    fn args, _info ->
      {:ok, type |> Repo.get_by(args)}
    end
  end

  defp collect_args(arg_keys, source, args, info) do
    ctx = %{source: source, args: args, info: info}

    arg_keys
    |> Enum.reverse
    |> Enum.reduce([], fn arg_key, rest ->
      [get_in(ctx, arg_key) | rest]
    end)
  end

  def assoc(assocs) do
    all(
      fn source ->
        Ecto.assoc(source, assocs)
      end,
      [[:source]]
    )
  end

  def all(type) when is_atom(type) do
    all(
      fn -> type end,
      []
    )
  end

  def all(fun, arg_keys) when is_function(fun) do
    fn source, args, info ->
      resources = fun
      |> apply(collect_args(arg_keys, source, args, info))
      |> EctoExtensions.orderable(args)
      |> Repo.all

      {:ok, resources}
    end
  end

  def run_with_args(fun, arg_keys) do
    fn source, args, info ->
      fun
      |> apply(collect_args(arg_keys, source, args, info))
    end
    |> Errors.graphqlize
  end

  def run_with_source(fun) do
    fn _args, %{source: source} ->
      res = fun.(source)
      {:ok, res}
    end
    |> Errors.graphqlize
  end

  def run(fun) do
    fn args, _info ->
      fun.(args)
    end
    |> Errors.graphqlize
  end

  #
  # Non-generic resolvers
  def me(_args, %{context: %{current_user: current_user}}) do
    {:ok, current_user}
  end
  def me(_args, context), do: {:error, :unauthorized}
end
