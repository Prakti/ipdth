defmodule IpdthWeb.AuthZ do
  @moduledoc """
  Helper methods for checking authorization. Import into your LiveView.
  """

  alias Ipdth.Accounts
  alias Ipdth.Accounts.User
  alias Ipdth.Agents.Agent

  @doc """
  Check whether the given user or user_id has the :user_admin role.
  For robustness reasons, this returns `false` for invalid input like `nil`
  or id's of nonexisting users.
  """
  def user_admin?(%User{} = user) do
    Enum.member?(user.roles, :user_admin)
  end

  def user_admin?(user_id) when is_integer(user_id) do
    user_admin?(Accounts.get_user!(user_id))
  end

  def user_admin?(_) do
    false
  end

  @doc """
  Check whether the given user or user_id has the :tournament_admin role.
  For robustness reasons, this returns `false` for invalid input like `nil`
  or id's of nonexisting users.
  """
  def tournament_admin?(%User{} = user) do
    Accounts.has_role?(user.id, :tournament_admin)
  end

  def tournament_admin?(user_id) when is_integer(user_id) do
    tournament_admin?(Accounts.get_user!(user_id))
  end

  def tournament_admin?(_) do
    false
  end


  @doc """
  Check whether the given user or user_id is the owner of a given Agent
  For robustness reasons, this returns `false` for invalid input like `nil`
  or id's of nonexisting users.
  """
  def agent_owner?(%User{} = user, %Agent{} = agent) do
    agent_owner?(user.id, agent)
  end

  def agent_owner?(user_id, %Agent{owner_id: owner_id}) when is_integer(user_id) do
    user_id == owner_id
  end

  def agent_owner?(_, _) do
    false
  end

end
