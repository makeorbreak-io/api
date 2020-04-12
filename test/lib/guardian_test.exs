defmodule ApiWeb.GuardianTest do
	use ExUnit.Case, async: true

	alias Api.Repo
	alias Api.Accounts.User
	alias ApiWeb.Guardian

	setup do
   	:ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

		user = User.changeset(%User{}, %{
			email: "email@example.com",
			password: "thisisapassword"
			})
		|> Repo.insert!

		{:ok, user: user}
	end

	test "generates token for valid user", %{user: user} do
		assert {:ok, _} = Guardian.subject_for_token(user, "")
	end

	test "generates error for invalid user", %{} do
		assert { :error, "Unknown resource type" } = Guardian.subject_for_token(%{}, "")
	end

	test "finds user from valid claims", %{user: user} do
		{:ok, _token, claims} = Guardian.encode_and_sign(user)
		assert {:ok, user} = Guardian.resource_from_claims(claims)
	end

	test "doesn't find user from invalid claims", %{} do
		assert { :error, "Unknown resource type" } = Guardian.resource_from_claims("bad")
	end
end
