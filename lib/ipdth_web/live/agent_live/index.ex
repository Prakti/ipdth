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
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Agent")
    |> assign(:agent, %Agent{})
  end

  defp apply_action(socket, :index, params) do
    case Agents.list_agents_with_filter_and_sort(params) do
      {:ok, {agents, meta}} ->
        socket
        |> assign(:page_title, "Listing Agents")
        |> assign(:agent, nil)
        |> assign(:meta, meta)
        |> assign(:meta_form, Phoenix.Component.to_form(meta))
        |> stream(:agents, agents, reset: true)

      {:error, _meta} ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not Load data specified filters and sorts. Reverting to Defaults."
         )
         |> push_patch(to: ~p"/agents")}
    end
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
  def handle_event("limit", %{"first" => limit}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: limit}
    path = Flop.Phoenix.build_path(~p"/agents", flop)
    {:noreply, push_patch(socket, to: path)}
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
end
