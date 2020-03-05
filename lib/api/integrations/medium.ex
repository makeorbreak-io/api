defmodule Api.Integrations.Medium do
  use ApiWeb, :controller

  def get_latest_posts(count) do
    url = "https://medium.com/@makeorbreak.io/latest?count=#{count}&format=json"

    with {:ok, response} <- HTTPoison.get(url), do: remove_prefix(response) |> Poison.decode!
  end

  defp remove_prefix(response) do
    String.replace_prefix(response.body, "])}while(1);</x>", "")
  end
end
