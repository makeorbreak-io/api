defmodule Api.SuffragesTest do
  use Api.DataCase

  alias Api.Suffrages
  alias Api.Suffrages.{Candidate, Suffrage}
  alias Api.Teams.Team

  setup do
    member = create_user()
    competition = create_competition()
    create_competition_attendance(competition, member)
    team = create_team(member, competition)

    check_in_everyone(competition.id)

    {
      :ok,
      %{
        c: competition,
        s: create_suffrage(competition.id),
        a: create_admin(),
        m: member,
        t: team,
      },
    }
  end

  test "all suffrages", %{s: s1, c: c} do
    s2 = create_suffrage(c.id)

    assert Suffrages.all_suffrages() == [s1, s2]
  end

  test "create suffrage", %{c: c} do
    {:ok, s1} = Suffrages.create_suffrage(%{name: "koch", slug: "koch-2018"}, c.id)

    assert Repo.get(Suffrage, s1.id)
  end

  test "get suffrage by slug", %{s: s} do
    assert s == Suffrages.by_slug(s.slug)
  end

  test "delete_suffrage", %{c: c} do
    s1 = create_suffrage(c.id)

    Suffrages.delete_suffrage(s1.id)

    refute Repo.get(Suffrage, s1.id)
  end

  test "before start", %{s: s} do
     assert Suffrages.suffrage_status(s.id) == :not_started
  end

  test "start_suffrage", %{s: s} do
    {:ok, _} = Suffrages.start_suffrage(s.id)
    assert Suffrages.suffrage_status(s.id) == :started
  end

  test "end_suffrage", %{s: s} do
    {:ok, _} = Suffrages.start_suffrage(s.id)
    {:ok, _} = Suffrages.end_suffrage(s.id)
    assert Suffrages.suffrage_status(s.id) == :ended
  end

  test "start_suffrage twice", %{s: s} do
    {:ok, _} = Suffrages.start_suffrage(s.id)
    :already_started = Suffrages.start_suffrage(s.id)
  end

  test "end_suffrage without starting", %{s: s} do
    :not_started = Suffrages.end_suffrage(s.id)
  end

  test "end_suffrage twice", %{s: s} do
    {:ok, _} = Suffrages.start_suffrage(s.id)
    {:ok, _} = Suffrages.end_suffrage(s.id)
    :already_ended = Suffrages.end_suffrage(s.id)
  end

  test "create paper vote", %{s: s, a: a} do
    {:ok, _} = Suffrages.create_paper_vote(s.id, a)
  end

  test "create paper vote after end", %{s: s, a: a} do
    Suffrages.start_suffrage(s.id)
    Suffrages.end_suffrage(s.id)

    :already_ended = Suffrages.create_paper_vote(s.id, a)
  end

  test "redeem paper vote", %{s: s, a: a, m: m, t: t, c: c} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)

    make_teams_eligible(c.id)
    Suffrages.start_suffrage(s.id)

    {:ok, _} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not twice",
    %{s: s, a: a, m: m, t: t, c: c} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)

    make_teams_eligible(c.id)
    Suffrages.start_suffrage(s.id)

    {:ok, p} = Suffrages.redeem_paper_vote(p, t, m, s, a)
    {:error, :already_redeemed} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not annulled", %{s: s, a: a, m: m, t: t} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)
    Suffrages.start_suffrage(s.id)

    {:ok, p} = Suffrages.annul_paper_vote(p, a, s)
    {:error, :annulled} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote not eligible", %{s: s, a: a, m: m, t: t} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)
    # Notice I'm not making teams eligible
    Suffrages.start_suffrage(s.id)

    {:error, :team_not_candidate} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote disqualified", %{s: s, a: a, m: m, t: t, c: c} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)
    make_teams_eligible(c.id)
    Suffrages.start_suffrage(s.id)

    Suffrages.disqualify_team(t.id, s.id, a)
    t = Repo.get!(Team, t.id)

    Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote before start", %{s: s, a: a, m: m, t: t} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)

    {:error, :not_started} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "redeem paper vote after end", %{s: s, a: a, m: m, t: t, c: c} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)

    make_teams_eligible(c.id)
    Suffrages.start_suffrage(s.id)
    Suffrages.end_suffrage(s.id)

    {:error, :already_ended} = Suffrages.redeem_paper_vote(p, t, m, s, a)
  end

  test "annul paper vote", %{s: s, a: a} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)
    {:ok, _} = Suffrages.annul_paper_vote(p, a, s)
  end

  test "annul paper vote after end", %{s: s, a: a} do
    {:ok, p} = Suffrages.create_paper_vote(s.id, a)

    Suffrages.start_suffrage(s.id)
    Suffrages.end_suffrage(s.id)

    {:error, :already_ended} = Suffrages.annul_paper_vote(p, a, s)
  end

  test "disqualify team", %{t: t1, s: s1, c: c1} do
    admin = create_admin()

    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    Suffrages.disqualify_team(t1.id, s1.id, admin)

    c = from(
      c in Candidate,
      where: c.team_id == ^t1.id,
      where: c.suffrage_id == ^s1.id )
    |> Repo.one()

    assert c.disqualified_at
    assert c.disqualified_by_id == admin.id
  end

  test "disqualify team twice", %{t: t1, s: s1, c: c1} do
    admin = create_admin()
    admin2 = create_admin()

    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    Suffrages.disqualify_team(t1.id, s1.id, admin)
    Suffrages.disqualify_team(t1.id, s1.id, admin2)

    c = from(
      c in Candidate,
      where: c.team_id == ^t1.id,
      where: c.suffrage_id == ^s1.id )
    |> Repo.one()

    assert c.disqualified_at
    assert c.disqualified_by_id == admin.id
  end

  test "assign missing preferences to team", %{t: t, c: c, s: s1} do
    s2 = create_suffrage(c.id)
    s3 = create_suffrage(c.id)

    assert t.prize_preference == nil
    Suffrages.assign_missing_preferences(c.id)
    assert Repo.get!(Team, t.id).prize_preference |> Enum.sort ==
      [s1.id, s2.id, s3.id] |> Enum.sort
  end
end

defmodule Api.SuffragesTest.CalculatePodium do
  use Api.DataCase

  alias Api.Suffrages
  alias Api.Suffrages.{Suffrage, Candidate}

  setup do
    c1 = create_competition(%{name: "awesome competition", is_default: true})
    s1 = create_suffrage(c1.id)
    u1 = create_attendee(c1)
    t1 = create_team(u1, c1, %{prize_preference: [s1.id]})

    u2 = create_attendee(c1)
    t2 = create_team(u2, c1, %{prize_preference: [s1.id]})

    u3 = create_attendee(c1)
    t3 = create_team(u3, c1, %{prize_preference: [s1.id]})

    u4 = create_attendee(c1)
    t4 = create_team(u4, c1, %{prize_preference: [s1.id]})

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)


    Suffrages.start_suffrage(s1.id)

    {
      :ok,
      %{
        u1: u1,
        u2: u2,
        u3: u3,
        u4: u4,
        t1: t1,
        t2: t2,
        t3: t3,
        t4: t4,
        c1: c1,
        s1: s1,
        a: create_admin(),
      },
    }
  end

  test "insert valid vote", %{t2: t2, u1: u1, s1: s1} do
    Suffrages.upsert_votes(u1, [{s1.id, [t2.id]}])

    {:ok, votes} = Suffrages.get_votes(u1)

    assert Enum.count(votes) == 1
  end

  test "insert invalid vote", %{t1: t1, u1: u1, s1: s1} do
    assert {:error, "Invalid vote"} == Suffrages.upsert_votes(u1, [{s1.id, [t1.id]}])

    {:ok, votes} = Suffrages.get_votes(u1)

    assert Enum.count(votes) == 0
  end

  test "update valid vote", %{t2: t2, t3: t3, u1: u1, s1: s1} do
    Suffrages.upsert_votes(u1, [{s1.id, [t2.id]}])

    Suffrages.upsert_votes(u1, [{s1.id, [t2.id, t3.id]}])

    {:ok, votes} = Suffrages.get_votes(u1)

    assert List.first(votes).ballot == [t2.id, t3.id]
  end

  test "update invalid vote", %{t1: t1, t2: t2, u1: u1, s1: s1} do
    Suffrages.upsert_votes(u1, [{s1.id, [t2.id]}])

    Suffrages.upsert_votes(u1, [{s1.id, [t2.id, t1.id]}])

    {:ok, votes} = Suffrages.get_votes(u1)

    assert List.first(votes).ballot == [t2.id]
  end

  test "calculate_podium", %{c1: c1, t1: t1, t2: t2, t3: t3, t4: t4, s1: s1} do
    create_vote(create_attendance_with_user(c1), s1, [t1.id, t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])
    create_vote(create_attendance_with_user(c1), s1, [t4.id])

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    assert Suffrages.calculate_podium(s1.id) == [
      t1.id,
      t2.id,
      t3.id,
    ]
  end

  test "calculate_podium tie", %{c1: c1, t1: t1, t2: t2, t3: t3, s1: s1} do
    u1 = create_attendee(c1)
    u2 = create_attendee(c1)
    u3 = create_attendee(c1)
    u4 = create_attendee(c1)
    u5 = create_attendee(c1)

    check_in_everyone(c1.id)
    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)

    Suffrages.upsert_votes(u1, [{s1.id, [t2.id]}])
    Suffrages.upsert_votes(u2, [{s1.id, [t1.id]}])
    Suffrages.upsert_votes(u3, [{s1.id, [t2.id]}])
    Suffrages.upsert_votes(u4, [{s1.id, [t1.id]}])
    Suffrages.upsert_votes(u5, [{s1.id, [t3.id]}])

    Repo.get_by!(Candidate, team_id: t1.id) |> Candidate.changeset(%{tie_breaker: 0}) |> Repo.update!
    Repo.get_by!(Candidate, team_id: t2.id) |> Candidate.changeset(%{tie_breaker: -10}) |> Repo.update!
    Repo.get_by!(Candidate, team_id: t3.id) |> Candidate.changeset(%{tie_breaker: -20}) |> Repo.update!

    assert Suffrages.calculate_podium(s1.id) == [t2.id, t1.id, t3.id]
  end

  test "resolve_voting", %{t1: t1, t2: t2, t3: t3, c1: c1, s1: s1, a: a, u1: u1, u2: u2, u3: u3, u4: u4} do
    s2 = create_suffrage(c1.id)
    s3 = create_suffrage(c1.id)

    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t1.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t2.id])
    create_vote(create_attendance_with_user(c1), s1, [t3.id])

    create_vote(create_attendance_with_user(c1), s2, [t1.id])
    create_vote(create_attendance_with_user(c1), s2, [t2.id])
    create_vote(create_attendance_with_user(c1), s2, [t2.id])
    create_vote(create_attendance_with_user(c1), s2, [t2.id])
    create_vote(create_attendance_with_user(c1), s2, [t3.id])
    create_vote(create_attendance_with_user(c1), s2, [t3.id])

    create_vote(create_attendance_with_user(c1), s3, [t1.id])
    create_vote(create_attendance_with_user(c1), s3, [t1.id])
    create_vote(create_attendance_with_user(c1), s3, [t2.id])
    create_vote(create_attendance_with_user(c1), s3, [t3.id])
    create_vote(create_attendance_with_user(c1), s3, [t3.id])
    create_vote(create_attendance_with_user(c1), s3, [t3.id])

    check_in_everyone(c1.id)

    make_teams_eligible(c1.id)
    Suffrages.start_suffrage(s1.id)
    Suffrages.redeem_paper_vote(create_paper_vote(s1, a), t1, a, s1, a)
    Suffrages.end_suffrage(s1.id)

    Suffrages.start_suffrage(s2.id)
    Suffrages.redeem_paper_vote(create_paper_vote(s2, a), t2, a, s2, a)
    Suffrages.end_suffrage(s2.id)

    Suffrages.start_suffrage(s3.id)
    Suffrages.redeem_paper_vote(create_paper_vote(s3, a), t3, a, s3, a)
    Suffrages.end_suffrage(s3.id)

    assert Repo.get(Suffrage, s1.id).podium == [
      t1.id,
      t2.id,
      t3.id,
    ]
    assert Repo.get(Suffrage, s2.id).podium == [
      t2.id,
      t3.id,
      t1.id,
    ]
    assert Repo.get(Suffrage, s3.id).podium == [
      t3.id,
      t1.id,
      t2.id,
    ]

    assert Suffrages.missing_voters |> Enum.map(&(&1.id)) |> Enum.sort == Enum.sort([u1.id, u2.id, u3.id, u4.id])
  end
end
