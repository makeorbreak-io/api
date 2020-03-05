defmodule Api.AICompetition do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.AICompetition.{Games, Game, Bot, Bots, GameTemplates}

  def users_with_valid_bots do
    from(
      u in User,
      join: b in Bot,
      where:
        u.role == "participant" and
        b.user_id == u.id and
        not is_nil(b.id) and
        b.status == "processed",
      order_by: u.id,
      distinct: u.id
    )
    |> Repo.all
  end

  def user_pairs(users) do
    users
    |> Enum.map(fn u1 ->
      users
      |> Enum.map(fn u2 ->
          [u1, u2]
          |> Enum.sort(&(&1.id < &2.id))
        end)
      |> Enum.filter(&(&1 != nil && Enum.at(&1, 0).id != Enum.at(&1, 1).id))
    end)
    |> Enum.flat_map(&(&1))
    |> Enum.uniq
  end

  def perform_training_matches do
    templates = [
      &GameTemplates.ten_by_ten/2,
      &GameTemplates.five_by_eleven/2,
    ]

    users_with_valid_bots()
    |> user_pairs
    |> Enum.flat_map(fn [u1, u2] ->
      templates
      |> Enum.map(fn template ->
        Games.create_game(
          Bots.current_bot(u1),
          Bots.current_bot(u2),
          false,
          nil,
          template
        )
      end)
    end)
  end

  def perform_ranked_matches(run_name, timestamp, templates \\ []) do
    users_with_valid_bots()
    |> user_pairs
    |> Enum.flat_map(fn [u1, u2] ->
      templates |> Enum.map(fn template ->
        Games.create_game(
          Bots.current_bot(u1, timestamp),
          Bots.current_bot(u2, timestamp),
          true,
          run_name,
          template
        )
      end)
    end)
  end

  def ranked_match_config(run_name) do
    %{
      "day 1" => %{timestamp: ~N[2018-04-10 03:00:00], templates: [
        &GameTemplates.ten_by_ten/2, &GameTemplates.five_by_eleven/2
      ]},
      "day 2" => %{timestamp: ~N[2018-04-11 03:00:00], templates: [
        &GameTemplates.ten_by_ten/2, &GameTemplates.five_by_eleven/2
      ]},
      "day 3" => %{timestamp: ~N[2018-04-12 03:00:00], templates: [
        &GameTemplates.ten_by_ten/2, &GameTemplates.five_by_eleven/2
      ]},
      "day 4" => %{timestamp: ~N[2018-04-13 03:00:00], templates: [
        &GameTemplates.ten_by_ten/2, &GameTemplates.five_by_eleven/2
      ]},
      "day 5" => %{timestamp: ~N[2018-04-14 03:00:00], templates: [
        &GameTemplates.seven_by_thirteen/2, &GameTemplates.seven_by_thirteen/2
      ]},
      "day 6" => %{timestamp: ~N[2018-04-15 03:00:00], templates: [
        &GameTemplates.seven_by_thirteen_b/2, &GameTemplates.seven_by_thirteen_b/2
      ]},
    }
    |> Map.fetch!(run_name)
  end

  def day_performance_bonus(run_name) do
    %{
      "day 1" => [0.5, 0.4, 0.3, 0.2, 0.1],
      "day 2" => [0.8, 0.6, 0.4, 0.3, 0.2],
      "day 3" => [1.1, 0.9, 0.7, 0.5, 0.3],
      "day 4" => [1.4, 1.2, 0.9, 0.6, 0.4],
      "day 5" => [1.7, 1.4, 1.1, 0.8, 0.5],
      "day 6" => [0.0, 0.0, 0.0, 0.0, 0.0],
    }
    |> Map.fetch!(run_name)
  end

  def day_leaderboard(run_name) do
    %{timestamp: timestamp} = ranked_match_config(run_name)

    users_with_valid_bots()
    |> Enum.map(fn user ->
      bot = Bots.current_bot(user, timestamp)

      game_scores = from(
        g in Game,
        join: gb in assoc(g, :game_bots),
        where:
          g.is_ranked == true and
          g.status == "processed" and
          g.run == ^run_name and
          gb.ai_competition_bot_id == ^bot.id,
        preload: [:game_bots]
      )
      |> Repo.all
      |> Enum.map(fn g ->
        %{
          mine: Enum.find(g.game_bots, fn gb -> gb.ai_competition_bot_id == bot.id end).score,
          min: Enum.min_by(g.game_bots, &(&1.score)).score,
          max: Enum.max_by(g.game_bots, &(&1.score)).score,
        }
      end)

      player = %{
        name: User.display_name(user),
        bot: "#{bot.title} (rev. #{bot.revision})",
        day_performance: game_scores
          |> Enum.map(&(&1.mine))
          |> Enum.reject(&is_nil/1)
          |> Api.Enum.avg,
        matches: game_scores |> Enum.count,
      }

      performances =
      game_scores
      |> Enum.reduce(%{wins: 0, draws: 0, losses: 0, errors: 0}, fn(rank, acc) ->
          %{mine: mine, min: min, max: max} = rank

          %{
            wins: acc.wins + (if mine != nil && mine == max && mine != min, do: 1, else: 0),
            draws: acc.draws + (if mine != nil && mine == max && mine == min, do: 1, else: 0),
            losses: acc.losses + (if mine != nil && mine != max && mine == min, do: 1, else: 0),
            errors: acc.errors + (if mine == nil, do: 1, else: 0),
          }
        end
      )

      Map.merge(player, performances)
    end)
    |> Enum.sort_by(&(-&1.day_performance))
    |> Api.Enum.rank1224_by(&(&1.day_performance))
    |> Enum.map(fn({player, rank}) ->
      Map.merge(
        player,
        %{
          rank: rank,
          bonus_points: day_performance_bonus(run_name) |> Enum.at(rank),
        }
      )
    end)
  end
end
