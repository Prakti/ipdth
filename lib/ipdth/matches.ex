defmodule Ipdth.Matches do
  @moduledoc """
  The Matches context.
  """

  import Ecto.Query, warn: false
  alias Ipdth.Repo

  alias Ipdth.Matches.{Match, Round}

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
  Returns a list of matches with IDs corresponding to the ones
  given in as a list via `match_ids`. It will retrieve matches on a
  best-effort base, ignoring unkown ids that are still of type integer.

  It will raise an error in case one of the ids is not of type integer.
  """
  def list_matches_by_ids(match_ids) do
    query =
      from m in Match,
        where: m.id in ^match_ids

    Repo.all(query)
  end

  def list_matches_by_tournament(tournament_id, map_or_flop \\ %{}) do
    query =
      Match
      |> where([m], m.tournament_id == ^tournament_id)
      |> join(:inner, [m], a in assoc(m, :agent_a), as: :agent_a)
      |> preload([agent_a: a], agent_a: a)
      |> join(:inner, [m], b in assoc(m, :agent_b), as: :agent_b)
      |> preload([agent_b: b], agent_b: b)

    Flop.validate_and_run(query, map_or_flop,
      for: Match,
      repo: Repo,
      default_pagination_type: :first,
      pagination_types: [:first, :last]
    )
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
  def create_match(agent_a, agent_b, tournament, tournament_round, rounds_to_play) do
    Match.new(agent_a, agent_b, tournament, tournament_round, rounds_to_play)
    |> Repo.insert()
  end

  @doc """
  Creates multiple matches in one transaction.

  """
  def create_multiple_matches(matches) do
    Repo.insert_all(Match, matches)
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

  def delete_all_matches_of_tournament(tournament_id) do
    # Delete all matches associated with this tournament
    query =
      from m in Match,
        where: m.tournament_id == ^tournament_id,
        select: m

    Repo.delete_all(query)
  end

  def count_matches_in_tournament(tournament_id) do
    query =
      from m in Match,
        where: m.tournament_id == ^tournament_id,
        select: count(m.id)

    Repo.one(query)
  end

  def determine_current_tournament_round(tournament_id) do
    query =
      from m in Match,
        where: m.tournament_id == ^tournament_id,
        where: m.status == :open or m.status == :started,
        select: min(m.tournament_round)

    Repo.one(query)
  end

  def get_open_or_started_matches_for_tournament_round(tournament_id, round_no) do
    query =
      from m in Match,
        where: m.tournament_id == ^tournament_id,
        where: m.tournament_round == ^round_no,
        where: m.status == :open or m.status == :started,
        select: m.id

    Repo.all(query)
  end

  def sum_tournament_score_for_agents(tournament_id) do
    query_a =
      from m in Match,
        where: m.tournament_id == ^tournament_id,
        where: m.status == :finished,
        group_by: m.agent_a_id,
        select: {m.agent_a_id, sum(m.score_a)}

    query_b =
      from m in Match,
        where: m.tournament_id == ^tournament_id,
        where: m.status == :finished,
        group_by: m.agent_b_id,
        select: {m.agent_b_id, sum(m.score_b)}

    scores_a = Repo.all(query_a) |> Map.new()
    scores_b = Repo.all(query_b) |> Map.new()

    Map.merge(scores_a, scores_b, fn _id, score_a, score_b ->
      score_a + score_b
    end)
  end

  def invalidate_past_matches_for_errored_agents(agents, tournament) do
    Repo.transaction(fn ->
      Enum.each(agents, fn agent ->
        query =
          from m in Match,
            where: m.tournament_id == ^tournament.id,
            where:
              m.agent_a_id == ^agent.id or
                m.agent_b_id == ^agent.id,
            where: m.status == :finished,
            update: [set: [status: :invalidated]]

        Repo.update_all(query, [])
      end)
    end)
  end

  def cancel_open_matches_for_errored_agents(agents, tournament) do
    Repo.transaction(fn ->
      Enum.each(agents, fn agent ->
        query =
          from m in Match,
            where: m.tournament_id == ^tournament.id,
            where:
              m.agent_a_id == ^agent.id or
                m.agent_b_id == ^agent.id,
            where: m.status == :open,
            update: [set: [status: :cancelled]]

        Repo.update_all(query, [])
      end)
    end)
  end

  @doc """
  Fetches all Rounds for a given Match ID.
  Returns an empty list if nothing was found.
  """
  def get_rounds_for_match(match_id, params \\ %{}) do
    Round
    |> where(match_id: ^match_id)
    |> Flop.validate_and_run(params,
      for: Round,
      repo: Repo,
      default_pagination_type: :first,
      pagination_types: [:first, :last]
    )
  end
end
