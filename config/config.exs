# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ipdth,
  ecto_repos: [Ipdth.Repo]

# make the current environment accessible
config :ipdth, :environment, config_env()

# Configures the endpoint
config :ipdth, IpdthWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: IpdthWeb.ErrorHTML, json: IpdthWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Ipdth.PubSub,
  live_view: [signing_salt: "u3DgBWm9"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :ipdth, Ipdth.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Ecto Repo to use UTC Timestamps wherever possible
config :ipdth,
       Ipdth.Repo,
       migration_timestamps: [type: :utc_datetime_usec]

# Options for the ConnectionManager
config :ipdth,
       Ipdth.Agents.ConnectionManager,
       backoff_duration: 5_000,
       max_retries: 3

# Options for the connections to an agent
config :ipdth,
       Ipdth.Agents.Connection,
       connect_options: [timeout: 30_000],
       pool_timeout: 5_000,
       receive_timeout: 15_000

# Dependency injection config for the Tournaments Manager
# Needs to be overidden for testing purposes
config :ipdth,
       Ipdth.Tournaments.Manager,
       auto_mode: true,
       get_tournaments: &Ipdth.Tournaments.list_due_and_overdue_tournaments/1,
       start_tournament: &Ipdth.Tournaments.Runner.start/1,
       check_interval: 1_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
