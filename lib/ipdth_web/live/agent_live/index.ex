defmodule IpdthWeb.AgentLive.Index do
  use IpdthWeb, :live_view

  import IpdthWeb.AuthZ

  alias Ipdth.Agents
  alias Ipdth.Agents.Agent

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
    case Agents.list_agents_with_filter_and_sort(params) do
      {:ok, {agents, meta}} ->
        {:noreply,
         socket
         |> assign(:meta, meta)
         |> stream(:agents, agents, reset: true)
         |> apply_action(socket.assigns.live_action, params)}

      {:error, _meta} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not Load data with specified filter and sorting. Reverting to Defaults."
         )
         |> apply_action(socket.assigns.live_action, params)
         |> push_patch(to: ~p"/agents")}
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Agent")
    |> assign(:agent, Agents.get_agent!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Agent")
    |> assign(:agent, %Agent{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Agents")
    |> assign(:agent, nil)
  end

  @impl true
  def handle_info({IpdthWeb.AgentLive.FormComponent, {:saved, agent}}, socket) do
    agent = Agents.load_owner(agent)
    {:noreply, stream_insert(socket, :agents, agent)}
  end

  @impl true
  def handle_event("filter", params, socket) do
    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/agents", flop))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: size}
    {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/agents", flop))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    agent = Agents.get_agent!(id)
    user = socket.assigns.current_user
    {:ok, _} = Agents.delete_agent(agent, user.id)

    {:noreply, stream_delete(socket, :agents, agent)}
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
         |> push_patch(to: ~p"/agents")}

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
         |> push_patch(to: ~p"/agents")}

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
end
