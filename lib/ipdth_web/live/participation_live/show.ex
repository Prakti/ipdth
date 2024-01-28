defmodule IpdthWeb.ParticipationLive.Show do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_page: "participations")}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:participation, Tournaments.get_participation!(id))}
  end

  defp page_title(:show), do: "Show Participation"
  defp page_title(:edit), do: "Edit Participation"
end
