defmodule Api.AICompetition.GameTemplates do

  def ten_by_ten(bot1, bot2) do
    id1 = bot1.id
    id2 = bot2.id

    %{
      width: 10,
      height: 10,
      turns_left: 100,
      colors: [
        [id1, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, id2]
      ],
      player_positions: %{} |> Map.put(id1, [0, 0]) |> Map.put(id2, [9, 9]),
      previous_actions: [],
    }
  end

  def five_by_eleven(bot1, bot2) do
    id1 = bot1.id
    id2 = bot2.id

    %{
      width: 11,
      height: 5,
      turns_left: 110,
      colors: [
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, id1, id1, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, id1, id1, id1, nil, nil, nil, id2, id2, id2, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, id2, id2, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
      ],
      player_positions: %{} |> Map.put(id1, [2, 3]) |> Map.put(id2, [2, 7]),
      previous_actions: [],
    }
  end

  def seven_by_thirteen(bot1, bot2) do
    id1 = bot1.id
    id2 = bot2.id

    %{
      width: 13,
      height: 7,
      turns_left: 130,
      colors: [
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, id1, nil, nil, nil, nil, nil, nil, nil, nil, nil, id2, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
      ],
      player_positions: %{} |> Map.put(id1, [3, 1]) |> Map.put(id2, [3, 11]),
      previous_actions: [],
    }
  end

  def seven_by_thirteen_b(bot1, bot2) do
    id1 = bot1.id
    id2 = bot2.id

    %{
      width: 13,
      height: 7,
      turns_left: 130,
      colors: [
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, id2, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, id1, nil, nil, nil, nil, nil, nil, nil],
        [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil]
      ],
      player_positions: %{} |> Map.put(id1, [5, 5]) |> Map.put(id2, [1, 7]),
      previous_actions: [],
    }
  end

end
