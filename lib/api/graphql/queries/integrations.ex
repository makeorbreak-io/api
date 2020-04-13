defmodule Api.GraphQL.Queries.Integrations do
  use Absinthe.Schema.Notation

  alias Api.Integrations.Medium

  object :integrations_queries do
    field :medium, :medium do
      resolve fn _args, _info ->
        json = Medium.get_latest_posts(2)
        {:ok, %{posts:
          json
          |> Map.get("payload")
          |> Map.get("references")
          |> Map.get("Post")
          |> Map.values
        }}
      end
    end
  end
end
