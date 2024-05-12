defmodule IpdthWeb.UserLive.Index do
  use IpdthWeb, :live_view

  require Logger

  import IpdthWeb.AuthZ

  alias Ipdth.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    {:ok,
     socket
     |> assign(:active_page, "users")
     |> assign(:is_user_admin, user_admin?(current_user))
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

  defp apply_action(socket, :edit_roles, %{"id" => id}) do
    user_to_edit = Accounts.get_user!(id)
    socket
    |> assign(:page_title, "Edit User Roles")
    |> assign(:user_to_edit, user_to_edit)
    |> assign(:roles_mapping, compute_roles_mapping(user_to_edit.roles))
  end

  defp compute_roles_mapping(assigned_roles) do
    available_roles = Accounts.User.get_available_roles()
    Enum.map(available_roles, fn role ->
      {role, Enum.member?(assigned_roles, role)}
    end)
  end

  @impl true
  def handle_event("toggle_role", %{"role" => role, "value" => "on"}, socket) do
    actor = socket.assigns.current_user
    user_to_edit = socket.assigns.user_to_edit

    case Accounts.add_user_role(user_to_edit, role, actor.id) do
      {:ok, user} ->
        Logger.debug("Added Role #{role} to #{user.id} - Roles #{inspect(user.roles)}" )
        {:noreply,
          socket
          |> assign(:user_to_edit, user)
          |> assign(:roles_mapping, compute_roles_mapping(user.roles))
          |> stream(:users, Accounts.list_users_with_agent_count_and_status())}
      {:error, details} ->
        Logger.warning(details)
        {:noreply, put_flash(socket, :error, "Could not add role")}
    end
  end

  def handle_event("toggle_role", %{"role" => role}, socket) do
    actor = socket.assigns.current_user
    user_to_edit = socket.assigns.user_to_edit

    case Accounts.remove_user_role(user_to_edit, role, actor.id) do
      {:ok, user} ->
        Logger.debug("Removed Role #{role} from #{user.id} - Roles #{inspect(user.roles)}" )
        {:noreply,
          socket
          |> assign(:user_to_edit, user)
          |> assign(:roles_mapping, compute_roles_mapping(user.roles))
          |> stream(:users, Accounts.list_users_with_agent_count_and_status())}
      {:error, details} ->
        Logger.warning(details)
        {:noreply, put_flash(socket, :error, "Could not remove role")}
    end
  end

end
