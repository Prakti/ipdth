defmodule IpdthWeb.TournamentLive.ListMatches do
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
  def handle_params(%{"id" => id} = params, _url, socket) do
    current_user = socket.assigns.current_user

    tournament =
      case current_user do
        nil -> Tournaments.get_tournament!(id)
        _ -> Tournaments.get_tournament!(id, current_user.id)
      end

    if tournament == nil do
      {:noreply,
       socket
       |> assign(:page_title, "Matches not Found")
       |> assign(:error, "Tournament not Found")}
    else
      case Matches.list_matches_by_tournament(tournament.id, Map.delete(params, "id")) do
        {:ok, {matches, meta}} ->
          Logger.debug("Applied Filters: #{inspect(meta.flop.filters)}")

          {:noreply,
           socket
           |> assign(:page_title, "Showing Matches for Tournament")
           |> assign(:error, nil)
           |> assign(:tournament, tournament)
           |> assign(:matches, matches)
           |> assign(:meta, meta)
           |> assign(:id, id)
           |> assign(:empty_filters?, IpdthWeb.Utils.empty_filters?(meta.flop))
           |> assign(:empty_matches?, Enum.empty?(matches))}

        {:error, meta} ->
          Logger.debug("Could not apply filters: #{inspect(meta)}")

          {:noreply,
           socket
           |> put_flash(
             :error,
             "Could not Load data with specified filter and sorting. Reverting to defaults."
           )
           |> push_patch(to: ~p"/tournaments/#{id}/matches")}
      end
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    id = socket.assigns.tournament.id
    meta = socket.assigns.meta
    filters = Map.values(params["filters"])
    maybe_flop = %Flop{meta.flop | filters: filters}

    case Flop.validate(maybe_flop) do
      {:ok, flop} ->
        base_path = ~p"/tournaments/#{id}/matches"
        path = IpdthWeb.Utils.build_path(base_path, flop, backend: meta.backend, for: meta.schema)
        {:noreply, push_patch(socket, to: path)}

      {:error, meta} ->
        Logger.debug("Could not apply filters: #{inspect(meta)}")
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    id = socket.assigns.tournament.id
    base_path = ~p"/tournaments/#{id}/matches"
    path = IpdthWeb.Utils.page_size_to_path(base_path, socket.assigns.meta, size)

    {:noreply, push_patch(socket, to: path)}
  end

  defp filter_field_config() do
    [
      agent_name: [
        op: :ilike_and
      ],
      agent_a_name: [
        op: :ilike_and
      ],
      agent_b_name: [
        op: :ilike_and
      ]
    ]
  end
end
