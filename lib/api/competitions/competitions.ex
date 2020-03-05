defmodule Api.Competitions do
  import Ecto.Query, warn: false

  alias Api.{Repo, Mailer}
  alias Api.Accounts.User
  alias Api.Competitions.{Competition, Attendance}
  alias Api.Notifications.Emails

  def list_competitions do
    Repo.all(Competition)
  end

  def get_competition(id) do
    Repo.get(Competition, id)
    |> Repo.preload([:suffrages, :teams, :attendances])
  end

  def default_competition do
    q = (from c in Competition, where: c.is_default == true)

    (Repo.one(q) || Repo.insert!(%Competition{name: "default", is_default: true}))
    |> Repo.preload(:suffrages)
  end

  def set_as_default(competition_id) do
    Repo.update_all(Competition, set: [is_default: false])
    update_competition(competition_id, %{is_default: true})
  end

  def create_competition(competition_params) do
    changeset = Competition.changeset(%Competition{}, competition_params)
    Repo.insert(changeset)
  end

  def update_competition(id, competition_params) do
    changeset = Competition.changeset(get_competition(id), competition_params)
    Repo.update(changeset)
  end

  def delete_competition(id) do
    c = Repo.get(Competition, id)
    Repo.delete!(c)
  end

  def get_attendance(id), do: Repo.get(Attendance, id)
  def get_attendance(competition_id, attendee) do
    Repo.get_by(Attendance, competition_id: competition_id, attendee: attendee)
  end

  def create_attendance(competition_id, attendee_id) do
    changeset = Attendance.changeset(%Attendance{}, %{
      competition_id: competition_id,
      attendee: attendee_id
    })

    Repo.insert(changeset)
  end

  def toggle_checkin(competition_id, attendee_id) do
    attendance = get_attendance(competition_id, attendee_id)
    toggle_checkin(competition_id, attendee_id, !attendance.checked_in)
  end

  def toggle_checkin(competition_id, attendee_id, value) do
    attendance = get_attendance(competition_id, attendee_id)
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
