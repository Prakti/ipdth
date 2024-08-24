defmodule IpdthWeb.UserLive.Index do
  use IpdthWeb, :live_view

  require Logger

  import IpdthWeb.AuthZ

  alias Ipdth.Accounts

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    is_user_admin = user_admin?(current_user)

    {:ok,
     socket
     |> assign(:active_page, "users")
     |> assign(:filter_fields, filter_field_config(is_user_admin))
     |> assign(:is_user_admin, is_user_admin)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    case Accounts.list_users_with_filter_and_sort(params) do
      {:ok, {users, meta}} ->
        {:noreply,
         socket
         |> assign(:user, nil)
         |> assign(:meta, meta)
         |> stream(:users, users, reset: true)
         |> apply_action(socket.assigns.live_action, params)}

      {:error, meta} ->
        Logger.debug("Could not apply filters: #{inspect(meta)}")

        {:noreply,
         socket
         |> put_flash(
           :error,
           "Could not Load data with specified filter and sorting. Reverting to defaults."
         )
         |> apply_action(socket.assigns.live_action, params)
         |> push_patch(to: ~p"/users")}
    end
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
        Logger.debug("Added Role #{role} to #{user.id} - Roles #{inspect(user.roles)}")

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
        Logger.debug("Removed Role #{role} from #{user.id} - Roles #{inspect(user.roles)}")

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

  @impl true
  def handle_event("filter", params, socket) do
    case Flop.validate(params) do
      {:ok, flop} ->
        {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/users", flop))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not apply Filter!")}
    end
  end

  @impl true
  def handle_event("page-size", %{"size" => size}, socket) do
    flop = %Flop{socket.assigns.meta.flop | first: size}
    {:noreply, push_patch(socket, to: Flop.Phoenix.build_path(~p"/users", flop))}
  end

  defp filter_field_config(false) do
    [
      email: [
        op: :ilike_and
      ]
    ]
  end

  defp filter_field_config(true) do
    [
      email: [
        op: :ilike_and
      ]
      # TODO: 2024-08-22 - Turn status into a proper field to enable filtering and sorting
    ]
  end
end
