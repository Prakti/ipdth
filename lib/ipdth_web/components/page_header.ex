defmodule IpdthWeb.Components.PageHeader do
  use IpdthWeb, :live_component

  @moduledoc """
  Renders the page header with navbar and user profile menu.
  Instructs the navbar to highlight the active page.

  TODO: 2024-01-28 - Think about moving this into layouts/app.html.heex
  TODO: 2024-01-28 - Think about making navbar and user profile menu responsive

  ## Examples
      <.live_component module={IpdthWeb.Components.PageHeader} id="page_header" active_page="tournaments" />
  """

  def render(assigns) do
    ~H"""
      <header class="header py-02 sticky top-0 flex items-center justify-between bg-white px-8 shadow-md border-b border-color-zinc-400">
        <!-- logo -->
        <h1 class="w-3/12 text-xl font-semibold">
          <a href="">IPDTH</a>
        </h1>

        <!-- navigation -->
        <.navbar active_page={@active_page}>
          <:nav_item id="dashboard" route={~p"/"}>Dashboard</:nav_item>
          <:nav_item id="tournaments" route={~p"/tournaments"}>Tournaments</:nav_item>
          <:nav_item id="agents" route={~p"/agents"}>Agents</:nav_item>
          <:nav_item id="members" route={""}>Members</:nav_item>
        </.navbar>

        <!-- user profile & menu or login & register functionality -->
        <div class="flex w-3/12 justify-end">
          <%= if @current_user do %>
            <.dropdown_menu id="user_menu">
              <div class="inline text-[0.850rem]"><%= @current_user.email %></div>
                <.icon name="hero-user-circle" class="h-8 w-8"/>
              <:menu_items>
                <.link
                  href={~p"/users/settings"}
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold"
                >
                  Settings
                </.link>
              </:menu_items>
              <:menu_items>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold"
                >
                  Log out
                </.link>
              </:menu_items>
            </.dropdown_menu>
          <% else %>
            <ul class="relative flex items-center gap-4 px-4 sm:px-6 lg:px-8 justify-end">
              <li :if={@active_page != "register"}>
                <.link
                  href={~p"/users/register"}
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
                >
                  Register
                </.link>
              </li>
              <li :if={@active_page != "log_in"}>
                <.link
                  href={~p"/users/log_in"}
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
                >
                  Log in
                </.link>
              </li>
            </ul>
          <% end %>
        </div>
      </header>
    """
  end
end
