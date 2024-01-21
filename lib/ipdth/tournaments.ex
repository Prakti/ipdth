defmodule Ipdth.Tournaments do
  @moduledoc """
  The Tournaments context.
  """

  import Ecto.Query, warn: false
  alias Ipdth.Repo

  alias Ipdth.Tournaments.Tournament

  @doc """
  Returns the list of tournaments.

  ## Examples

      iex> list_tournaments()
      [%Tournament{}, ...]

  """
  def list_tournaments do
    Repo.all(Tournament)
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
  def get_tournament!(id), do: Repo.get!(Tournament, id)

  @doc """
  Creates a tournament.

  ## Examples

      iex> create_tournament(%{field: value})
      {:ok, %Tournament{}}

      iex> create_tournament(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tournament(attrs \\ %{}) do
    %Tournament{}
    |> Tournament.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a tournament.

  ## Examples

      iex> update_tournament(tournament, %{field: new_value})
      {:ok, %Tournament{}}

      iex> update_tournament(tournament, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tournament(%Tournament{} = tournament, attrs) do
    tournament
    |> Tournament.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a tournament.

  ## Examples

      iex> delete_tournament(tournament)
      {:ok, %Tournament{}}

      iex> delete_tournament(tournament)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tournament(%Tournament{} = tournament) do
    Repo.delete(tournament)
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

  alias Ipdth.Tournaments.Participation

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

  @doc """
  Creates a participation.

  ## Examples

      iex> create_participation(%{field: value})
      {:ok, %Participation{}}

      iex> create_participation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_participation(attrs \\ %{}) do
    %Participation{}
    |> Participation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a participation.

  ## Examples

      iex> update_participation(participation, %{field: new_value})
      {:ok, %Participation{}}

      iex> update_participation(participation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_participation(%Participation{} = participation, attrs) do
    participation
    |> Participation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a participation.

  ## Examples

      iex> delete_participation(participation)
      {:ok, %Participation{}}

      iex> delete_participation(participation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_participation(%Participation{} = participation) do
    Repo.delete(participation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking participation changes.

  ## Examples

      iex> change_participation(participation)
      %Ecto.Changeset{data: %Participation{}}

  """
  def change_participation(%Participation{} = participation, attrs \\ %{}) do
    Participation.changeset(participation, attrs)
  end
end
