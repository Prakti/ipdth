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
     |> assign(:agent, Agents.get_agent_with_connection_errors!(id))}
  end

  @impl true
  def handle_event("activate", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user

    case Agents.activate_agent(agent, user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Agent #{agent.name} activated")
         |> push_patch(to: ~p"/agents/#{agent.id}")}

      {:error, _} ->
        {:noreply,
         socket
         |> assign(:agent, Agents.get_agent_with_connection_errors!(id))
         |> push_patch(to: ~p"/agents/#{agent.id}")}
    end
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user

    case Agents.deactivate_agent(agent, user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Agent #{agent.name} deactivated")
         |> assign(:agent, Agents.get_agent_with_connection_errors!(id))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not deactivate Agent #{agent.name}")
         |> push_patch(to: ~p"/agents/#{agent.id}")}
    end
  end

  @impl true
  def handle_event("clear_errors", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user

    case Agents.clear_connection_errors(agent, user.id) do
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Could not clear connection errors for #{agent.name}")
         |> push_patch(to: ~p"/agents/#{agent.id}")}

      {_count, _errors} ->
        {:noreply,
         socket
         |> put_flash(:info, "Cleared connection errors for #{agent.name}")
         |> push_patch(to: ~p"/agents/#{agent.id}")}
    end
  end

  defp page_title(:show), do: "Show Agent"
  defp page_title(:edit), do: "Edit Agent"
  defp page_title(:signup), do: "Sign-Up Agent"
end
