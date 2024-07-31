defmodule IpdthWeb.TournamentLive.ShowMatch do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments
  alias Ipdth.Matches

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:active_page, "tournaments")}
  end

  @impl true
  def handle_params(%{"tournament_id" => tournament_id, "match_id" => match_id}, _url, socket) do
    current_user = socket.assigns.current_user
    tournament = Tournaments.get_tournament!(tournament_id, current_user.id)

    if tournament == nil do
      {:noreply,
       socket
       |> assign(:page_title, "Match not Found")
       |> assign(:error, "Tournament not Found")}
    else
      match = Matches.get_match!(match_id, [:agent_a, :agent_b])
      rounds = Matches.get_rounds_for_match(match_id)

      {:noreply,
       socket
       |> assign(:page_title, "Showing Matches for Tournament")
       |> assign(:error, nil)
       |> assign(:tournament, tournament)
       |> assign(:match, match)
       |> assign(:rounds, rounds)
       |> assign(:empty_rounds?, Enum.empty?(rounds))}
    end
  end
end
