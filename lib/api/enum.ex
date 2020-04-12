defmodule Api.Enum do

  def avg([]), do: 0
  def avg(list), do: Enum.sum(list) / Enum.count(list)

  def rank1224_by(list, fun) do
    list
    |> Stream.with_index()
    |> Enum.scan(fn({elem, idx}, {previous_elem, previous_rank}) ->
        if apply(fun, [elem]) == apply(fun, [previous_elem]) do
          {elem, previous_rank}
        else
          {elem, idx}
        end
    end)
  end
end