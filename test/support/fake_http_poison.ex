defmodule FakeHTTPoison do
  def post(url, _, _) do
    uri = URI.parse(url)

    [{"email", email} | _] = URI.query_decoder(uri.query) |> Enum.to_list()

    case email do
      "valid@example.com" -> { :ok, successful_response() }
      "error@example.com" -> { :ok, error_response() }
    end
  end

  defp successful_response do
    %HTTPoison.Response{
      headers: [{"Content-Type", "application/json"}],
      status_code: 200,
      body: "{\"ok\": true}"
    }
  end

  defp error_response do
    %HTTPoison.Response{
      headers: [{"Content-Type", "application/json"}],
      status_code: 500,
      body: "{\"ok\": false, \"error\": \"already_in_team\"}"
    }
  end
end
