defmodule IpdthWeb.TournamentLive.ShowMatch do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments
  alias Ipdth.Matches

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_page, "tournaments")
     |> assign(:filter_fields, filter_field_config())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    %{"tournament_id" => tournament_id, "match_id" => match_id} = params

    current_user = socket.assigns.current_user
    tournament = Tournaments.get_tournament!(tournament_id, current_user.id)

    if tournament == nil do
      {:noreply,
       socket
       |> assign(:page_title, "Match not Found")
       |> assign(:error, "Tournament not Found")}
    else
      match = Matches.get_match!(match_id, [:agent_a, :agent_b])
      # TODO: 2024-08-31 - Handle case where get_match! returns nil
      flop_params = Map.drop(params, ["tournament_id", "match_id"])

      case Matches.get_rounds_for_match(match_id, flop_params) do
        {:ok, {rounds, meta}} ->
          {:noreply,
           socket
           |> assign(:page_title, "Showing Matches for Tournament")
           |> assign(:error, nil)
           |> assign(:tournament, tournament)
           |> assign(:match, match)
           |> assign(:rounds, rounds)
           |> assign(:meta, meta)
           |> assign(:empty_rounds?, Enum.empty?(rounds))}

        {:error, meta} ->
          Logger.debug("Could not apply filters: #{inspect(meta)}")

          {:noreply,
           socket
           |> put_flash(
             :error,
             "Could not Load data with specified filter and sorting. Reverting to defaults."
           )
           |> push_patch(to: ~p"/tournaments/#{tournament.id}/matches/#{match_id}")}
      end
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    tournament = socket.assigns.tournament
    match = socket.assigns.match

    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply,
         push_patch(socket,
           to: Flop.Phoenix.build_path(~p"/tournaments/#{tournament}/matches/#{match}", flop)
         )}

      {:error, meta} ->
        Logger.debug("Could not apply filters: #{inspect(meta)}")
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: size}
    tournament = socket.assigns.tournament
    match = socket.assigns.match

    {:noreply,
     push_patch(socket,
       to: Flop.Phoenix.build_path(~p"/tournaments/#{tournament}/matches/#{match}", flop)
     )}
  end

  defp filter_field_config() do
    [
      action_a: [
        type: "select",
        options: [
          {"", nil},
          {"cooperate", :cooperate},
          {"defect", :defect}
        ]
      ],
      action_b: [
        type: "select",
        options: [
          {"", nil},
          {"cooperate", :cooperate},
          {"defect", :defect}
        ]
      ],
      score_a: [],
      score_b: []
    ]
  end
end
