defmodule IpdthWeb.ParticipationLive.FormComponent do
  use IpdthWeb, :live_component

  alias Ipdth.Tournaments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage participation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="participation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:score]} type="number" label="Score" />
        <.input field={@form[:ranking]} type="number" label="Ranking" />
        <.input field={@form[:sign_up]} type="text" label="Sign up" />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          prompt="Choose a value"
          options={Ecto.Enum.values(Ipdth.Tournaments.Participation, :status)}
        />
        <.input field={@form[:details]} type="text" label="Details" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Participation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{participation: participation} = assigns, socket) do
    changeset = Tournaments.change_participation(participation)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"participation" => participation_params}, socket) do
    changeset =
      socket.assigns.participation
      |> Tournaments.change_participation(participation_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"participation" => participation_params}, socket) do
    save_participation(socket, socket.assigns.action, participation_params)
  end

  defp save_participation(socket, :edit, participation_params) do
    case Tournaments.update_participation(socket.assigns.participation, participation_params) do
      {:ok, participation} ->
        notify_parent({:saved, participation})

        {:noreply,
         socket
         |> put_flash(:info, "Participation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_participation(socket, :new, participation_params) do
    case Tournaments.create_participation(participation_params) do
      {:ok, participation} ->
        notify_parent({:saved, participation})

        {:noreply,
         socket
         |> put_flash(:info, "Participation created successfully")
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
