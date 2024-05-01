defmodule IpdthWeb.TournamentLive.FormComponent do
  use IpdthWeb, :live_component

  alias Ipdth.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>(<%= @id %>)</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="tournament-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:start_date]} type="datetime-local" label="Start date" />
        <.input field={@form[:round_number]} type="number" label="Round number" />
        <.input field={@form[:random_seed]} type="text" label="Random seed" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Tournament</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{tournament: tournament} = assigns, socket) do
    changeset = Tournaments.change_tournament(tournament)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"tournament" => tournament_params}, socket) do
    changeset =
      socket.assigns.tournament
      |> Tournaments.change_tournament(tournament_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"tournament" => tournament_params}, socket) do
    save_tournament(socket, socket.assigns.action, tournament_params)
  end

  defp save_tournament(socket, :edit, tournament_params) do
    user = socket.assigns.current_user
    case Tournaments.update_tournament(socket.assigns.tournament, tournament_params, user.id) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        {:noreply,
         socket
         |> put_flash(:info, "Tournament updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_tournament(socket, :new, tournament_params) do
    user = socket.assigns.current_user
    case Tournaments.create_tournament(tournament_params, user.id) do
      {:ok, tournament} ->
        notify_parent({:saved, tournament})

        {:noreply,
         socket
         |> put_flash(:info, "Tournament created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
