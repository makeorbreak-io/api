use Mix.Config

# Configure your database
config :api, Api.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.Postgres,
  url: "#{System.get_env("DB_URL")}-test"

config :api,
  slack_token: "DUMMY-TOKEN",
  http_lib: FakeHTTPoison,
  github_token: "DUMMY-TOKEN"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :api, ApiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Bamboo configuration
config :api, Api.Mailer,
  adapter: Bamboo.TestAdapter