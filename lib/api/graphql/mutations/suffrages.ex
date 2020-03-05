defmodule Api.GraphQL.Mutations.Suffrages do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}

  alias Api.Accounts
  alias Api.Competitions
  alias Api.Suffrages
  alias Api.Teams

  object :suffrages_mutations do
    @desc "Casts votes"
    field :cast_votes, :user do
      arg :votes, non_null(:string) # stringified json

      middleware RequireAuthn

      resolve fn %{votes: votes}, %{context: %{current_user: current_user}} ->
        ballots = votes |> Poison.decode! |> Map.to_list
        Suffrages.upsert_votes(current_user, ballots)

        {:ok, Accounts.get_user(current_user.id)}
      end
    end

    # =================================================================== Admin

    @desc "Create suffrage (admin only)"
    field :create_suffrage, :suffrage do
      arg :suffrage, non_null(:suffrage_input)
      arg :competition_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{suffrage: suffrage, competition_id: competition_id}, _info ->
        Suffrages.create_suffrage(suffrage, competition_id)
      end
    end

    @desc "Updates a suffrage (admin only)"
    field :update_suffrage, :suffrage do
      arg :id, non_null(:string)
      arg :suffrage, non_null(:suffrage_input)

      middleware RequireAdmin

      resolve fn %{id: id, suffrage: suffrage} , _info ->
        Suffrages.update_suffrage(id, suffrage)
      end
    end

    @desc "Delete suffrage (admin only)"
    field :delete_suffrage, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.delete_suffrage(id)
      end
    end

    @desc "Opens voting for a suffrage"
    field :start_suffrage_voting, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.start_suffrage(id)
      end
    end

    @desc "Closes voting for a suffrage"
    field :end_suffrage_voting, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.end_suffrage(id)
      end
    end

    @desc "Resolves a suffrage"
    field :resolve_suffrage, :suffrage do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Suffrages.resolve_suffrage!(id)
      end
    end

    #========================================================================== Paper Votes

    @desc "Disqualify team (admin only)"
    field :disqualify_team, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Competitions.default_competition.suffrages
        |> Enum.each(fn suffrage ->
          Suffrages.disqualify_team(id, suffrage.id, current_user)
        end)

        {:ok, Teams.get_team(id)}
      end
    end

    #========================================================================== Paper Votes

    @desc "Creates a paper vote"
    field :create_paper_vote, :paper_vote do
      arg :suffrage_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{suffrage_id: suffrage_id}, %{context: %{current_user: current_user}} ->
        Suffrages.create_paper_vote(suffrage_id, current_user)
      end
    end

    @desc "Redeems a paper vote"
    field :redeem_paper_vote, :paper_vote do
      arg :paper_vote_id, non_null(:string)
      arg :user_id, non_null(:string)
      arg :team_id, non_null(:string)

      middleware RequireAdmin

      resolve fn args, info ->
        %{paper_vote_id: paper_vote_id, user_id: user_id, team_id: team_id} = args
        %{context: %{current_user: current_user}} = info

        paper_vote = Suffrages.get_paper_vote(paper_vote_id)
        user = Accounts.get_user(user_id)
        team = Teams.get_team(team_id)

        Suffrages.redeem_paper_vote(paper_vote, team, user, paper_vote.suffrage, current_user)
      end
    end

    @desc "Annuls a paper vote"
    field :annul_paper_vote, :paper_vote do
      arg :paper_vote_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{paper_vote_id: paper_vote_id}, %{context: %{current_user: current_user}} ->
        paper_vote = Suffrages.get_paper_vote(paper_vote_id)

        Suffrages.annul_paper_vote(paper_vote, current_user, paper_vote.suffrage)
      end
    end
  end
end
