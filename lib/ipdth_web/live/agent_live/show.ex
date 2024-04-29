defmodule IpdthWeb.AgentLive.Show do
  use IpdthWeb, :live_view

  alias Ipdth.Agents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket
          |> assign(:active_page, "agents")
          |> assign(:check_ownership, fn agent ->
            current_user = socket.assigns.current_user
            current_user && agent.owner_id == current_user.id
          end)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:agent, Agents.get_agent!(id, [:owner]))}
  end

  defp page_title(:show), do: "Show Agent"
  defp page_title(:edit), do: "Edit Agent"
end
