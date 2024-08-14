defmodule IpdthWeb.TournamentLive.Index do
  use IpdthWeb, :live_view

  import IpdthWeb.AuthZ

  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Tournament

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Ipdth.PubSub, "tournaments")
    current_user = socket.assigns.current_user

    {:ok,
     socket
     |> assign(:active_page, "tournaments")
     |> assign(:user_is_tournament_admin, tournament_admin?(current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    current_user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Tournament")
    |> assign(:tournament, Tournaments.get_tournament!(id, current_user.id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tournament")
    |> assign(:tournament, %Tournament{})
  end

  defp apply_action(socket, :index, params) do
    current_user = socket.assigns.current_user

    case Tournaments.list_tournaments_with_filter_and_sort(current_user.id, %{order_by: [:name]}) do
      {:ok, {tournaments, meta}} ->
        socket
        |> assign(:page_title, "Listing Tournaments")
        |> assign(:tournament, nil)
        |> assign(:meta, meta)
        |> assign(:meta_form, Phoenix.Component.to_form(meta))
        |> stream(:tournaments, tournaments, reset: true)

      {:error, meta} ->
        socket
        |> put_flash(
          :error,
          "Could not Load data with specified filter and sorting. Reverting to Defaults."
        )
        |> push_patch(to: ~p"/tournaments")
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    tournament = Tournaments.get_tournament!(id, current_user.id)

    if current_user do
      {:ok, _} = Tournaments.delete_tournament(tournament, current_user.id)
      {:noreply, stream_delete(socket, :tournaments, tournament)}
    else
      # TODO 2024-04-28 -- Show error flash about missing permission
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({IpdthWeb.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_info(:tournaments_updated, socket) do
    current_user = socket.assigns.current_user

    {:noreply,
     socket
     |> stream(:tournaments, list_tournaments(current_user))}
  end

  defp list_tournaments(nil) do
    Tournaments.list_tournaments()
  end

  defp list_tournaments(user) do
    Tournaments.list_tournaments(user.id)
  end
end
