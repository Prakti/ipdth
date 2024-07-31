defmodule IpdthWeb.TournamentLive.ListMatches do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments
  alias Ipdth.Matches

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:active_page, "tournaments")}
  end

  @impl true
  def handle_params(%{"id" => id}, _url, socket) do
    current_user = socket.assigns.current_user
    tournament = Tournaments.get_tournament!(id, current_user.id)

    if tournament == nil do
      {:noreply,
       socket
       |> assign(:page_title, "Matches not Found")
       |> assign(:error, "Tournament not Found")}
    else
      matches = Matches.list_matches_by_tournament(tournament.id)

      {:noreply,
       socket
       |> assign(:page_title, "Showing Matches for Tournament")
       |> assign(:error, nil)
       |> assign(:tournament, tournament)
       |> assign(:matches, matches)
       |> assign(:empty_matches?, Enum.empty?(matches))}
    end
  end
end
