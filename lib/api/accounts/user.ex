defmodule Api.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Api.Repo
  alias Api.Competitions.Attendance, as: CompAttendance
  alias Api.{Teams.Invite, Teams.Membership}
  alias Api.{Events.Event, Events.Attendance}
  alias Api.{Teams.Invite, Teams.Membership, Teams.ProjectFavorite}
  alias Api.AICompetition.Bot

  @valid_attrs ~w(
    email
    name
    password
    github_handle
    tshirt_size
    pwd_recovery_token
    pwd_recovery_token_expiration
    data_usage_consent
    spam_consent
    share_consent
    deleted_at
  )a

  @admin_attrs @valid_attrs ++ ~w(
    role
  )a

  @required_attrs ~w(
    email
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :email, :string
    field :name, :string
    field :password_hash, :string
    field :github_handle, :string
    field :role, :string, default: "participant"
    field :tshirt_size, :string
    field :pwd_recovery_token, :string
    field :pwd_recovery_token_expiration, :utc_datetime, default: nil
    field :data_usage_consent, :boolean, default: false
    field :spam_consent, :boolean, default: false
    field :share_consent, :boolean, default: false
    field :deleted_at, :utc_datetime, default: nil

    timestamps()

    # Virtual fields
    field :password, :string, virtual: true

    # Associations
    has_many :invites, Invite, foreign_key: :host_id, on_delete: :delete_all
    has_many :invitations, Invite, foreign_key: :invitee_id, on_delete: :delete_all
    has_many :memberships, Membership, foreign_key: :user_id, on_delete: :delete_all
    has_many :teams, through: [:memberships, :team]
    has_many :ai_competition_bots, Bot
    has_many :attendances, CompAttendance, foreign_key: :attendee
    has_many :project_favorites, ProjectFavorite

    many_to_many :events, Event, join_through: Attendance, on_delete: :delete_all
  end

  def changeset(struct, params \\ %{}),  do: _cs(struct, params, @valid_attrs)
  def participant_changeset(struct, params \\ %{}),  do: _cs(struct, params, @valid_attrs)
  def admin_changeset(struct, params \\ %{}), do: _cs(struct, params, @admin_attrs)
  defp _cs(struct, params, attrs) do
    struct
    |> cast(params, attrs)
    |> validate_required(@required_attrs)
    |> validate_length(:email, min: 1, max: 255)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:password_recovery_token)
  end

  def registration_changeset(struct, params \\ %{}) do
    struct
    |> changeset(params)
    |> validate_required(~w(password)a)
    |> validate_length(:password, min: 6)
    |> hash_password
  end

  defp hash_password(%{valid?: false} = changeset), do: changeset
  defp hash_password(%{valid?: true} = changeset) do
    hashed_password =
      changeset
      |> get_field(:password)
      |> Argon2.hash_pwd_salt()

    changeset
    |> put_change(:password_hash, hashed_password)
  end

  # gravatar hash
  def gravatar_hash(%{email: email}),
    do: :crypto.hash(:md5, String.trim(email)) |> Base.encode16(case: :lower)

  def display_name(%{name: name, email: email, deleted_at: deleted_at}) do
    if deleted_at == nil, do: name || (email |> String.split("@") |> Enum.at(0)), else: "[deleted]"
  end

  def can_apply_to_events(user) do
    user = Repo.preload(user, [:events, :teams])

    (
      Enum.any?(user.teams, fn team -> team.applied == true && team.accepted == true end) &&
      Enum.count(user.events, fn(w) -> w.year == DateTime.utc_now.year end) < 2
    ) || true
  end

  def can_apply_to_hackathon(user) do
    user = Repo.preload(user, :events)

    Enum.count(user.events, fn(w) -> w.year == DateTime.utc_now.year end) <= 2
  end

  # generate password recovery token
  def generate_token(length \\ 32) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end

  def calculate_token_expiration do
    :erlang.universaltime
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.+(30 * 60)
    |> DateTime.from_unix!
  end

  # def able_to_vote(at \\ nil) do
  #   at = at || DateTime.utc_now

  #   from(
  #     u in User,
  #     left_join: tm in assoc(u, :teams),
  #     left_join: t in assoc(tm, :team),
  #     where: u.role == "participant",
  #     where: is_nil(t.disqualified_at) or t.disqualified_at > ^at,
  #   )
  # end
end
