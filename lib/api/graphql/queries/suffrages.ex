defmodule Api.GraphQL.Queries.Suffrages do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}

  alias Api.Competitions
  alias Api.Suffrages

  object :suffrages_queries do
    @desc "Voting categories"
    field :suffrages, list_of(:suffrage) do
      middleware RequireAuthn

      resolve fn _args, _info ->
        {:ok, Suffrages.all_suffrages}
      end
    end

    field :votes, list_of(:vote) do
      middleware RequireAuthn

      resolve fn _args, %{context: %{current_user: current_user}} ->
        Suffrages.get_votes(current_user)
      end
    end

    field :info_start, non_null(:string) do
      resolve fn _args, _info ->
        {:ok, Suffrages.build_info_start(Competitions.default_competition().id)}
      end
    end

    field :info_end, :string do
      resolve fn _args, _info ->
        {:ok, Suffrages.build_info_end(Competitions.default_competition().id)}
      end
    end

    field :unredeemed_paper_votes, list_of(:paper_vote) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        {
          :ok,
          Suffrages.unredeemed_paper_votes(Competitions.default_competition().id)
          |> Api.Repo.all()
        }
      end
    end

    field :redeemed_paper_votes, list_of(:paper_vote) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        {
          :ok,
          Suffrages.redeemed_paper_votes(Competitions.default_competition().id)
          |> Api.Repo.all()
        }
      end
    end

    field :missing_voters, list_of(:user) do
      middleware RequireAdmin

      resolve fn _args, _info ->
        {:ok, Suffrages.missing_voters()}
      end
    end
  end
end

