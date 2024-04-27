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
      <div class="p-5 grid grid-cols-4 gap-4">
        <.badge color="gray"> Gray </.badge>
        <.badge color="zinc"> Zinc </.badge>
        <.badge color="neutral"> Neutral </.badge>
        <.badge color="stone"> Stone </.badge>
        <.badge color="red"> Red </.badge>
        <.badge color="orange"> Orange </.badge>
        <.badge color="amber"> Amber </.badge>
        <.badge color="yellow"> Yellow </.badge>
        <.badge color="lime"> Lime </.badge>
        <.badge color="green"> Green </.badge>
        <.badge color="emerald"> Emerald </.badge>
        <.badge color="teal"> Teal </.badge>
        <.badge color="cyan"> Cyan </.badge>
        <.badge color="sky"> Sky </.badge>
        <.badge color="blue"> Blue </.badge>
        <.badge color="indigo"> Indigo </.badge>
        <.badge color="violet"> Violet </.badge>
        <.badge color="purple"> Purple </.badge>
        <.badge color="fuchsia"> Fuchsia </.badge>
        <.badge color="pink"> Pink </.badge>
        <.badge color="rose"> Rose </.badge>
      </div>
      <h2>This is the user dashboard for <%= @current_user.email %></h2>
      <div class="p-5 grid grid-cols-2 gap-4">
        <div class="relative rounded ring-1 ring-zinc-300 border-b-2 border-zinc-300 shadow-md p-2">
          <h1 class="text-xl">tit-for-tat</h1>
          <h2 class="text-sm absolute top-1 right-1 text-zinc-400 ">#23</h2>
          <p class="mb-8 mt-4">
            this is a description lorem ipsum dolor sit amet blah foo blah 1 2 3 4 5
          </p>

          <div class="absolute bottom-2 right-2 bg-green-200 rounded-full px-2.5 py-1.5 text-xs font-bold text-green-700 leading-none ring-1 ring-inset ring-green-500/40">
            Active
          </div>
        </div>
        <div class="relative rounded ring-1 ring-zinc-300 border-b-2 border-zinc-300 shadow-md p-2">
          <h1 class="text-xl">tit-for-tat</h1>
          <h2 class="text-sm absolute top-1 right-1 text-zinc-400 ">#23</h2>
          <p class="mb-8 mt-4">
            this is a description lorem ipsum dolor sit amet blah foo blah 1 2 3 4 5
          </p>

          <div class="absolute bottom-2 right-2 bg-green-200 rounded-full px-2 py-1 text-xs font-bold text-green-700 leading-none ring-1 ring-inset ring-green-600/40">
            active
          </div>
        </div>

        <div class="relative rounded ring-1 ring-zinc-300 border-b-2 border-zinc-300 shadow-md p-2">
          <h1 class="text-xl">tit-for-tat</h1>
          <h2 class="text-sm absolute top-1 right-1 text-zinc-400 ">#23</h2>
          <p class="mb-8 mt-4">
            this is a description lorem ipsum dolor sit amet blah foo blah 1 2 3 4 5
          </p>

          <div class="absolute bottom-2 right-2 bg-green-200 rounded-full px-2 py-1 text-xs font-bold text-green-700 leading-none ring-1 ring-inset ring-green-600/40">
            active
          </div>
        </div>

        <div class="relative rounded ring-1 ring-zinc-300 border-b-2 border-zinc-300 shadow-md p-2">
          <h1 class="text-xl">tit-for-tat</h1>
          <h2 class="text-sm absolute top-1 right-1 text-zinc-400 ">#23</h2>
          <p class="mb-8 mt-4">
            this is a description lorem ipsum dolor sit amet blah foo blah 1 2 3 4 5
          </p>

          <div class="absolute bottom-2 right-2 bg-green-200 rounded-full px-2 py-1 text-xs font-bold text-green-700 leading-none ring-1 ring-inset ring-green-600/40">
            active
          </div>
        </div>

        <div class="relative rounded ring-1 ring-zinc-300 border-b-2 border-zinc-300 shadow-md p-2">
          <h1 class="text-xl">tit-for-tat</h1>
          <h2 class="text-sm absolute top-1 right-1 text-zinc-400 ">#23</h2>
          <p class="mb-8 mt-4">
            this is a description lorem ipsum dolor sit amet blah foo blah 1 2 3 4 5
          </p>

          <div class="absolute bottom-2 right-2 bg-green-200 rounded-full px-2 py-1 text-xs font-bold text-green-700 leading-none ring-1 ring-inset ring-green-600/40">
            active
          </div>
        </div>

        <div class="relative rounded ring-1 ring-zinc-300 border-b-2 border-zinc-300 shadow-md p-2">
          <h1 class="text-xl">tit-for-tat</h1>
          <h2 class="text-sm absolute top-1 right-1 text-zinc-400 ">#23</h2>
          <p class="mb-8 mt-4">
            this is a description lorem ipsum dolor sit amet blah foo blah 1 2 3 4 5
          </p>

          <div class="absolute bottom-2 right-2 bg-green-200 rounded-full px-2 py-1 text-xs font-bold text-green-700 leading-none ring-1 ring-inset ring-green-600/40">
            active
          </div>
        </div>
      </div>
      <ul>
        <li>TODO: 2024-01-28 - Render Card Lists for Agents and upcoming Tournaments</li>
        <li>
          TODO: 2024-01-28 - Render Buttons to add an agent or register an agent to a tournament
        </li>
        <li>TODO: 2024-01-28 - Render Table with results of last tournaments</li>
      </ul>
    <% else %>
      <h2>This is the user dashboard for unauthenticated users.</h2>
      <ul>
        <li>TODO: 2024-01-28 - Render Card Lists for Agents and upcoming Tournaments</li>
        <li>
          TODO: 2024-01-28 - Render Buttons to add an agent or register an agent to a tournament
        </li>
        <li>TODO: 2024-01-28 - Render Table with results of last tournaments</li>
      </ul>
    <% end %>
    """
  end
end
