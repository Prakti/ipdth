defmodule IpdthWeb.TournamentLive.Show do
  use IpdthWeb, :live_view

  import IpdthWeb.AuthZ

  require Logger

  alias Ipdth.Tournaments
  alias Ipdth.Agents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:active_page, "tournaments")}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _, socket) do
    Phoenix.PubSub.subscribe(Ipdth.PubSub, "tournament:#{id}")
    load_data_into_socket(id, socket, Map.delete(params, "id"))
  end

  @impl true
  def handle_event("publish", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    tournament = Tournaments.get_tournament!(id, current_user.id)

    if current_user do
      {:ok, tournament} = Tournaments.publish_tournament(tournament, current_user.id)
      {:noreply, assign(socket, :tournament, tournament)}
    else
      # TODO 2024-04-28 -- Show error flash about missing permission
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("filter", params, socket) do
    id = socket.assigns.id

    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/tournaments/#{id}", flop))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: size}
    id = socket.assigns.id
    {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/tournaments/#{id}", flop))}
  end

  @impl true
  def handle_info({:tournament_updated, id}, socket) do
    meta = Map.get(socket.assigns, :meta, %{flop: %{}})
    load_data_into_socket(id, socket, meta.flop)
  end

  @impl true
  def handle_info({IpdthWeb.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    meta = Map.get(socket.assigns, :meta, %{flop: %{}})
    load_data_into_socket(tournament.id, socket, meta.flop)
  end

  defp load_data_into_socket(id, socket, map_or_flop) do
    current_user = socket.assigns.current_user
    tournament = get_tournament!(id, current_user)

    if Enum.member?([:finished, :running], tournament.status) do
      case Tournaments.list_ranking_for_tournament(id, map_or_flop) do
        {:ok, {ranking, meta}} ->
          {:noreply,
           socket
           |> assign(:page_title, page_title(socket.assigns.live_action))
           |> assign(:tournament, tournament)
           |> assign(:meta, meta)
           |> assign(:id, id)
           |> assign(:user_is_tournament_admin, tournament_admin?(current_user))
           |> assign(:show_ranking?, true)
           |> assign(:empty_agents?, true)
           |> assign(:ranking, ranking)}

        {:error, meta} ->
          Logger.debug("Could not apply filters: #{inspect(meta)}")

          {:noreply,
           socket
           |> put_flash(
             :error,
             "Could not Load data with specified filter and sorting. Reverting to defaults."
           )
           |> push_patch(to: ~p"/tournaments/#{id}")}
      end
    else
      agents = Agents.list_agents_by_tournament(id)

      {:noreply,
       socket
       |> assign(:page_title, page_title(socket.assigns.live_action))
       |> assign(:tournament, tournament)
       |> assign(:user_is_tournament_admin, tournament_admin?(current_user))
       |> assign(:show_ranking?, false)
       |> assign(:empty_agents?, Enum.empty?(agents))
       |> stream(:agents, agents)}
    end
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  defp get_tournament!(id, nil), do: Tournaments.get_tournament!(id)
  defp get_tournament!(id, user), do: Tournaments.get_tournament!(id, user.id)
end
