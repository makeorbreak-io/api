defmodule Api.GraphQL.Mutations.Teams do
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Middleware.{RequireAuthn, RequireAdmin}

  alias Api.Competitions
  alias Api.Integrations.Github
  alias Api.Teams
  alias Api.Teams.ProjectFavorites

  object :teams_mutations do
    @desc "Creates a team"
    field :create_team, type: :team do
      arg :team, non_null(:team_input)

      middleware RequireAuthn

      resolve fn %{team: params}, %{context: %{current_user: current_user}} ->
        team_params = params |> Map.merge(%{competition_id: Competitions.default_competition.id})

        Teams.create_team(current_user, team_params)
      end
    end

    @desc "Updates a team"
    field :update_team, type: :team do
      arg :id, non_null(:string)
      arg :team, non_null(:team_input)

      middleware RequireAuthn

      resolve fn %{id: id, team: params}, %{context: %{current_user: current_user}} ->
        params = if Map.has_key?(params, :prize_preference) do
          Map.put(params, :prize_preference, params.prize_preference |> Poison.decode!)
        else
          params
        end

        Teams.update_team(current_user, id, params)
      end
    end

    @desc "Deletes a team"
    field :delete_team, type: :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.delete_team(current_user, id)
      end
    end

    @desc "Invites new members to a team"
    field :invite, type: :team do
      arg :id, non_null(:string)
      arg :emails, non_null(list_of(:string))

      middleware RequireAuthn

      resolve fn %{id: id, emails: emails}, %{context: %{current_user: current_user}} ->
        Enum.each emails, fn email ->
          Teams.create_invite(current_user.id, id, %{email: email})
        end

        {:ok, Teams.get_team(id)}
      end
    end

    @desc "Accepts an invite"
    field :accept_invite, type: :user do
      arg :id, non_null(:string)

      middleware RequireAuthn
      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.accept_invite(current_user, id)
      end
    end

    @desc "Rejects an invite"
    field :reject_invite, type: :user do
      arg :id, non_null(:string)

      middleware RequireAuthn
      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.reject_invite(current_user, id)
      end
    end

    @desc "Revokes an invite"
    field :revoke_invite, type: :team do
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{id: id}, %{context: %{current_user: current_user}} ->
        Teams.delete_invite(current_user, id)
      end
    end

    @desc "Removes a user from team"
    field :remove_from_team, type: :team do
      arg :user_id, non_null(:string)
      arg :id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{id: id, user_id: user_id}, %{context: %{current_user: current_user}} ->
        Teams.remove_membership(current_user, id, user_id)

        {:ok, Teams.get_team(id)}
      end
    end

    @desc "Toggles favorite status on a project (team)"
    field :toggle_project_favorite, :project_favorite do
      arg :team_id, non_null(:string)

      middleware RequireAuthn

      resolve fn %{team_id: team_id}, %{context: %{current_user: current_user}} ->
        ProjectFavorites.toggle_favorite(current_user.id, team_id)
      end
    end

    # =================================================================== Admin

    @desc "Apply the team to the hackathon (admin only)"
    field :apply_team_to_hackathon, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.update_any_team(id, %{applied: true})
      end
    end

    @desc "De-apply the team from the hackathon (admin only)"
    field :deapply_team_from_hackathon, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.update_any_team(id, %{applied: false})
      end
    end

    @desc "Accepts a team in the hackathon"
    field :accept_team, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.accept_team(id)
      end
    end

    @desc "Delete the team (admin only)"
    field :delete_any_team, :string do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.delete_any_team(id)
        {:ok, id}
      end
    end

    @desc "Removes any team membership (admin only)"
    field :remove_any_membership, :team do
      arg :team_id, non_null(:string)
      arg :user_id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{team_id: team_id, user_id: user_id}, _info ->
        Teams.remove_any_membership(team_id, user_id)
      end
    end

    @desc "Makes a team eligible for voting"
    field :make_team_eligible, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Teams.update_any_team(id, %{eligible: true})
      end
    end

    @desc "Creates a repo on github for a team"
    field :create_team_repo, :team do
      arg :id, non_null(:string)

      middleware RequireAdmin

      resolve fn %{id: id}, _info ->
        Github.create_repo(id)
      end
    end
  end
end
