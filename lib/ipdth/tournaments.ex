defmodule Ipdth.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Ipdth.Repo

  alias Ipdth.Tournaments.Participation
  alias Ipdth.Tournaments.Tournament
  alias Ipdth.Agents.Agent
  alias Ipdth.Accounts

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments()
      [%Tournament{}, ...]

  """
  def list_tournaments() do
    Repo.all(from t in Tournament, where: t.status != ^:created)
  end

  def list_tournaments(actor_id) do
    if Accounts.has_role?(actor_id, :tournament_admin) do
      Repo.all(Tournament)
    else
      list_tournaments()
    end
  end

  @doc """
  Lists published tournaments along with a flag indicating whether a given agent is already signed up.

  This function retrieves all tournaments that have a status of 'published' and determines if the specified agent
  is already participating in each tournament. It returns a list of tournament details, each enhanced with a `signed_up`
  boolean flag that is `true` if the agent is already signed up, otherwise `false`.

  ## Parameters
  - agent_id: The ID of the agent for whom to check tournament signups. This is an integer representing the unique identifier of the agent in the database.

  ## Returns
  - A list of maps, where each map contains the following keys:
    - :id - The ID of the tournament.
    - :name - The name of the tournament.
    - :description - A description of the tournament.
    - :start_date - The start date of the tournament.
    - :round_number - The current round number of the tournament.
    - :signed_up - A boolean indicating whether the agent is signed up for the tournament.

  ## Example
      iex> Tournaments.list_tournaments_for_signup(1)
      [
        %{id: 2, name: "Open Championship", description: "Annual open chess tournament.", start_date: ~D[2023-06-15], round_number: 1, signed_up: false},
        %{id: 3, name: "Regional Qualifier", description: "Qualifier for the national finals.", start_date: ~D[2023-07-20], round_number: 2, signed_up: true}
      ]
  """
  def list_tournaments_for_signup(agent_id) do
    # TODO: 2024-05-12 - Write test for this query
    query =
      from t in Tournament,
        left_join: p in Participation,
        on: p.tournament_id == t.id and p.agent_id == ^agent_id,
        where: t.status == :published,
        select: %{
          id: t.id,
          name: t.name,
          description: t.description,
          start_date: t.start_date,
          round_number: t.round_number,
          signed_up: not is_nil(p.id)
        }

    Repo.all(query)
  end

  @doc """
  Lists all tournaments in which a specific agent has signed up.

  This function retrieves a list of tournaments where the specified agent has a 'signed_up' status in their participation. It executes a query joining the `Tournament`, `Participation`, and `Agent` schemas to filter out only those tournaments where the `agent_id` matches and the participation status is `:signed_up`.

  ## Parameters
  - `agent_id`: The ID of the agent for whom signed up tournaments are being queried.

  ## Returns
  - A list of `Tournament` structs, each preloaded with associated `Participation` records that match the agent ID and signed-up status.

  ## Examples
      # Get all signed-up tournaments for agent with ID 1
      iex> MyProject.list_signed_up_tournaments_by_agent(1)
      [%Tournament{...}, ...]

  """
  def list_signed_up_tournaments_by_agent(agent_id) do
    query =
      from t in Tournament,
        join: p in Participation,
        on: t.id == p.tournament_id,
        join: a in Agent,
        on: a.id == p.agent_id,
        where: p.agent_id == ^agent_id,
        where: p.status == :signed_up,
        preload: [participations: p]

    Repo.all(query)
  end

  @doc """
  Fetches a list of published tournaments that are due or overdue as of the given timestamp.

  ## Parameters

    - `timestamp`: A `DateTime` struct representing the current time. Tournaments with a start date earlier than or equal to this timestamp will be considered due or overdue.

  ## Returns

    - A list of `%Tournament{}` structs that are published and have a start date earlier than or equal to the provided timestamp.

  ## Examples
      iex> current_time = DateTime.utc_now()
      iex> list_due_and_overdue_tournaments(current_time)
      [%Tournament{status: :published, start_date: ~U[2023-05-21 15:30:00Z]}, ...]
  """
  def list_due_and_overdue_tournaments(%DateTime{} = timestamp) do
    query =
      from t in Tournament,
        where: t.status == :published,
        where: t.start_date <= ^timestamp

    Repo.all(query)
  end

  @doc """
  Gets a single tournament.

  Raises `Ecto.NoResultsError` if the Tournament does not exist.

  ## Examples

      iex> get_tournament!(123)
      %Tournament{}

      iex> get_tournament!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tournament!(id) do
    Repo.one(from t in Tournament, where: t.id == ^id and t.status != ^:created)
  end

  def get_tournament!(id, actor_id) do
    if Accounts.has_role?(actor_id, :tournament_admin) do
      Repo.get!(Tournament, id)
    else
      get_tournament!(id)
    end
  end

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(attrs \\ %{}, actor_id) do
    if Accounts.has_role?(actor_id, :tournament_admin) do
      %Tournament{}
      |> Tournament.new(attrs, actor_id)
      |> Repo.insert()
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(%Tournament{} = tournament, attrs, actor_id) do
    if Accounts.has_role?(actor_id, :tournament_admin) do
      if Enum.member?([:created, :published], tournament.status) do
        tournament
        |> Tournament.update(attrs, actor_id)
        |> Repo.update()
      else
        {:error, :tournament_editing_locked}
      end
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Publish a tournament (:created -> :published)

  Once published only it's name and description may be changed.
  TODO: 2024-04-30 - Write Test for publish_tournament!
  """
  def publish_tournament(%Tournament{status: :created} = tournament, actor_id) do
    if Accounts.has_role?(actor_id, :tournament_admin) do
      tournament
      |> Tournament.publish(actor_id)
      |> Repo.update()
    else
      {:error, :not_authorized}
    end
  end

  def publish_tournament(%Tournament{}, _actor_id) do
    {:error, :already_published}
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(%Tournament{} = tournament, actor_id) do
    if Accounts.has_role?(actor_id, :tournament_admin) do
      Repo.delete(tournament)
    else
      {:error, :not_authorized}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tournament changes.

  ## Examples

      iex> change_tournament(tournament)
      %Ecto.Changeset{data: %Tournament{}}

  """
  def change_tournament(%Tournament{} = tournament, attrs \\ %{}) do
    Tournament.changeset(tournament, attrs)
  end

  @doc """
  Returns the list of participations.

  ## Examples

      iex> list_participations()
      [%Participation{}, ...]

  """
  def list_participations do
    Repo.all(Participation)
  end

  @doc """
  Gets a single participation.

  Raises `Ecto.NoResultsError` if the Participation does not exist.

  ## Examples

      iex> get_participation!(123)
      %Participation{}

      iex> get_participation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_participation!(id), do: Repo.get!(Participation, id)

  def get_participation(agent_id, tournament_id) do
    Repo.one(
      from p in Participation,
        where: p.agent_id == ^agent_id and p.tournament_id == ^tournament_id,
        limit: 1
    )
  end

  @doc """
  Sign an Agent up for a tournament.

  ## Examples

      iex> sign_up(tournament, agent)
      {:ok, %Participation}
  """
  def sign_up(%Tournament{status: :published} = tournament, %Agent{} = agent, actor_id) do
    # TODO: 2024-05-12 - Put uniqueness constraint on the participation table for {agent_id, tournament_id}
    if agent.owner_id == actor_id do
      case find_or_create_participation(agent, tournament) do
        {:ok, {:ok, participation}} ->
          {:ok, participation}

        {:error, details} ->
          {:error, details}
      end
    else
      {:error, :not_authorized}
    end
  end

  def sign_up(%Tournament{}, %Agent{}) do
    {:error, :wrong_tournament_or_agent}
  end

  defp find_or_create_participation(agent, tournament) do
    Repo.transaction(fn ->
      participation = get_participation(agent.id, tournament.id)

      if participation do
        {:ok, participation}
      else
        %Participation{}
        |> Participation.sign_up(tournament, agent)
        |> Repo.insert()
      end
    end)
  end

  def sign_off(%Tournament{} = tournament, %Agent{} = agent, actor_id) do
    if agent.owner_id == actor_id do
      participation = get_participation(agent.id, tournament.id)

      if participation do
        Repo.delete(participation)
      else
        {:ok, participation}
      end
    else
      {:error, :not_authorized}
    end
  end
end
