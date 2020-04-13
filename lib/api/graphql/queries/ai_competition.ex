defmodule Api.GraphQL.Queries.AICompetition do
  use Absinthe.Schema.Notation

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}
  alias Api.GraphQL.Resolvers

  alias Api.AICompetition
  alias Api.AICompetition.{Games, Bots, Bot}

  object :ai_competition_queries do
    @desc "Last 50 AI Competition games for the current user"
    field :ai_games, list_of(:ai_competition_game) do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        {:ok, Games.user_games(current_user)}
      end
    end

    field :bot, :ai_competition_bot do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve Resolvers.by_id(Bot)
    end

    field :bots, list_of(:ai_competition_bot) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        bots =
        AICompetition.users_with_valid_bots
        |> Enum.map(&(Bots.current_bot(&1)))

        {:ok, bots}
      end
    end

    field :run_bots, list_of(:ai_competition_bot) do
      arg :run_name, non_null(:string)

      middleware RequireAdmin

      resolve fn %{run_name: run_name}, _info ->
        bots =
        AICompetition.users_with_valid_bots
        |> Enum.map(&(Bots.current_bot(&1, AICompetition.ranked_match_config(run_name).timestamp)))

        {:ok, bots}
      end
    end

    field :run_games, list_of(:ai_competition_game) do
      arg :run_name, non_null(:string)

      middleware RequireAdmin

      resolve fn %{run_name: run_name}, _info ->
        {:ok, Games.run_games(run_name)}
      end
    end

    field :game, :ai_competition_game do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        {:ok, Games.get_game(id)}
      end
    end
  end
end
