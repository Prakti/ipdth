defmodule IpdthWeb.UserLive.Index do
  use IpdthWeb, :live_view

  alias Ipdth.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {:ok,
     socket
     |> assign(:active_page, "users")
     |> assign(:is_user_admin, Enum.member?(current_user.roles, :user_admin))
     |> stream(:users, Accounts.list_users_with_agent_count_and_status())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Users")
    |> assign(:user, nil)
  end

end
