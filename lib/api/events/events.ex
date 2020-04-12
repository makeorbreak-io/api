defmodule Api.Events do
  import Ecto.Query, warn: false

  alias Api.{Mailer, Repo}
  alias Api.Accounts.User
  alias Api.{Events.Event, Events.Attendance}
  alias Api.Notifications.Emails

  def all do
    Repo.all(Event)
  end

  def get(slug) do
    Repo.get_by(Event, slug: slug)
  end

  def create(event_params) do
    changeset = Event.changeset(%Event{}, event_params)

    Repo.insert(changeset)
  end

  def update(slug, event_params) do
    event = get(slug)
    changeset = Event.changeset(event, event_params)

    Repo.update(changeset)
  end

  def delete(slug) do
    event = get(slug)
    Repo.delete(event)
  end

  def join(user, slug) do
    event = get(slug)

    cond do
      event.participants_counter < event.participant_limit &&
      User.can_apply_to_events(user) ->
        changeset = Attendance.changeset(%Attendance{},
          %{user_id: user.id, event_id: event.id})

        case Repo.insert(changeset) do
          {:ok, _attendance} ->
            increase_participants_counter(event)
            Emails.joined_event_email(user, event) |> Mailer.deliver_later

            {:ok, event |> Repo.preload(:attendances)}
          {:error, _} -> :join_event
        end

     !User.can_apply_to_events(user) -> {:error, :user_cant_apply}
     true -> {:error, :event_full}
    end
  end

  def leave(user, slug) do
    event = get(slug)

    query = from(w in Attendance,
      where: w.event_id == type(^event.id, Ecto.UUID)
        and w.user_id == type(^user.id, Ecto.UUID))

    case Repo.delete_all(query) do
      {1, nil} ->
        decrease_participants_counter(event)

        {:ok, event |> Repo.preload(:attendances)}
      {0, nil} -> {:error, :not_event_attendee}
    end
  end

  def toggle_checkin(slug, user_id, value) do
    event = get(slug)

    result = from(a in Attendance,
      where: a.event_id == ^event.id,
      where: a.user_id == ^user_id,
      update: [set: [checked_in: ^value]])
      |> Repo.update_all([])

    case result do
      {1, _} -> {:ok, Repo.get(Event, event.id)}
      {0, _} -> if value, do: :checkin, else: :remove_checkin
    end
  end

  defp increase_participants_counter(event) do
    Event.changeset(event, %{
      participants_counter: event.participants_counter + 1
    }) |> Repo.update()
  end

  defp decrease_participants_counter(event) do
    Event.changeset(event, %{
      participants_counter: event.participants_counter - 1
    }) |> Repo.update()
  end
end
