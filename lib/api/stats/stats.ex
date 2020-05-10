defmodule Api.Stats do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Api.Accounts.User
  alias Api.Events.{Event, Attendance}
  alias Api.Editions.Attendance, as: EditionAttendance
  alias Api.Teams.{Team, Membership}

  def get do
    roles = from(
      u in User,
      group_by: :role,
      order_by: :role,
      select: %{role: u.role, total: count(u.id)}
    )
    applied_teams = from t in Team, where: t.applied == true
    applied_users = from u in Membership,
      join: t in assoc(u, :team),
      where: t.applied == true,
      preload: [team: t]
    checked_in_users = from a in EditionAttendance,
      where: a.checked_in == true

    %{
      users: %{
        total: Repo.aggregate(User, :count, :id),
        hackathon: Repo.aggregate(applied_users, :count, :user_id),
        checked_in: Repo.aggregate(checked_in_users, :count, :id),
      },
      roles: Repo.all(roles),
      teams: %{
        total: Repo.aggregate(Team, :count, :id),
        applied: Repo.aggregate(applied_teams, :count, :id),
      },
      events: event_stats(),
    }
  end

  defp event_stats do
    events = Repo.all(Event)

    Enum.map(events, fn(event) ->
      query = from w in Attendance,
        where: w.event_id == type(^event.id, Ecto.UUID)

      attendees_count = Repo.aggregate(query, :count, :event_id)

      %{
        name: event.name,
        slug: event.slug,
        participants: attendees_count,
        participant_limit: event.participant_limit,
      }
    end)
  end
end
