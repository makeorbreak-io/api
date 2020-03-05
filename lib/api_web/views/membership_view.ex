defmodule ApiWeb.MembershipView do
  use ApiWeb, :view

  alias ApiWeb.InviteView
  import Api.Accounts.User, only: [gravatar_hash: 1]

  def render("member_user.json", %{membership: membership}) do
    %{
      id: membership.user.id,
      role: membership.role,
      gravatar_hash: gravatar_hash(membership.user),
    }
  end

  def render("member_team_short.json", %{membership: membership}) do
    %{
      id: membership.team.id,
      role: membership.role,
      name: membership.team.name,
      applied: membership.team.applied,
    }
  end

  def render("member_team_full.json", %{membership: membership}) do
    %{
      id: membership.team.id,
      role: membership.role,
      name: membership.team.name,
      applied: membership.team.applied,
      members: if Ecto.assoc_loaded?(membership.team.members) do
        render_many(membership.team.members, __MODULE__, "member_user.json", as: :membership)
      end,
      invites: if Ecto.assoc_loaded?(membership.team.invites) do
        render_many(membership.team.invites, InviteView, "invite.json")
      end,
    }
  end
end
