defmodule Api.GraphQL.Scalars do
  use Absinthe.Schema.Notation

  scalar :json, name: "JSON" do
    description """
      Represents a stringified JSON resource
    """

    parse fn x -> x end
    serialize fn x -> x end
  end

  scalar :array, name: "Array" do
    description """
      Represents a array of values
    """

    parse fn x -> x end
    serialize fn x -> x end
  end

  scalar :utc_datetime, name: "UTCDatetime" do
    description """
      Represents a datetime in UTC
    """

    serialize fn x -> NaiveDateTime.to_iso8601(x) <> "Z" end
    parse &parse_naive_datetime/1
  end

  @spec parse_naive_datetime(Absinthe.Blueprint.Input.String.t())
    :: {:ok, NaiveDateTime.t()} | :error
  @spec parse_naive_datetime(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp parse_naive_datetime(%Absinthe.Blueprint.Input.String{value: value}) do
    case NaiveDateTime.from_iso8601(value) do
      {:ok, naive_datetime} -> {:ok, naive_datetime}
      _error -> :error
    end
  end

  defp parse_naive_datetime(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp parse_naive_datetime(_) do
    :error
  end

end
