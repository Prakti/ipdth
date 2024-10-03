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
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    current_user = socket.assigns.current_user

    socket
    |> assign(:page_title, "Edit Tournament")
    |> assign(:tournament, Tournaments.get_tournament!(id, current_user.id))
    |> assign(:back_url, build_path(socket))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Tournament")
    |> assign(:tournament, %Tournament{})
    |> assign(:back_url, build_path(socket))
  end

  defp apply_action(socket, :index, params) do
    current_user = socket.assigns.current_user

    case list_tournaments(current_user, params) do
      {:ok, {tournaments, meta}} ->
        socket
        |> assign(:page_title, "Listing Tournaments")
        |> assign(:tournament, nil)
        |> assign(:meta, meta)
        |> assign(:back_url, build_path(meta))
        |> stream(:tournaments, tournaments, reset: true)

      {:error, _meta} ->
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
  def handle_event("filter", params, socket) do
    meta = socket.assigns.meta

    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply,
         push_patch(socket, to: build_path(flop, backend: meta.backend, for: meta.schema))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    meta = socket.assigns.meta
    flop = %Flop{meta.flop | first: size}
    path = build_path(flop, backend: meta.backend, for: meta.schema)
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_info({IpdthWeb.TournamentLive.FormComponent, {:saved, tournament}}, socket) do
    {:noreply, stream_insert(socket, :tournaments, tournament)}
  end

  @impl true
  def handle_info(:tournaments_updated, socket) do
    current_user = socket.assigns.current_user
    flop = socket.assigns.meta.flop

    case list_tournaments(current_user, flop) do
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

  defp list_tournaments(nil, flop) do
    Tournaments.list_tournaments_with_filter_and_sort(nil, flop)
  end

  defp list_tournaments(user, flop) do
    Tournaments.list_tournaments_with_filter_and_sort(user.id, flop)
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
          {"finished", :finished}
        ]
      ]
    ]
  end

  defp build_path(socket_or_meta_or_flop_or_params, opts \\ []) do
    IpdthWeb.Utils.build_path(~p"/tournaments", socket_or_meta_or_flop_or_params, opts)
  end
end
