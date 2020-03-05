defmodule Api.Integrations.Github do
  import Ecto.Query, warn: false

  alias Api.Repo
  alias Tentacat.{Client, Repositories, Repositories.Collaborators}
  alias Api.{Teams, Teams.Team}
  import ApiWeb.StringHelper

  @github_token Application.get_env(:api, :github_token)
  @organization Application.get_env(:api, :github_org)
  @github_regex ~r/^(?:https?:\/\/)?(?:www\.)?github\.com\/([^\-][a-z0-9\-]*)(?:\/\w*)?$/i
  @permissions %{permissions: "push"}

  def init do
    Client.new(%{access_token: @github_token})
  end

  def create_repo(id) do
    team = Repo.get!(Team, id)

    case create(team) do
      {:ok, repo} ->
        Teams.update_any_team(id, %{repo: repo})
        add_users_to_repo(id)
      {:error, error} -> {:error, error}
    end
  end

  def add_users_to_repo(id) do
    team = Repo.get!(Team, id)
    members = Repo.all Ecto.assoc(team, :members)

    Enum.each(members, fn(member) ->
      add_collaborator(team.repo, member.github_handle)
    end)

    {:ok, team}
  end

  defp create(team) do
    client = init()

    case Repositories.org_create(@organization, slugify(team.project_name),
      client, [private: false]) do
        {201, repo} -> {:ok, repo}
        {_, error} -> {:error, error["message"]}
    end
  end

  defp add_collaborator(_, username) when is_nil(username), do: :no_username
  defp add_collaborator(repo, username) do
    client = init()

    if is_url?(username) do
      Collaborators.add(@organization, repo["name"],
        username_from_url(username), @permissions, client)
    else
      Collaborators.add(@organization, repo["name"], username, @permissions, client)
    end
  end

  defp username_from_url(url) do
    case Regex.run(@github_regex, url) do
      [_, username] -> username
      nil -> nil
    end
  end

  defp is_url?(url) do
    Regex.match?(@github_regex, url)
  end
end
