defmodule IpdthWeb.TournamentLive.Index do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Tournament

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_page, "tournaments")
     |> stream(:tournaments, Tournaments.list_tournaments())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Tournament")
    |> assign(:tournament, Tournaments.get_tournament!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tournament")
    |> assign(:tournament, %Tournament{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tournaments")
    |> assign(:tournament, nil)
  end

  @impl true
  def handle_info({IpdthWeb.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    tournament = Tournaments.get_tournament!(id)
    {:ok, _} = Tournaments.delete_tournament(tournament)

    {:noreply, stream_delete(socket, :tournaments, tournament)}
  end
end
