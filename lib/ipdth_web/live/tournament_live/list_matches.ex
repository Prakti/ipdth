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
    tournament = Tournaments.get_tournament!(id, current_user.id)

    if tournament == nil do
      {:noreply,
       socket
       |> assign(:page_title, "Matches not Found")
       |> assign(:error, "Tournament not Found")}
    else
      case Matches.list_matches_by_tournament(tournament.id, Map.delete(params, "id")) do
        {:ok, {matches, meta}} ->
          {:noreply,
           socket
           |> assign(:page_title, "Showing Matches for Tournament")
           |> assign(:error, nil)
           |> assign(:tournament, tournament)
           |> assign(:matches, matches)
           |> assign(:meta, meta)
           |> assign(:id, id)
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

    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply,
         push_patch(socket, to: Flop.Phoenix.build_path(~p"/tournaments/#{id}/matches", flop))}

      {:error, meta} ->
        Logger.debug("Could not apply filters: #{inspect(meta)}")
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: size}
    id = socket.assigns.tournament.id

    {:noreply,
     push_patch(socket, to: Flop.Phoenix.build_path(~p"/tournaments/#{id}/matches", flop))}
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
