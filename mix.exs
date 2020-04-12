defmodule Api.MixProject do
  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Api.Application, []},
      applications: [
        :bamboo,
        :cors_plug,
        :cowboy,
        :elixir_make,
        :guardian,
        :httpoison,
        :logger,
        :markus,
        :phoenix,
        :phoenix_ecto,
        :phoenix_html,
        :postgrex,
        :runtime_tools,
        :tentacat,
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.4.0"},
      {:absinthe_ecto, "~> 0.1.3"},
      {:absinthe_plug, "~> 1.4.0"},
      {:absinthe_relay, "~> 1.4.0"},
      {:argon2_elixir, "~> 2.3"},
      {:bamboo, "~> 1.4"},
      {:cors_plug, "~> 2.0"},
      {:ecto_sql, "~> 3.1"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.0"},
      {:guardian_phoenix, "~> 2.0"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.0"},
      {:markus, "~> 0.3.0"},
      {:phoenix, "~> 1.4.14"},
      {:phoenix_ecto, "~> 4.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:premailex, "~> 0.3.0"},
      {:plug_cowboy, "~> 2.0"},
      {:plug, "~> 1.7"},
      {:poison, "~> 2.1.0"},
      {:postgrex, ">= 0.0.0"},
      {:tentacat, "~> 1.0"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
