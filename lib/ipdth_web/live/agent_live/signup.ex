defmodule IpdthWeb.AgentLive.Signup do
  use IpdthWeb, :live_view

  require Logger

  import IpdthWeb.AuthZ

  alias Ipdth.Tournaments
  alias Ipdth.Agents

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
      socket
      |> assign(:active_page, "agents")
      |> assign(:agent, Agents.get_agent!(id, [:owner]))
      |> stream(:tournaments, Tournaments.list_tournaments_for_signup(id))
      |> assign(:check_ownership, fn agent ->
        agent_owner?(socket.assigns.current_user, agent)
      end)}
  end

  @impl true
  def handle_event("toggle_signup", %{"tournament_id" => tournament_id, "value" => "on"}, socket) do
    actor = socket.assigns.current_user
    agent = socket.assigns.agent
    tournament = Tournaments.get_tournament!(tournament_id)

    case Tournaments.sign_up(tournament, agent, actor.id) do
      {:ok, _} ->
        Logger.debug("Agent #{agent.id} signed up for tournament #{tournament_id}")
        {:noreply,
          socket
          |> stream(:tournaments, Tournaments.list_tournaments_for_signup(agent.id))}
      {:error, details} ->
        Logger.warning(details)
        {:noreply, put_flash(socket, :error, "Could not sign up for tournament")}
    end
  end

  @impl true
  def handle_event("toggle_signup", %{"tournament_id" => tournament_id}, socket) do
    agent = socket.assigns.agent
    actor = socket.assigns.current_user
    tournament = Tournaments.get_tournament!(tournament_id)

    case Tournaments.sign_off(tournament, agent, actor.id) do
      {:ok, _} ->
        Logger.debug("Agent #{agent.id} signed off from tournament #{tournament.id}")
        {:noreply,
          socket
          |> stream(:tournaments, Tournaments.list_tournaments_for_signup(agent.id))}
      {:error, details} ->
        Logger.warning(details)
        {:noreply, put_flash(socket, :error, "Could not sign off from tournament")}
    end
  end
end
