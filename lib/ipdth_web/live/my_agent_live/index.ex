defmodule IpdthWeb.MyAgentLive.Index do
  use IpdthWeb, :live_view

  alias Ipdth.Accounts.User
  alias Ipdth.Agents
  alias Ipdth.Agents.Agent

  @impl true
  def mount(_params, _session, socket) do
    # TODO: 2024-01-21 - Detect logged-in user and query for his agents
    {:ok, stream(socket, :agents, Agents.list_agents())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    # TODO: 2024-01-21 - Check if User is allowed to edit agent!
    socket
    |> assign(:page_title, "Edit Agent")
    |> assign(:agent, Agents.get_agent!(id))
  end

  defp apply_action(socket, :new, _params) do
    # TODO: 2024-01-21 - Prefill user into Agent
    socket
    |> assign(:page_title, "New Agent")
    |> assign(:agent, %Agent{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Agents")
    |> assign(:agent, nil)
  end

  @impl true
  def handle_info({IpdthWeb.MyAgentLive.FormComponent, {:saved, agent}}, socket) do
    {:noreply, stream_insert(socket, :agents, agent)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    {:ok, _} = Agents.delete_agent(agent)

    {:noreply, stream_delete(socket, :agents, agent)}
  end
end
