use Mix.Config

config :logger, level: :warn

config :ex_zample, ExZample.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  database: System.get_env("POSTGRES_DB") || "example_test",
  hostname: System.get_env("POSTGRES_HOSTNAME") || "localhost",
  pool_size: 10,
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "test/priv/repo"

config :ex_zample, ecto_repos: [ExZample.Repo]
