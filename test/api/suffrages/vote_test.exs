defmodule Api.VoteTest do
  use Api.DataCase

  alias Api.Suffrages.Vote

  setup %{} do
    competition = create_competition()
    {:ok, %{
      suffrage: create_suffrage(competition.id),
      team: create_team(create_user(), competition),
    }}
  end

  test "changeset", %{suffrage: suffrage, team: team} do
    assert Vote.changeset(%Vote{}, %{
      voter_identity: "derp",
      suffrage_id: suffrage.id,
      ballot: [team.id],
    }).valid?
  end
end
