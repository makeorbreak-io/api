defmodule Api.Accounts do
  import Ecto.Query, warn: false

  alias Api.{Mailer, Repo}
  alias Api.Accounts.User
  alias Api.Teams
  alias Api.Notifications.Emails
  alias ApiWeb.Guardian
  # alias Guardian.Permissions

  def create_session(email, password) do
    Repo.get_by(User, email: email)
    |> check_password(password)
    |> sign_user
  end

  def delete_session(token) do
    revoke_claims(token)
  end

  def list_users do
    Repo.all(User)
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def create_user(user_params) do
    changeset = User.registration_changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        Teams.associate_invites_with_user(user.email, user.id)

        Emails.registration_email(user) |> Mailer.deliver_later

        {:ok, jwt, _claims} = ApiWeb.Guardian.encode_and_sign(user)

        {:ok, jwt}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def update_user(current_user, id, params) do
    user = get_user(id)

    if user.id == current_user.id do
      changeset = User.participant_changeset(user, params)
      Repo.update(changeset)
    else
      {:unauthorized, :unauthorized}
    end
  end

  def update_any_user(id, params) do
    user = get_user(id)

    changeset = User.admin_changeset(user, params)
    Repo.update(changeset)
  end

  def delete_user(current_user, id) do
    user = Repo.get!(User, id)

    if user.id == current_user.id do
      changeset = User.participant_changeset(user, %{
        email: user.id <> "@deleted",
        name: nil,
        password_hash: nil,
        github_handle: nil,
        tshirt_size: nil,
        pwd_recovery_token: nil,
        pwd_recovery_token_expiration: nil,
        data_usage_consent: nil,
        deleted_at: NaiveDateTime.utc_now,
      })

      Repo.update(changeset)
    else
      {:unauthorized, :unauthorized}
    end
  end

  def delete_any_user(id) do
    user = get_user(id)
    Repo.delete(user)
  end

  def get_pwd_token(email) do
    Repo.get_by(User, email: email)
    |> add_pwd_recovery_data()
  end

  def recover_password(token, new_password) do
    Repo.get_by(User, pwd_recovery_token: token)
    |> maybe_update_password(new_password)
  end

  defp check_password(nil, _password), do: {:error, :wrong_credentials}
  defp check_password(user, password) do
    Argon2.check_pass(password, user.password_hash) && {:ok, user} || {:error, :wrong_credentials}
  end

  defp sign_user({:error, error}), do: {:error, error}
  defp sign_user({:ok, user}) do
    # {:ok, jwt, _} = Guardian.encode_and_sign(
    #   user,
    #   :token,
    #   perms: %{"#{user.role}": Permissions.max}
    # )
    {:ok, jwt, _full_claims} = Guardian.encode_and_sign(user)
    {:ok, jwt}
  end

  defp revoke_claims(token) do
    Guardian.revoke(token)
  end

  defp add_pwd_recovery_data(nil), do: :user_not_found
  defp add_pwd_recovery_data(user) do
    changeset = User.changeset(user, %{
      pwd_recovery_token: User.generate_token(),
      pwd_recovery_token_expiration: User.calculate_token_expiration()
    })

    case Repo.update(changeset) do
      {:ok, user} ->
        Emails.recover_password_email(user) |> Mailer.deliver_later
        {:ok, user}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp maybe_update_password(nil, _), do: :invalid_token
  defp maybe_update_password(user, new_password) do
    now = DateTime.utc_now

    if DateTime.compare(now, user.pwd_recovery_token_expiration) == :lt do
      changeset = User.registration_changeset(user, %{password: new_password})

      Repo.update(changeset)
    else
      :expired_token
    end
  end
end
