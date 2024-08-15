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
     |> assign(:filter_fields, filter_field_config())
     |> assign(:user_is_tournament_admin, tournament_admin?(current_user))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    current_user = socket.assigns.current_user

    case Tournaments.list_tournaments_with_filter_and_sort(current_user.id, params) do
      {:ok, {tournaments, meta}} ->
        {:noreply,
         socket
         |> assign(:page_title, "Listing Tournaments")
         |> assign(:tournament, nil)
         |> assign(:meta, meta)
         |> stream(:tournaments, tournaments, reset: true)
         |> apply_action(socket.assigns.live_action, params)}

      {:error, _meta} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not Load data with specified filter and sorting. Reverting to Defaults."
         )
         |> apply_action(socket.assigns.live_action, params)
         |> push_patch(to: ~p"/tournaments")}
    end
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

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Tournaments")
    |> assign(:tournament, nil)
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
  def handle_event("filter", params, socket) do
    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/tournaments", flop))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: size}
    {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/tournaments", flop))}
  end

  @impl true
  def handle_info({IpdthWeb.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_info(:tournaments_updated, socket) do
    current_user = socket.assigns.current_user
    flop = socket.assigns.meta.flop

    case Tournaments.list_tournaments_with_filter_and_sort(current_user.id, flop) do
      {:ok, {tournaments, meta}} ->
        {:noreply,
         socket
         |> assign(:meta, meta)
         |> stream(:tournaments, tournaments, reset: true)}

      {:error, _meta} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not Load data with specified filter and sorting. Reverting to Defaults."
         )
         |> push_patch(to: ~p"/tournaments")}
    end
  end

  defp filter_field_config() do
    [
      name: [
        op: :ilike_and
      ],
      description: [
        op: :ilike_and
      ],
      status: [
        type: "select",
        options: [
          {"", nil},
          {"created", :created},
          {"published", :published},
          {"running", :running},
          {"aborted", :aborted},
          {"finished", :aborted}
        ]
      ]
    ]
  end
end
