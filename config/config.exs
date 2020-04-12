# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :api,
  ecto_repos: [Api.Repo],
  generators: [binary_id: true],
  # Use this tutorial to get a Slack token with client privileges
  # https://medium.com/@andrewarrow/how-to-get-slack-api-tokens-with-client-scope-e311856ebe9
  slack_token: System.get_env("SLACK_TOKEN"),
  # Maximum number of users each team is allowed to have
  team_user_limit: 4,
  # Library used to make external HTTP requests
  http_lib: HTTPoison,
  # Github API data
  github_token: System.get_env("GITHUB_TOKEN"),
  github_org: "makeorbreak-io"

# Configures the endpoint
config :api, ApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: System.get_env("SECRET_KEY_BASE"),
  render_errors: [view: ApiWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Api.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "2QpPQxUe"]

# Configures Guardian for authentication
config :api, ApiWeb.Guardian,
  issuer: "Api",
  secret_key: System.get_env("SECRET_KEY_BASE")

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Bamboo configuration
config :api, Api.Mailer,
  adapter: Bamboo.LocalAdapter

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
