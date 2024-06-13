defmodule Ipdth.Matches do
  @moduledoc """
  The Matches context.
  """

  import Ecto.Query, warn: false
  alias Ipdth.Repo

  alias Ipdth.Matches.Match

  @doc """
  Returns the list of matches.

  ## Examples

      iex> list_matches()
      [%Match{}, ...]

  """
  def list_matches do
    Repo.all(Match)
  end

  @doc """
  Gets a single match.

  Raises `Ecto.NoResultsError` if the Match does not exist.

  ## Examples

      iex> get_match!(123)
      %Match{}

      iex> get_match!(456)
      ** (Ecto.NoResultsError)

  """
  def get_match!(id, preload \\ []) do
    Repo.get!(Match, id) |> Repo.preload(preload)
  end




  @doc """
  Creates a match.

  """
  def create_match(agent_a, agent_b, tournament, rounds_to_play) do
    Match.new(agent_a, agent_b, tournament, rounds_to_play)
    |> Repo.insert()
  end

  @doc """
  Deletes a match.

  ## Examples

      iex> delete_match(match)
      {:ok, %Match{}}

      iex> delete_match(match)
      {:error, %Ecto.Changeset{}}

  """
  def delete_match(%Match{} = match) do
    Repo.delete(match)
  end

end
