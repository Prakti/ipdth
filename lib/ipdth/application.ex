defmodule Ipdth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      IpdthWeb.Telemetry,
      # Start the Ecto repository
      Ipdth.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Ipdth.PubSub},
      # Start Finch
      {Finch, name: Ipdth.Finch},
      # Start the Endpoint (http/https)
      IpdthWeb.Endpoint,
      # System managing Connections to Agents
      Ipdth.Agents.ConnectionManager,
      # Supervisor for Tasks running the Tournaments
      Ipdth.Tournaments.Runner.supervisor_spec(),
      # The Tournament Manager that starts the Runners
      Ipdth.Tournaments.Manager,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ipdth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IpdthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
