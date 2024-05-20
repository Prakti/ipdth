defmodule IpdthWeb.AgentLive.Show do
  use IpdthWeb, :live_view

  import IpdthWeb.AuthZ

  alias Ipdth.Agents
  alias Ipdth.Tournaments

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_page, "agents")
     |> assign(:check_ownership, fn agent ->
       agent_owner?(socket.assigns.current_user, agent)
     end)}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    tournaments = Tournaments.list_signed_up_tournaments_by_agent(id)

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:signed_up_for_tournaments?, not Enum.empty?(tournaments))
     |> stream(:tournaments, tournaments)
     |> assign(:agent, Agents.get_agent!(id, [:owner]))}
  end

  defp page_title(:show), do: "Show Agent"
  defp page_title(:edit), do: "Edit Agent"
  defp page_title(:signup), do: "Sign-Up Agent"
end
