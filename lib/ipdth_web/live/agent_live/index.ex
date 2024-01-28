defmodule IpdthWeb.AgentLive.Index do
  use IpdthWeb, :live_view

  alias Ipdth.Agents
  alias Ipdth.Agents.Agent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
      socket
      |> assign(:active_page, "agents")
      |> stream(:agents, Agents.list_agents())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Agents")
    |> assign(:agent, nil)
  end

  # TODO: 2024-01-28 - receive notification and reload agent list

end
