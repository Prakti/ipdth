defmodule IpdthWeb.ParticipationLive.Index do
  use IpdthWeb, :live_view

  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Participation

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:active_page, "participations")
      |> stream(:participations, Tournaments.list_participations())

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Participation")
    |> assign(:participation, Tournaments.get_participation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Participation")
    |> assign(:participation, %Participation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Participations")
    |> assign(:participation, nil)
  end

  @impl true
  def handle_info({IpdthWeb.ParticipationLive.FormComponent, {:saved, participation}}, socket) do
    {:noreply, stream_insert(socket, :participations, participation)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    participation = Tournaments.get_participation!(id)
    {:ok, _} = Tournaments.delete_participation(participation)

    {:noreply, stream_delete(socket, :participations, participation)}
  end
end
