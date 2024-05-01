defmodule IpdthWeb.TournamentLive.Show do
  use IpdthWeb, :live_view

  import IpdthWeb.AuthZ

  alias Ipdth.Tournaments

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, socket
          |> assign(:active_page, "tournaments")
          |> assign(:user_is_tournament_admin, tournament_admin?(current_user))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    current_user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tournament, get_tournament!(id, current_user))}
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

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"

  defp get_tournament!(id, nil), do: Tournaments.get_tournament!(id)
  defp get_tournament!(id, user), do: Tournaments.get_tournament!(id, user.id)
end
