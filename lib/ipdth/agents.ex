defmodule Ipdth.Agents do
  @moduledoc """
  The Agents context.
  """

  import Ecto.Query, warn: false
  alias Ipdth.Repo

  alias Ipdth.Agents.Agent
  alias Ipdth.Agents.Connection

  # TODO: 2024-03-18 - Save User as Owner upon creation
  # TODO: 2024-03-18 - Ensure that only Owner can update, activate, deactivate an agent

  @doc """
  Returns the list of agents.

  ## Examples

      iex> list_agents()
      [%Agent{}, ...]

  """
  def list_agents do
    Repo.all(Agent)
  end

  @doc """
  Gets a single agent.

  Raises `Ecto.NoResultsError` if the Agent does not exist.

  ## Examples

      iex> get_agent!(123)
      %Agent{}

      iex> get_agent!(456)
      ** (Ecto.NoResultsError)

  """
  def get_agent!(id), do: Repo.get!(Agent, id)

  @doc """
  Creates a agent.

  ## Examples

      iex> create_agent(%{field: value})
      {:ok, %Agent{}}

      iex> create_agent(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agent(attrs \\ %{}) do
    %Agent{}
    |> Agent.new(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a agent.

  ## Examples

      iex> update_agent(agent, %{field: new_value})
      {:ok, %Agent{}}

      iex> update_agent(agent, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_agent(%Agent{} = agent, attrs) do
    agent
    |> Agent.update(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a agent.

  ## Examples

      iex> delete_agent(agent)
      {:ok, %Agent{}}

      iex> delete_agent(agent)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agent(%Agent{} = agent) do
    Repo.delete(agent)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking agent changes.

  ## Examples

      iex> change_agent(agent)
      %Ecto.Changeset{data: %Agent{}}

  """
  def change_agent(%Agent{} = agent, attrs \\ %{}) do
    Agent.changeset(agent, attrs)
  end

  @doc """
  Activates an agent. Tests the connection before activation.

  ## Examples

      iex> activate_agent(agent)
      {:ok, %Agent{}}
  """
  def activate_agent(%Agent{} = agent) do
    # TODO: 2024-03-18 - Think about running the connection test in a separate process

    case Connection.test(agent) do
      :ok ->
        agent
        |> Agent.activate()
        |> Repo.update()
      {:error, {_type, _details}} ->
        agent
        |> Agent.error_backoff()
        |> Repo.update()
    end
  end
end
