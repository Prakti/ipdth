defmodule IpdthWeb.TournamentLive.Signup do
  use IpdthWeb, :live_view

  require Logger

  alias Ipdth.Agents
  alias Ipdth.Tournaments

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:active_page, "tournaments")
     |> assign(:tournament, Tournaments.get_tournament!(id))
     |> stream(:agents, Agents.list_agents_for_signup(current_user.id, id))}
  end

  @impl true
  def handle_event("toggle_signup", %{"agent_id" => agent_id, "value" => "on"}, socket) do
    actor = socket.assigns.current_user
    tournament = socket.assigns.tournament
    agent = Agents.get_agent!(agent_id)

    case Tournaments.sign_up(tournament, agent, actor.id) do
      {:ok, _} ->
        Logger.debug("Agent #{agent.id} signed up for tournament #{tournament.id}")

        {:noreply,
         socket
         |> stream(:agents, Agents.list_agents_for_signup(actor.id, tournament.id))}

      {:error, details} ->
        Logger.warning(details)
        {:noreply, put_flash(socket, :error, "Could not sign up for tournament")}
    end
  end

  @impl true
  def handle_event("toggle_signup", %{"agent_id" => agent_id}, socket) do
    actor = socket.assigns.current_user
    tournament = socket.assigns.tournament
    agent = Agents.get_agent!(agent_id)

    case Tournaments.sign_off(tournament, agent, actor.id) do
      {:ok, _} ->
        Logger.debug("Agent #{agent.id} signed off from tournament #{tournament.id}")

        {:noreply,
         socket
         |> stream(:agents, Agents.list_agents_for_signup(actor.id, tournament.id))}

      {:error, details} ->
        Logger.warning(details)
        {:noreply, put_flash(socket, :error, "Could not sign off from tournament")}
    end
  end
end
