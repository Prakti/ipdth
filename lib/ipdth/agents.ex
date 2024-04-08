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
    Repo.all(from a in Agent, preload: :owner)
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
  def get_agent!(id, preload \\ []), do: Repo.get!(Agent, id) |> Repo.preload(preload)

  @doc """
  Loads the owner for a given Agent. Sometimes you already have a loaded agent
  and also want the owner for it. You can then use this to load the owner into
  the association on the agent schema.

  ## Example

     iex> load_owner(agent)
     %Agent{}
  """
  def load_owner(%Agent{} = agent), do: Repo.preload(agent, [:owner])

  @doc """
  Creates a agent.

  ## Examples

      iex> create_agent(owner_id, %{field: value})
      {:ok, %Agent{}}

      iex> create_agent(owner_id, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_agent(owner_id, attrs \\ %{}) do
    %Agent{}
    |> Agent.new(owner_id, attrs)
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
    # TODO: 2024-03-18 - Run the connection test in a separate process
    # TODO: 2024-04-03 - Trap exits of the separate process and handle errors

    case Connection.test(agent) do
      :ok ->
        agent
        |> Agent.activate()
        |> Repo.update()
      {:error, {_type, details}} ->
        # TODO: 2024-04-08 - Save details of errors in a text field on the agent
        agent
        |> Agent.error_backoff()
        |> Repo.update()
        {:error, details}
      {:error, details} ->
        # TODO: 2024-04-08 - Save details of errors in a text field on the agent
        agent
        |> Agent.error_backoff()
        |> Repo.update()
        {:error, details}
    end
  end

  @doc """
  Deactivates an agent. Resets error status.

  ## Examples

      iex> activate_agent(agent)
      {:ok, %Agent{}}
  """
  def deactivate_agent(%Agent{} = agent) do
    agent
    |> Agent.deactivate()
    |> Repo.update()
  end
end
