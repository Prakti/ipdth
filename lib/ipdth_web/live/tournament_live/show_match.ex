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

    tournament =
      case current_user do
        nil -> Tournaments.get_tournament!(tournament_id)
        _ -> Tournaments.get_tournament!(tournament_id, current_user.id)
      end

    if tournament == nil do
      {:noreply,
       socket
       |> assign(:page_title, "Match not Found")
       |> assign(:error, "Tournament not Found")}
    else
      match = Matches.get_match!(match_id, [:agent_a, :agent_b])
      # TODO: 2024-08-31 - Handle case where get_match! returns nil
      # TODO: 2024-11-13 - Handle case where get_match! returns a match for a different tournament
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
           |> assign(:empty_filters?, IpdthWeb.Utils.empty_filters?(meta.flop))
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
    meta = socket.assigns.meta
    filters = Map.values(params["filters"])
    maybe_flop = %Flop{meta.flop | filters: filters}

    case Flop.validate(maybe_flop) do
      {:ok, flop} ->
        base_path = ~p"/tournaments/#{tournament}/matches/#{match}"
        path = IpdthWeb.Utils.build_path(base_path, flop, backend: meta.backend, for: meta.schema)
        {:noreply, push_patch(socket, to: path)}

      {:error, meta} ->
        Logger.debug("Could not apply filters: #{inspect(meta)}")
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    tournament = socket.assigns.tournament
    match = socket.assigns.match
    base_path = ~p"/tournaments/#{tournament}/matches/#{match}"
    path = IpdthWeb.Utils.page_size_to_path(base_path, socket.assigns.meta, size)

    {:noreply, push_patch(socket, to: path)}
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
