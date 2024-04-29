defmodule IpdthWeb.TournamentLive.Show do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments
  alias Ipdth.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    {:ok, socket
          |> assign(:active_page, "tournaments")
          |> assign(:user_is_tournament_admin, Accounts.has_role?(current_user.id, :tournament_admin))}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    current_user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:tournament, Tournaments.get_tournament!(id, current_user.id))}
  end

  defp page_title(:show), do: "Show Tournament"
  defp page_title(:edit), do: "Edit Tournament"
end
