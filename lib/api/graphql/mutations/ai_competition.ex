defmodule Api.GraphQL.Mutations.AICompetition do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}

  alias Api.AICompetition
  alias Api.AICompetition.{Bots}

  object :ai_competition_mutations do
    @desc "Creates an AI competition bot"
    field :create_ai_competition_bot, :user do
      arg :bot, non_null(:ai_competition_bot_input)

      middleware RequireAuthn

      resolve fn %{bot: bot}, %{context: %{current_user: current_user}} ->
        Bots.create_bot(current_user, bot)

        {:ok, current_user}
      end
    end

    @desc "Runs AI Competition ranked games"
    field :perform_ranked_ai_games, :string do
      arg :name, non_null(:string)

      middleware RequireAdmin

      resolve fn %{name: name}, _info ->
        %{timestamp: timestamp, templates: templates} = AICompetition.ranked_match_config(name)

        AICompetition.perform_ranked_matches(name, timestamp, templates)

        {:ok, ""}
      end
    end
  end
end
