defmodule Ipdth.Agents do
  @moduledoc """
  The Agents context.
  """

  import Ecto.Query, warn: false
  alias Ipdth.Repo

  alias Ipdth.Accounts.User

  alias Ipdth.Agents.Agent
  alias Ipdth.Agents.Connection

  alias Ipdth.Tournaments.Participation

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
  Lists agents that are associated with a specific user and tournament.
  Used for signing up a user's Agent to a given tournamen.t
  It shows both agents that are signed up for the tournament and those that are not.

  ## Parameters
  - `user_id`: The ID of the user who owns the agents. This is used to filter agents such that only those owned by the given user are considered.
  - `tournament_id`: The ID of the tournament. This is used to determine which agents are signed up for this specific tournament.

  ## Returns
  Returns a list of agents, where each agent is represented as a map. Each map includes:
  - `id`: The ID of the agent.
  - `name`: The name of the agent.
  - `description`: A description of the agent.
  - `status`: The status of the agent.
  - `signed_up`: A boolean indicating whether the agent is signed up for the specified tournament.

  Each agent's participation status in the given tournament is determined and reflected in the `signed_up` field.

  ## Examples

      iex> MyApp.list_agents_for_signup(1, 2)
      [
        %{id: 4, name: "Agent A", description: "Experienced", status: "active", signed_up: true},
        %{id: 5, name: "Agent B", description: "Novice", status: "active", signed_up: false}
      ]

  """
  def list_agents_for_signup(user_id, tournament_id) do
    query =
      from a in Agent,
        left_join: p in Participation,
        on: p.tournament_id == ^tournament_id and p.agent_id == a.id,
        where: a.owner_id == ^user_id,
        select: %{
          id: a.id,
          name: a.name,
          description: a.description,
          status: a.status,
          signed_up: not is_nil(p.id)
        }

    Repo.all(query)
  end

  @doc """
  Fetches all agents participating in a specified tournament, along with their owners.

  ## Parameters
  - tournament_id: The ID of the tournament.

  ## Returns
  - A list of `%Agent{}` structs with the owner preloaded.

  ## Examples
      iex> MyApp.Tournaments.list_agents_by_tournament(1)
      [
        %Agent{
          id: 1,
          name: "Agent 1",
          owner: %User{id: 1, name: "User 1"}
        }
      ]
  """
  def list_agents_by_tournament(tournament_id) do
    query =
      from a in Agent,
        join: p in Participation,
        on: a.id == p.agent_id,
        join: u in User,
        on: u.id == a.owner_id,
        where: p.tournament_id == ^tournament_id,
        preload: [owner: u]

    Repo.all(query)
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
  def update_agent(%Agent{} = agent, actor_id, attrs) do
    if agent.owner_id == actor_id do
      agent
      |> Agent.update(attrs)
      |> Repo.update()
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Deletes a agent.

  ## Examples

      iex> delete_agent(agent)
      {:ok, %Agent{}}

      iex> delete_agent(agent)
      {:error, %Ecto.Changeset{}}

  """
  def delete_agent(%Agent{} = agent, actor_id) do
    if agent.owner_id == actor_id do
      Repo.delete(agent)
    else
      {:error, :not_authorized}
    end
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
  def activate_agent(%Agent{} = agent, actor_id) do
    if agent.owner_id == actor_id do
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
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Deactivates an agent. Resets error status.

  ## Examples

      iex> activate_agent(agent)
      {:ok, %Agent{}}
  """
  def deactivate_agent(%Agent{} = agent, actor_id) do
    if agent.owner_id == actor_id do
      agent
      |> Agent.deactivate()
      |> Repo.update()
    else
      {:error, :not_authorized}
    end
  end
end
