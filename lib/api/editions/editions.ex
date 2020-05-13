defmodule Api.Editions do
  import Ecto.Query, warn: false

  alias Api.{Repo, Mailer}
  alias Api.Accounts.User
  alias Api.Editions.{Edition, Attendance}
  alias Api.Notifications.Emails

  def list_editions do
    Repo.all(Edition)
  end

  def get_edition(id) do
    Repo.get(Edition, id)
    |> Repo.preload([:suffrages, :teams, :attendances, :events])
  end

  def default_edition do
    q = (from c in Edition, where: c.is_default == true)

    (Repo.one(q) || Repo.insert!(%Edition{name: "default", is_default: true}))
    |> Repo.preload(:suffrages)
  end

  def set_as_default(edition_id) do
    Repo.update_all(Edition, set: [is_default: false])
    update_edition(edition_id, %{is_default: true})
  end

  def create_edition(edition_params) do
    changeset = Edition.changeset(%Edition{}, edition_params)
    Repo.insert(changeset)
  end

  def update_edition(id, edition_params) do
    changeset = Edition.changeset(get_edition(id), edition_params)
    Repo.update(changeset)
  end

  def delete_edition(id) do
    c = Repo.get(Edition, id)
    Repo.delete!(c)
  end

  def get_attendance(id), do: Repo.get(Attendance, id)
  def get_attendance(edition_id, attendee) do
    Repo.get_by(Attendance, edition_id: edition_id, attendee: attendee)
  end

  def create_attendance(edition_id, attendee_id) do
    changeset = Attendance.changeset(%Attendance{}, %{
      edition_id: edition_id,
      attendee: attendee_id
    })

    Repo.insert(changeset)
  end

  def toggle_checkin(edition_id, attendee_id) do
    attendance = get_attendance(edition_id, attendee_id)
    toggle_checkin(edition_id, attendee_id, !attendance.checked_in)
  end

  def toggle_checkin(edition_id, attendee_id, value) do
    attendance = get_attendance(edition_id, attendee_id)
    attendee = Repo.get(User, attendee_id)

    changeset = Attendance.changeset(attendance, %{checked_in: value})

    case Repo.update(changeset) do
      {:ok, _attendance} ->
        value && (Emails.checkin_email(attendee) |> Mailer.deliver_later)
        {:ok, attendee}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def delete_attendance(id), do: Repo.get(Attendance, id) |> Repo.delete
  def delete_attendance(id, attendee) do
    get_attendance(id, attendee) |> Repo.delete
  end

end
