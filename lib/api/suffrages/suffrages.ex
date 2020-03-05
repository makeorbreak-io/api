defmodule Api.Suffrages do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Teams.{Team, Membership}
  alias Api.Competitions
  alias Api.Competitions.Attendance
  alias Api.Suffrages.{Suffrage, Vote, PaperVote, Candidate}
  alias Ecto.{Multi, Changeset}

  def all_suffrages do
    Repo.all(Suffrage)
  end

  def create_suffrage(params, competition_id) do
    changeset = Suffrage.changeset(
      %Suffrage{competition_id: competition_id},
      params
    )

    Repo.insert(changeset)
  end

  def get_suffrage(id) do
    Repo.get(Suffrage, id)
  end

  def by_slug(slug) do
    Repo.get_by(Suffrage, slug: slug)
  end

  def update_suffrage(id, params) do
    suffrage = get_suffrage(id)

    Suffrage.changeset(suffrage, params)
    |> Repo.update
  end

  def delete_suffrage(id) do
    suffrage = get_suffrage(id)

    suffrage
    |> Repo.delete
  end

  def suffrage_status(id) do
    s = get_suffrage(id)
    now = DateTime.utc_now

    cond do
      s.voting_ended_at && DateTime.compare(s.voting_ended_at, now) == :lt -> :ended
      s.voting_started_at && DateTime.compare(s.voting_started_at, now) == :lt -> :started
      true -> :not_started
    end
  end

  def suffrage_voting_started_at(id) do
    get_suffrage(id).voting_started_at
  end

  def suffrage_voting_ended_at(id) do
    get_suffrage(id).voting_ended_at
  end

  def suffrage_summary(id) do
    %{
      status: suffrage_status(id),
      unredeemed_paper_votes: unredeemed_paper_votes(id),
      missing_voters: missing_voters(),
    }
  end

  def start_suffrage(suffrage_id) do
    suffrage = get_suffrage(suffrage_id)
    case suffrage_status(suffrage_id) do
      :not_started ->
        create_candidates(suffrage_id)
        assign_tie_breakers(suffrage_id)
        assign_missing_preferences(suffrage.competition_id)
        update_suffrage(suffrage_id, %{voting_started_at: DateTime.utc_now})
      :started -> :already_started
      :ended -> :already_ended
    end
  end

  def candidates(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      c in Candidate,
      left_join: t in assoc(c, :team),
      where: c.suffrage_id == ^suffrage_id,
      where: is_nil(c.disqualified_at) or c.disqualified_at > ^at,
      select: c
    )
  end

  def create_candidate(params) do
    changeset = Candidate.changeset(%Candidate{}, params)

    Repo.insert(changeset)
  end

  def update_candidate(candidate, params) do
    Candidate.changeset(candidate, params) |> Repo.update()
  end

  def create_candidates(suffrage_id) do
    suffrage = get_suffrage(suffrage_id)
    from(t in Team, where: t.competition_id == ^suffrage.competition_id and t.eligible == ^true)
    |> Repo.all()
    |> Enum.each(fn team ->
      create_candidate(%{team_id: team.id, suffrage_id: suffrage_id})
    end)
  end

  def end_suffrage(suffrage_id) do
    case suffrage_status(suffrage_id) do
      :not_started -> :not_started
      :started ->
        at = DateTime.utc_now
        resolve_suffrage!(suffrage_id, at)
        update_suffrage(suffrage_id, %{voting_ended_at: at})
      :ended -> :already_ended
    end
  end

  def upsert_votes(user, votes) do
    multi = Multi.new()

    attendance = Competitions.get_attendance(Competitions.default_competition.id, user.id)

    votes_length = Enum.reduce(votes, 0, fn {_, ballot}, acc -> acc + length(ballot) end)

    valid_votes_length = Enum.reduce(votes, 0, fn {suffrage_id, ballot}, acc ->
      if validate_ballot(suffrage_id, ballot, user), do: acc + length(ballot), else: acc
    end)

    if votes_length != valid_votes_length do
      throw {:error, "Invalid vote"}
    end

    multi = Enum.reduce(votes, multi, fn {suffrage_id, ballot}, acc ->

      case suffrage_status(suffrage_id) do
        :not_started -> throw {:error, :not_started}
        :ended -> throw {:error, :already_ended}
        _ -> nil
      end

      Multi.insert_or_update(acc,
        suffrage_id,
        Vote.changeset(
          get_struct(user, suffrage_id),
          %{
            voter_identity: attendance.voter_identity,
            suffrage_id: suffrage_id,
            ballot: ballot,
          }
        )
      )
    end)

    Repo.transaction(multi)
  catch
    e -> e
  end

  def get_votes(user) do
    votes = from(
      v in Vote,
      join: a in Attendance,
      where: a.attendee == ^user.id,
      where: a.competition_id == ^Competitions.default_competition.id,
      where: a.voter_identity == v.voter_identity
    )
    |> Repo.all

    {:ok, votes}
  end

  def valid_voters(competition_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      c in Candidate,
      join: s in assoc(c, :suffrage),
      left_join: t in assoc(c, :team),
      left_join: m in assoc(t, :members),
      where: s.competition_id == ^competition_id,
      where: is_nil(c.disqualified_at) or c.disqualified_at > ^at,
      select: m
    )
  end

  def build_info_start(competition_id) do
    suffrages = all_suffrages()
    suffrage = List.first(suffrages)
    begun_at = suffrage_voting_started_at(suffrage.id)
    teams =
      candidates(suffrage.id, begun_at)
      |> Repo.all
      |> Repo.preload(:team) |> Enum.map(&(&1.team))

    %{
      participants: %{
        initial_count:
          Repo.aggregate(valid_voters(competition_id, begun_at), :count, :id),
      },
      paper_votes: %{
        initial_count:
          Repo.aggregate(valid_paper_votes(competition_id, begun_at), :count, :id),
      },
      teams: teams |> Enum.map(&(&1.name)),
    } |> Poison.encode!
  end

  def build_info_end(competition_id) do
    suffrages = all_suffrages()
    suffrage = List.first(suffrages)

    case suffrage_status(suffrage.id) do
      :not_started -> throw {:error, :not_started}
      :started -> throw {:error, :ongoing}
      :ended -> nil
    end

    begun_at = suffrage_voting_started_at(suffrage.id)
    ended_at = suffrage_voting_ended_at(suffrage.id)
    teams = candidates(suffrage.id, begun_at) |> Repo.all |> Repo.preload(:team) |> Enum.map(&(&1.team))
    team_name_map =
      teams
      |> Map.new(&{&1.id, &1.name})

    %{
      participants: %{
        initial_count:
          Repo.aggregate(valid_voters(competition_id, begun_at), :count, :id),
        final_count:
          Repo.aggregate(valid_voters(competition_id, ended_at), :count, :id),
      },
      paper_votes: %{
        initial_count:
          Repo.aggregate(valid_paper_votes(competition_id, begun_at), :count, :id) ,
        final_count:
          Repo.aggregate(redeemed_paper_votes(competition_id, ended_at), :count, :id),
      },
      teams: teams |> Enum.map(&(&1.name)),
      podiums: suffrages |> Map.new(fn s -> {s.name, s.podium |> Enum.map(&team_name_map[&1])} end),
      categories_to_votes: suffrages |> Map.new(fn s ->
        {
          s.name,
          ballots(s.id, ended_at)
          |> Map.new(fn {id, ballot} ->
              {
                id,
                ballot
                |> Enum.map(&team_name_map[&1])
              }
            end),
        }
      end),
    } |> Poison.encode!
  catch
    {:error, :not_started} -> nil
    {:error, :ongoing} -> nil
  end

  defp validate_ballot(suffrage_id, votes, user), do: validate_ballot(suffrage_id, votes, user, [])
  defp validate_ballot(_, [], _, acc), do: Enum.all?(acc)
  defp validate_ballot(suffrage_id, [vote|rest], user, acc), do: validate_ballot(
    suffrage_id,
    rest,
    user,
    acc ++ [validate_vote(suffrage_id, vote, user)]
  )

  defp validate_vote(suffrage_id, vote, user) do
    vote
    |> on_valid_team()
    |> on_votable_team(suffrage_id)
    |> not_on_own_team(user)
  end

  defp on_valid_team(vote) do
    Repo.get(Team, vote)
  end

  defp on_votable_team(nil, _), do: nil
  defp on_votable_team(team, suffrage_id) do
    teams = candidates(suffrage_id) |> Repo.all() |> Enum.map(&(&1.team_id))

    case team.id in teams do
      true -> team
      false -> nil
    end
  end

  defp not_on_own_team(nil, _), do: false
  defp not_on_own_team(team, user) do
    user_team = from(
      m in Membership,
      join: t in Team,
      where: m.user_id == ^user.id,
      where: t.competition_id == ^Competitions.default_competition().id,
      where: m.team_id == t.id
    ) |> Repo.one()

    user_team == nil || user_team.team_id != team.id
  end

  defp get_struct(user, suffrage_id) do
    suffrage = get_suffrage(suffrage_id)
    query = from v in Vote,
      join: a in Attendance,
      where: v.suffrage_id == ^suffrage_id,
      where: a.attendee == ^user.id,
      where: a.competition_id == ^suffrage.competition_id,
      where: a.voter_identity == v.voter_identity

    case Repo.one(query) do
      nil -> %Vote{}
      vote -> vote
    end
  end

  def ballots(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    votes =
      Repo.all(from(
        v in Vote,
        where: v.suffrage_id == ^suffrage_id
      ))
      |> Enum.map(&({&1.voter_identity, &1.ballot}))

    paper_votes =
      Repo.all(from(
        pv in redeemed_paper_votes_in_suffrage(suffrage_id, at),
        where: pv.suffrage_id == ^(suffrage_id)
      ))
      |> Enum.map(&({&1.id, [&1.team_id]}))

    (paper_votes ++ votes)
  end

  def resolve_suffrage!(suffrage_id, at \\ nil) do
    get_suffrage(suffrage_id)
    |> Changeset.change(podium: calculate_podium(suffrage_id, at))
    |> Repo.update!
  end

  def calculate_podium(suffrage_id, at \\ nil) do
    candidates = candidates(suffrage_id, at)
    |> Repo.all()

    valid_team_ids =
      candidates
      |> Enum.map(&(&1.team_id))


    votes =
      ballots(suffrage_id, at)
      |> clean_votes_into_ballots(valid_team_ids)

    tie_breakers =
      candidates
      |> Map.new(fn t ->
        {
          t.team_id,
          t.tie_breaker,
        }
      end)

    calculate_podium(votes, valid_team_ids, tie_breakers)
  end

  def clean_votes_into_ballots(votes, valid_team_ids) do
    votes
    |> Enum.map(fn {_id, ballot} ->
      ballot
      |> Enum.filter(&Enum.member?(valid_team_ids, &1))
    end)
    |> Enum.reject(&Enum.empty?/1)
  end

  def calculate_podium(votes, team_ids, tie_breakers) do
    votes
    |> Enum.flat_map(&Markus.ballot_to_pairs(&1, team_ids))
    |> Markus.pairs_to_preferences(team_ids)
    |> Markus.normalize_margins(team_ids)
    |> Markus.widen_paths(team_ids)
    |> Markus.sort_candidates_with_tie_breakers(team_ids, tie_breakers)
    |> Enum.take(3)
  end

  def missing_voters do
    competition_id = Competitions.default_competition().id

    voters = from(
      v in Vote,
      join: u in User,
      join: a in assoc(u, :attendances),
      where: v.voter_identity == a.voter_identity,
      where: a.competition_id == ^competition_id,
      select: u.id
    ) |> Repo.all()

    from(
      u2 in User,
      join: a in assoc(u2, :attendances),
      where: a.competition_id == ^competition_id,
      where: u2.id not in ^voters
    )
    |> Repo.all()
  end

  def valid_paper_votes(competition_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      pv in PaperVote,
      join: s in assoc(pv, :suffrage),
      where: s.competition_id == ^competition_id,
      where: is_nil(pv.annulled_at) or pv.annulled_at > ^at
    )
  end

  def valid_paper_votes_in_suffrage(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from(
      pv in PaperVote,
      where: pv.suffrage_id == ^suffrage_id,
      where: is_nil(pv.annulled_at) or pv.annulled_at > ^at
    )
  end

  def redeemed_paper_votes(competition_id, at \\ nil) do
    at = at || DateTime.utc_now

    from pv in valid_paper_votes(competition_id, at),
      where: not is_nil(pv.team_id)
  end

  def redeemed_paper_votes_in_suffrage(suffrage_id, at \\ nil) do
    at = at || DateTime.utc_now

    from pv in valid_paper_votes_in_suffrage(suffrage_id, at),
      where: not is_nil(pv.team_id)
  end

  def unredeemed_paper_votes(competition_id, at \\ nil) do
    at = at || DateTime.utc_now

    from pv in valid_paper_votes(competition_id, at),
      where: is_nil(pv.redeemed_at)
  end

  def get_paper_vote(id) do
    Repo.get!(PaperVote, id)
    |> Repo.preload(:suffrage)
  end

  def create_paper_vote(suffrage_id, admin) do
    case suffrage_status(suffrage_id) do
      :ended -> :already_ended
      _ ->
        {
          :ok,
          %PaperVote{}
          |> PaperVote.changeset(%{
            created_by_id: admin.id,
            suffrage_id: suffrage_id,
          })
          |> Repo.insert!
        }
    end
  end

  def redeem_paper_vote(paper_vote, team, member, suffrage, admin, at \\ nil) do
    at = at || DateTime.utc_now

    candidate = from(
      c in Candidate,
      where: c.team_id == ^team.id,
      where: c.suffrage_id == ^suffrage.id,
      where: is_nil(c.disqualified_at)
    ) |> Repo.one()

    cond do
      suffrage_status(paper_vote.suffrage_id) == :not_started -> {:error, :not_started}
      suffrage_status(paper_vote.suffrage_id) == :ended -> {:error, :already_ended}
      paper_vote.redeemed_at -> {:error, :already_redeemed}
      paper_vote.annulled_at -> {:error, :annulled}
      is_nil(candidate) -> {:error, :team_not_candidate}
      !is_nil(candidate.disqualified_at) -> {:error, :team_disqualified}
      true ->
        {
          :ok,
          paper_vote
          |> PaperVote.changeset(%{
            redeemed_at: at,
            redeeming_admin_id: admin.id,
            redeeming_member_id: member.id,
            team_id: team.id,
          })
          |> Repo.update!
        }
    end
  end

  def annul_paper_vote(paper_vote, admin, suffrage, at \\ nil) do
    at = at || DateTime.utc_now

    case suffrage_status(suffrage.id) do
      :ended -> {:error, :already_ended}
      _ ->
        {
          :ok,
          paper_vote
          |> PaperVote.changeset(%{
            annulled_at: at,
            annulled_by_id: admin.id,
          })
          |> Repo.update!
          |> Repo.preload(:suffrage)
        }
    end
  end

  def disqualify_team(team_id, suffrage_id, admin) do
    from(
      c in Candidate,
      where: c.team_id == ^team_id,
      where: c.suffrage_id == ^suffrage_id,
      where: is_nil(c.disqualified_at),
      update: [set: [
        disqualified_at: ^(DateTime.utc_now),
        disqualified_by_id: ^(admin.id),
      ]]
    )
    |> Repo.update_all([])
  end

  def is_disqualified(team_id) do
    candidates = from(
      c in Candidate,
      join: s in assoc(c, :suffrage),
      join: comp in assoc(s, :competition),
      where: comp.id == ^Competitions.default_competition.id,
      where: c.team_id == ^team_id,
      where: not is_nil(c.disqualified_at)
    )
    |> Repo.all()

    length(candidates) > 0
  end

  def assign_tie_breakers(suffrage_id) do
    candidates = candidates(suffrage_id) |> Repo.all()

    tie_breakers = 1..Enum.count(candidates) |> Enum.shuffle()

    Enum.reduce(candidates, tie_breakers, fn candidate, acc ->
      {number, remaining} = List.pop_at(acc, 0)
      update_candidate(candidate, %{tie_breaker: number})
      remaining
    end)
  end

  def assign_missing_preferences(competition_id) do
    suffrages = Repo.all(Suffrage) |> Enum.map(&(&1.id))

    Repo.all(from(t in Team,
      where: t.competition_id == ^competition_id and is_nil(t.prize_preference))
    )
    |> Enum.map(fn t ->
      t
      |> Changeset.change(prize_preference: suffrages |> Enum.shuffle)
      |> Repo.update!
    end)
  end
end
