import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :ipdth, Ipdth.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "ipdth_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ipdth, IpdthWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "LkqEIVafXEcCwf7oYxT60zrSny4NexF/t5lczehv092l5eH+HfSvLRhYy3l4BZLR",
  server: false

# In test we don't send emails.
config :ipdth, Ipdth.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :ipdth,
       Ipdth.Agents.ConnectionManager,
       backoff_duration: 1_000,
       max_retries: 2

# Shorten connection timeouts for faster tests
config :ipdth,
       Ipdth.Agents.Connection,
       connect_options: [timeout: 6_000],
       pool_timeout: 1_000,
       receive_timeout: 3_000

# Dependency injection config for the Tournaments Manager
# Needs to be overidden for testing purposes
config :ipdth,
       Ipdth.Tournaments.Manager,
       auto_mode: false,
       get_tournaments: fn _timestamp -> [] end,
       start_tournament: fn _tournament -> {:ok, nil} end,
       check_interval: 1_000
