defmodule Ipdth.Matches.Runner do
  @moduledoc """
  This module models a concurrent task, in which one match between two agents
  is handled. Calls to the agents, scoring, saving state is managed from here.
  """

  import Ecto.Query, warn: false

  alias Ipdth.Repo
  alias Ipdth.Matches.{Match, Round}
  alias Ipdth.Tournaments
  alias Ipdth.Agents.ConnectionManager
  alias Ipdth.Agents.Connection.{MatchInfo, PastResult, Request}

  require Logger

  def start(supervisor_pid, args) do
    Task.Supervisor.start_child(supervisor_pid, __MODULE__, :run, args, restart: :transient)
  end

  def run(%Match{} = match, tournament_runner_pid), do: run(match.id, tournament_runner_pid)

  def run(match_id, tournament_runner_pid) do
    # Our Runner might have crashed and been restarted.
    # We re-fetch the match from DB to avoid working on stale data
    match =
      Repo.get!(Match, match_id)
      |> Repo.preload([:agent_a, :agent_b, :tournament, :rounds])

    case match.status do
      :open ->
        Match.start(match) |> Repo.update()
        run(match, match.rounds_to_play, 0, tournament_runner_pid)

      :started ->
        round_no = count_match_rounds(match_id)
        run(match, match.rounds_to_play, round_no, tournament_runner_pid)

      other ->
        Logger.warning(
          "Matches.Runner encountered match in state #{other}." <>
            "Match: #{inspect(match, pretty: true)}"
        )

        report_completed_match(match, tournament_runner_pid)
    end
  end

  def run(match, rounds_to_play, round_no, tournament_runner_pid)
      when round_no < rounds_to_play do
    start_date = DateTime.utc_now()

    match_info = %MatchInfo{
      type: "Tournament Match",
      tournament_id: match.tournament_id,
      match_id: match.id
    }

    task_a = Task.async(__MODULE__, :agent_a_decision_request, [match, round_no, match_info])
    task_b = Task.async(__MODULE__, :agent_b_decision_request, [match, round_no, match_info])

    results =
      [task_a, task_b]
      |> Task.await_many(ConnectionManager.compute_timeout())
      |> List.to_tuple()

    case results do
      {{:ok, decision_a}, {:ok, decision_b}} ->
        {:ok, _round} = tally_round(match.id, decision_a, decision_b, start_date)
        run(match, rounds_to_play, round_no + 1, tournament_runner_pid)

      {{:error, _}, {:ok, _}} ->
        Logger.info("Agent #{match.agent_a_id} is in error-state, aborting Match.")
        abort_match(match, tournament_runner_pid)

      {{:ok, _}, {:error, _}} ->
        Logger.info("Agent #{match.agent_b_id} is in error-state, aborting Match.")
        abort_match(match, tournament_runner_pid)

      {{:error, _}, {:error, _}} ->
        Logger.info(
          "Agents #{match.agent_b_id} and #{match.agent_a_id} are in error-state, aborting Match."
        )

      other ->
        Logger.warning("Unexpected Agent decisions: #{inspect(other)}.")
        abort_match(match, tournament_runner_pid)
    end
  end

  def run(match, _, _, tournament_runner_pid) do
    query =
      from r in Round,
        where: r.match_id == ^match.id,
        select: %{score_a: sum(r.score_a), score_b: sum(r.score_b)}

    total_scores = Repo.one(query)

    {:ok, finished_match} = Match.finish(match, total_scores) |> Repo.update()
    report_completed_match(finished_match, tournament_runner_pid)
  end

  def agent_a_decision_request(match, round_no, match_info) do
    past_results_a =
      Enum.map(match.rounds, fn round ->
        %PastResult{action: round.action_a, points: round.score_a}
      end)

    request_a = %Request{
      round_number: round_no,
      past_results: past_results_a,
      match_info: match_info
    }

    ConnectionManager.decide(match.agent_a, request_a)
  end

  def agent_b_decision_request(match, round_no, match_info) do
    past_results_b =
      Enum.map(match.rounds, fn round ->
        %PastResult{action: round.action_b, points: round.score_b}
      end)

    request_b = %Request{
      round_number: round_no,
      past_results: past_results_b,
      match_info: match_info
    }

    ConnectionManager.decide(match.agent_b, request_b)
  end

  defp tally_round(match_id, action_a, action_b, start_date) do
    {score_a, score_b} =
      case {action_a, action_b} do
        {:cooperate, :cooperate} -> {3, 3}
        {:cooperate, :defect} -> {0, 5}
        {:defect, :cooperate} -> {5, 0}
        {:defect, :defect} -> {1, 1}
      end

    Round.new(match_id, action_a, action_b, score_a, score_b, start_date)
    |> Repo.insert()
  end

  defp count_match_rounds(match_id) do
    query =
      from r in Round,
        where: r.match_id == ^match_id

    Repo.aggregate(query, :count, :id)
  end

  defp abort_match(match, tournament_runner_pid) do
    {:ok, aborted_match} = Match.abort(match) |> Repo.update()
    report_completed_match(aborted_match, tournament_runner_pid)
  end

  defp report_completed_match(match, tournament_runner_pid) do
    Tournaments.Runner.report_finished_match(tournament_runner_pid, match)
  end
end
