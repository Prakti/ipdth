defmodule IpdthWeb.Components.PageHeader do
  use IpdthWeb, :live_component

  @moduledoc """
  Renders the page header with navbar and user profile menu.
  Instructs the navbar to highlight the active page.

  TODO: 2024-01-28 - Think about moving this into layouts/app.html.heex
  TODO: 2024-01-28 - Think about making navbar and user profile menu
  responsive
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
              <div class="inline text-[0.8125rem]"><%= @current_user.email %></div>
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="h-6 w-6 inline">
                <path stroke-linecap="round" stroke-linejoin="round" d="M17.982 18.725A7.488 7.488 0 0 0 12 15.75a7.488 7.488 0 0 0-5.982 2.975m11.963 0a9 9 0 1 0-11.963 0m11.963 0A8.966 8.966 0 0 1 12 21a8.966 8.966 0 0 1-5.982-2.275M15 9.75a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
              </svg>
              <:menu_items>
                <.link
                  href={~p"/users/settings"}
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
                >
                  Settings
                </.link>
              </:menu_items>
              <:menu_items>
                <.link
                  href={~p"/users/log_out"}
                  method="delete"
                  class="text-[0.8125rem] leading-6 text-zinc-900 font-semibold hover:text-zinc-700"
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
