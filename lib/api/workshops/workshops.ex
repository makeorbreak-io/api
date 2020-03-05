defmodule Api.Workshops do
  import Ecto.Query, warn: false

  alias Api.{Mailer, Repo}
  alias Api.Accounts.User
  alias Api.{Workshops.Workshop, Workshops.Attendance}
  alias Api.Notifications.Emails

  def all do
    Repo.all(Workshop)
  end

  def get(slug) do
    Repo.get_by(Workshop, slug: slug)
  end

  def create(workshop_params) do
    changeset = Workshop.changeset(%Workshop{}, workshop_params)

    Repo.insert(changeset)
  end

  def update(slug, workshop_params) do
    workshop = get(slug)
    changeset = Workshop.changeset(workshop, workshop_params)

    Repo.update(changeset)
  end

  def delete(slug) do
    workshop = get(slug)
    Repo.delete(workshop)
  end

  def join(user, slug) do
    workshop = get(slug)

    cond do
      workshop.participants_counter < workshop.participant_limit &&
      User.can_apply_to_workshops(user) ->
        changeset = Attendance.changeset(%Attendance{},
          %{user_id: user.id, workshop_id: workshop.id})

        case Repo.insert(changeset) do
          {:ok, _attendance} ->
            increase_participants_counter(workshop)
            Emails.joined_workshop_email(user, workshop) |> Mailer.deliver_later

            {:ok, workshop |> Repo.preload(:attendances)}
          {:error, _} -> :join_workshop
        end

     !User.can_apply_to_workshops(user) -> {:error, :user_cant_apply}
     true -> {:error, :workshop_full}
    end
  end

  def leave(user, slug) do
    workshop = get(slug)

    query = from(w in Attendance,
      where: w.workshop_id == type(^workshop.id, Ecto.UUID)
        and w.user_id == type(^user.id, Ecto.UUID))

    case Repo.delete_all(query) do
      {1, nil} ->
        decrease_participants_counter(workshop)

        {:ok, workshop |> Repo.preload(:attendances)}
      {0, nil} -> {:error, :not_workshop_attendee}
    end
  end

  def toggle_checkin(slug, user_id, value) do
    workshop = get(slug)

    result = from(a in Attendance,
      where: a.workshop_id == ^workshop.id,
      where: a.user_id == ^user_id,
      update: [set: [checked_in: ^value]])
      |> Repo.update_all([])

    case result do
      {1, _} -> {:ok, Repo.get(Workshop, workshop.id)}
      {0, _} -> if value, do: :checkin, else: :remove_checkin
    end
  end

  defp increase_participants_counter(workshop) do
    Workshop.changeset(workshop, %{
      participants_counter: workshop.participants_counter + 1
    }) |> Repo.update()
  end

  defp decrease_participants_counter(workshop) do
    Workshop.changeset(workshop, %{
      participants_counter: workshop.participants_counter - 1
    }) |> Repo.update()
  end
end
