defmodule Api.PaperVoteTest do
  use Api.DataCase

  alias Api.Suffrages.PaperVote

  setup %{} do
    user = create_user()
    admin = create_admin()
    competition = create_competition()
    suffrage = create_suffrage(competition.id)
    team = create_team(user, competition)
    {:ok, %{
      user: user,
      admin: admin,
      suffrage: suffrage,
      team: team,
      base_attrs: %{
        hmac_secret: "you'll never guess me",
        suffrage_id: suffrage.id,
        created_by_id: admin.id,
      }
    }}
  end

  test "changeset create", %{base_attrs: base_attrs} do
    assert PaperVote.changeset(%PaperVote{}, base_attrs).valid?
  end

  test "changeset redeem", %{base_attrs: base_attrs, user: user, team: team, admin: admin} do
    assert PaperVote.changeset(%PaperVote{}, Map.merge(base_attrs, %{
      redeemed_at: DateTime.utc_now(),
      redeeming_admin_id: admin.id,
      redeeming_member_id: user.id,
      team_id: team.id,
    })).valid?
  end

  test "changeset annul", %{base_attrs: base_attrs, admin: admin} do
    assert PaperVote.changeset(%PaperVote{}, Map.merge(base_attrs, %{
      annulled_at_id: DateTime.utc_now(),
      annulled_by: admin.id,
    })).valid?
  end
end
