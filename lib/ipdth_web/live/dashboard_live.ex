defmodule IpdthWeb.DashboardLive do
  use IpdthWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :active_page, "dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <%= if @current_user do %>
        <h2>This is the user dashboard for <%= @current_user.email %></h2>
        <ul>
          <li>TODO: 2024-01-28 - Render Card Lists for Agents and upcoming Tournaments </li>
          <li>TODO: 2024-01-28 - Render Buttons to add an agent or register an agent to a tournament </li>
          <li>TODO: 2024-01-28 - Render Table with results of last tournaments </li>
        </ul>
      <% else %>
        <h2>This is the user dashboard for unauthenticated users.</h2>
        <ul>
          <li>TODO: 2024-01-28 - Render Card Lists for Agents and upcoming Tournaments </li>
          <li>TODO: 2024-01-28 - Render Buttons to add an agent or register an agent to a tournament </li>
          <li>TODO: 2024-01-28 - Render Table with results of last tournaments </li>
        </ul>
      <% end %>
    """
  end
end
