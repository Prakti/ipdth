defmodule IpdthWeb.AgentLive.Index do
  use IpdthWeb, :live_view

  import IpdthWeb.AuthZ

  alias Ipdth.Agents
  alias Ipdth.Agents.Agent

  alias Phoenix.LiveView.Socket

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_page, "agents")
     |> assign(:filter_fields, filter_field_config())
     |> assign(:check_ownership, fn agent ->
       agent_owner?(socket.assigns.current_user, agent)
     end)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Agent")
    |> assign(:agent, Agents.get_agent!(id))
    |> assign(:back_url, build_path(socket))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Agent")
    |> assign(:agent, %Agent{})
    |> assign(:back_url, build_path(socket))
  end

  defp apply_action(socket, :index, params) do
    case Agents.list_agents_with_filter_and_sort(params) do
      {:ok, {agents, meta}} ->
        socket
        |> assign(:page_title, "Listing Agents")
        |> assign(:agent, nil)
        |> assign(:meta, meta)
        |> assign(:back_url, build_path(meta))
        |> stream(:agents, agents, reset: true)

      {:error, _meta} ->
        socket
        |> put_flash(
          :error,
          "Could not Load data with specified filter and sorting. Reverting to Defaults."
        )
        |> apply_action(socket.assigns.live_action, params)
        |> push_patch(to: build_path(socket))
    end
  end

  @impl true
  def handle_info({IpdthWeb.AgentLive.FormComponent, {:saved, agent}}, socket) do
    agent = Agents.load_owner(agent)
    {:noreply, stream_insert(socket, :agents, agent)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    meta = socket.assigns.meta
    filters = Map.values(params["filters"])
    flop? = %Flop{socket.assigns.meta.flop | filters: filters}

    case Flop.validate(flop?) do
      {:ok, flop} ->
        path = build_path(flop, backend: meta.backend, for: meta.schema)
        {:noreply, push_patch(socket, to: path)}

      {:error, meta} ->
        Logger.debug("Cannot filter Agents: #{inspect(meta, pretty: true)}")
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    meta = socket.assigns.meta
    flop = %Flop{socket.assigns.meta.flop | first: size}
    path = build_path(flop, backend: meta.backend, for: meta.schema)
    {:noreply, push_patch(socket, to: path)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user
    {:ok, _} = Agents.delete_agent(agent, user.id)

    {:noreply, push_patch(socket, to: socket.assigns.back_url)}
  end

  @impl true
  def handle_event("activate", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user

    case Agents.activate_agent(agent, user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream(:agents, Agents.list_agents())
         |> put_flash(:info, "Agent #{agent.name} activated")
         |> push_patch(to: build_path(socket))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not activate Agent #{agent.name}")}
    end
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user

    case Agents.deactivate_agent(agent, user.id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> stream(:agents, Agents.list_agents())
         |> put_flash(:info, "Agent #{agent.name} deactivated")
         |> push_patch(to: build_path(socket))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not deactivate Agent #{agent.name}")}
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
          {"active", :active},
          {"inactive", :inactive},
          {"error", :error},
          {"backoff", :testing}
        ]
      ],
      owner_email: [
        op: :ilike_and
      ]
    ]
  end

  defp build_path(meta_or_flop_or_params, opts \\ [])

  defp build_path(%Socket{} = socket, _opts) do
    build_path(Map.get(socket.assigns, :meta, nil))
  end

  # TODO 2024-09-04 - Get rid of magic string
  defp build_path(%Flop.Meta{} = meta, _opts) do
    Flop.Phoenix.build_path(~p"/agents", meta.flop, backend: meta.backend, for: meta.schema)
  end

  defp build_path(%Flop{} = flop, opts) do
    Flop.Phoenix.build_path(~p"/agents", flop, opts)
  end

  defp build_path(params, opts) when is_map(params) do
    Flop.Phoenix.build_path(~p"/agents", params, opts)
  end

  defp build_path(_, _) do
    ~p"/agents"
  end
end
