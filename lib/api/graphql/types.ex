defmodule Api.GraphQL.Types do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: Api.Repo
  use Absinthe.Relay.Schema.Notation, :modern

  alias Api.GraphQL.Resolvers

  alias Api.AICompetition.Bots
  alias Api.Accounts.User
  alias Api.Competitions
  alias Api.Repo
  alias Api.Suffrages

  import_types Absinthe.Type.Custom
  import_types Api.GraphQL.Scalars
  import_types Api.GraphQL.InputTypes

  connection node_type: :ai_competition_game
  object :ai_competition_game do
    field :id, :string
    field :initial_state, :json
    field :final_state, :json
    field :status, :string
    field :is_ranked, :boolean
    field :run, :string
    field :inserted_at, :utc_datetime
    field :updated_at, :utc_datetime

    field :bots, list_of(:ai_competition_bot), resolve: assoc(:bots)
  end

  connection node_type: :ai_competition_bot
  object :ai_competition_bot do
    field :id, :string
    field :sdk, :string
    field :status, :string
    field :title, :string
    field :compilation_output, :string
    field :revision, :integer
    field :inserted_at, :utc_datetime

    field :author, :json do
      resolve fn _args, %{source: source} ->
        user = Repo.preload(source, :user).user
        {:ok, %{
          name: User.display_name(user),
          id: user.id,
        }}
      end
    end

    # source code can only be shown to their respective authors
    field :source_code, :string do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        if source.user_id == current_user.id || current_user.role == "admin" do
          {:ok, source.source_code}
        else
          {:ok, nil}
        end
      end
    end
  end

  connection node_type: :competition
  object :competition do
    field :id, :string
    field :name, :string
    field :status, :string
    field :is_default, :boolean

    field :teams, list_of(:team)
    field :suffrages, list_of(:suffrage)
    field :attendances, list_of(:attendance)
  end

  connection node_type: :email
  object :email do
    field :id, :string
    field :name, :string
    field :subject, :string
    field :title, :string
    field :content, :string
  end

  object :medium do
    field :posts, :json
  end

  object :membership do
    field :user_id, :string
    field :team_id, :string
    field :role, :string

    field :team, :team, resolve: assoc(:team)
    field :user, :user, resolve: assoc(:user)
  end

  connection node_type: :team
  object :team do
    field :id, :string
    field :name, :string
    field :repo, :json # jsonb in postgres
    field :tie_breaker, :integer
    field :project_name, :string
    field :project_desc, :string
    field :prize_preference, :array
    field :applied, :boolean
    field :accepted, :boolean
    field :eligible, :boolean
    field :is_disqualified, :boolean do
      resolve fn _args, %{source: source} ->
        {:ok, Suffrages.is_disqualified(source.id)}
      end
    end

    field :competition, :competition, resolve: assoc(:competition)
    field :memberships, list_of(:membership), resolve: assoc(:memberships)
    field :members, list_of(:user), resolve: assoc(:members)
    field :invites, list_of(:invite), resolve: assoc(:invites)
    field :favorites, list_of(:project_favorite), resolve: assoc(:project_favorites)
    field :suffrages, list_of(:suffrage), resolve: assoc(:suffrages)
  end

  object :project_favorite do
    field :id, :string
    field :team_id, :string
    field :user_id, :string do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        if source.user_id == current_user.id do
          {:ok, source.user_id}
        else
          {:ok, nil}
        end
      end
    end

  end

  connection node_type: :user
  object :user do
    field :id, :string
    field :email, :string
    field :name, :string
    field :github_handle, :string
    field :role, :string
    field :tshirt_size, :string
    field :data_usage_consent, :boolean
    field :spam_consent, :boolean
    field :share_consent, :boolean

    field :display_name, :string, resolve: Resolvers.run_with_source(&User.display_name/1)
    field :gravatar_hash, :string, resolve: Resolvers.run_with_source(&User.gravatar_hash/1)
    field :can_apply_to_events, :boolean, resolve: Resolvers.run_with_source(&User.can_apply_to_events/1)
    field :can_apply_to_hackathon, :boolean, resolve: Resolvers.run_with_source(&User.can_apply_to_hackathon/1)

    field :ai_competition_bot, :ai_competition_bot do
      arg :id, :string

      resolve fn %{id: id}, %{source: source} ->
        {:ok, Bots.user_bot(id, source)}
      end
    end

    field :current_team, :team do
      resolve fn _args, %{source: source} ->
        team = Repo.preload(source, :teams).teams
          |> Enum.at(0)
          |> Repo.preload([:invites, :memberships])

        {:ok, team}
      end
    end

    field :current_ai_competition_bot, :ai_competition_bot do
      resolve fn _args, %{source: source} ->
        {:ok, Bots.current_bot(source)}
      end
    end

    field :current_attendance, :attendance do
      resolve fn _args, %{source: source} ->
        {:ok, Competitions.get_attendance(Competitions.default_competition.id, source.id)}
      end
    end

    field :teams, list_of(:team), resolve: assoc(:teams)
    field :invites, list_of(:invite), resolve: assoc(:invites)
    field :invitations, list_of(:invite), resolve: assoc(:invitations)
    field :ai_competition_bots, list_of(:ai_competition_bot), resolve: assoc(:ai_competition_bots)
    field :events, list_of(:event), resolve: assoc(:events)
    field :favorites, list_of(:project_favorite), resolve: assoc(:project_favorites)
  end

  connection node_type: :invite
  object :invite do
    field :id, :string
    field :open, :boolean
    field :description, :string
    field :email, :string
    field :display_name, :string do
      resolve fn _args, %{source: source} ->
        {
          :ok,
          User.display_name(
            (source.email && %{name: nil, email: source.email, deleted_at: nil})
            || (source |> Repo.preload(:invitee)).invitee
          )
        }
      end
    end
    field :gravatar_hash, :string do
      resolve fn _args, %{source: source} ->
        {
          :ok,
          User.gravatar_hash(
            (source.email && source)
            || (source |> Repo.preload(:invitee)).invitee
          )
        }
      end
    end

    field :invitee, :user, resolve: assoc(:invitee)
    field :host, :user, resolve: assoc(:host)
    field :team, :user, resolve: assoc(:team)
  end

  connection node_type: :event
  object :event do
    field :id, :string
    field :name, :string
    field :slug, :string
    field :summary, :string
    field :description, :string
    field :speaker, :string
    field :participant_limit, :integer
    field :year, :integer
    field :speaker_image, :string
    field :banner_image, :string
    field :short_speaker, :string
    field :short_date, :string

    field :attendances, list_of(:event_attendance), resolve: assoc(:attendances)
    field :users, list_of(:user) do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        role = current_user && current_user.role
        case role do
          "admin" -> {:ok, Repo.preload(source, :users).users}
          _ -> {:ok, []}
        end
      end
    end
  end

  object :attendance do
    field :id, :string
    field :competition_id, :string
    field :attendee, :string
    field :checked_in, :boolean

    field :user, :user do
      resolve fn _args, %{source: source} ->
        {:ok, Repo.get(User, source.attendee) |> Repo.preload([:teams])}
      end
    end

    field :voter_identity, :string do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        if source.attendee == current_user.id do
          {:ok, source.voter_identity}
        else
          {:ok, nil}
        end
      end
    end
  end

  object :event_attendance do
    field :checked_in, :boolean
    field :user, :user do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        role = current_user && current_user.role
        case role do
          "admin" -> {:ok, Repo.preload(source, :user).user}
          _ -> {:ok, nil}
        end
      end
    end
  end

  #============================================================================ Voting / competition
  object :suffrage do
    field :id, :string
    field :name, :string
    field :slug, :string
    field :status, :string
    field :voting_started_at, :naive_datetime
    field :voting_ended_at, :naive_datetime
    field :competition_id

    field :teams, list_of(:team), resolve: assoc(:teams)
  end

  object :vote do
    field :id, :string
    field :voter_identity, :string
    field :ballot, :array
    field :suffrage_id, :string

    field :suffrage, :suffrage, resolve: assoc(:suffrage)
  end

  object :paper_vote do
    field :id, :string
    field :suffrage_id, :string
    field :redeemed_at, :utc_datetime
    field :annuled_at, :utc_datetime
  end

  #============================================================================ Admin
  object :admin_stats do
    field :users, :json
    field :roles, :json
    field :teams, :json
    field :events, :json
  end

  # connection node_type: :flyby
  object :flyby do
    field :id, :string
    field :name, :string
    field :email, :string do
      resolve fn _args, %{source: source, context: %{current_user: current_user}} ->
        if current_user && current_user.role == "admin" do
          {:ok, source.email}
        else
          {:ok, nil}
        end
      end
    end
    field :time, :integer
  end
end
