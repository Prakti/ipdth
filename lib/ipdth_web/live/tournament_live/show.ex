defmodule IpdthWeb.TournamentLive.Show do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :active_page, "tournaments")}
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
