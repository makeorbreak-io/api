defmodule Api.AICompetition.Games do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.AICompetition.{Game, GameBot, Bot}

  def get_game(id) do
    Repo.get!(Game, id)
    |> Repo.preload(:game_bots)
    |> Repo.preload(:game_template)
  end

  def run_games(run_name) do
    from(g in Game,
      where: g.run == ^run_name
    )
    |> Repo.all
  end

  def set_result(id) do
    game = get_game(id)

    game.game_bots
    |> Enum.map(fn game_bot ->
      GameBot.changeset(game_bot, %{score: game_performance(game, game_bot.ai_competition_bot_id)})
      |> Repo.update
    end)
  end

  def user_games(user) do
    unranked = from(
      g in Game,
      join: gb in GameBot, where: gb.ai_competition_game_id == g.id,
      join: b in Bot, where: b.id == gb.ai_competition_bot_id and b.user_id == ^user.id,
      where: g.status == "processed" and g.is_ranked == false,
      order_by: [desc: g.updated_at],
      limit: 50
    )

    ranked = from(
      g in Game,
      join: gb in GameBot, where: gb.ai_competition_game_id == g.id,
      join: b in Bot, where: b.id == gb.ai_competition_bot_id and b.user_id == ^user.id,
      where: g.status == "processed" and g.is_ranked == true,
      order_by: [desc: g.updated_at]
    )

    Repo.all(unranked) ++ Repo.all(ranked)
  end

  def create_game(bot1, bot2, is_ranked, run, template) do

    changeset = Game.changeset(%Game{}, %{
      status: "pending",
      initial_state: apply(template, [bot1, bot2]),
      is_ranked: is_ranked,
      run: run,
    })

    case Repo.insert(changeset) do
      {:ok, game} ->
        Repo.insert!(%GameBot{game: game, bot: bot1})
        Repo.insert!(%GameBot{game: game, bot: bot2})

        submit_to_ai_server(game, "compete")

        {:ok, game}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def day_performance(games, bot_id) do
    games
    |> Enum.map(fn game -> game_performance(game, bot_id) end)
    |> Api.Enum.avg
  end

  def game_performance(game, bot_id) do
    all_bot_ids = game.game_bots |> Enum.map(&(&1.ai_competition_bot_id))

    all_scores = all_bot_ids
    |> Enum.map(fn id -> %{id: id, score: base_points(game, id)} end)
    |> Enum.sort(fn %{score: score1}, %{score: score2} -> score1 > score2 end)
    |> Enum.chunk_by(fn %{score: score} -> score end)

    winners = Enum.at(all_scores, 0)
    winner = Enum.find(winners, fn %{id: id} -> id == bot_id end)

    if winner && winner.score > 0 do
      if Enum.count(winners) > 1 do
        winner.score + 5
      else
        winner.score + 10
      end
    else
      base_points(game, bot_id)
    end
  end

  def base_points(game, bot_id) do
    score = game.final_state
    |> Map.fetch!("colors")
    |> Enum.flat_map(fn c -> c end)
    |> Enum.map(fn c -> (if c == bot_id, do: 1, else: 0) end)
    |> Api.Enum.avg

    score * 100 |> trunc
  rescue
    Enum.OutOfBoundsError -> 0
  end

  def submit_to_ai_server(game, "compete") do
    body = %{
      type: "compete",
      payload: %{
        game_state: game.initial_state,
      },
      callback_url: System.get_env("AI_CALLBACK_URL") <> "/api/games/" <> game.id,
      auth_token: game.id,
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer " <> System.get_env("AI_SERVER_TOKEN")},
    ]

    url = System.get_env("AI_SERVER_HOST") <> "/jobs"

    HTTPoison.post(url, Poison.encode!(body), headers)
  end
end
