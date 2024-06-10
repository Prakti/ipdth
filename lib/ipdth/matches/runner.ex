defmodule Ipdth.Matches.Runner do
  alias Ipdth.Matches
  alias Ipdth.Matches.{Match, Round}

  alias Ipdth.Agents.ConnectionManager
  alias Ipdth.Agents.Connection.{MatchInfo, PastResult, Request}

  def run_match(%Match{} = match, rounds_to_play, tournament_runner_pid) do
    round_no = Enum.count(match.rounds)

    if round_no < rounds_to_play do
      start_date = DateTime.utc_now()

      match_info = %MatchInfo{
        type: "Tournament Match",
        tournament_id: match.tournament_id,
        match_id: match.id
      }

      {:ok, result_a} = agent_a_decision_request(match, round_no, match_info)
      # TODO: 2024-06-10 - Check for error, and handle it properly

      {:ok, result_b} = agent_b_decision_request(match, round_no, match_info)
      # TODO: 2024-06-10 - Check for error, and handle it properly

      round = tally_round(result_a, result_b, start_date)

      # {:ok, updated_match} = Matches.save_match_round(match, round)
      # run_match(updated_match, rounds_to_play, tournament_runner_pid)
    else
      TournamentRunner.report_complete_match(tournament_runner_pid, match)
    end
  end

  defp agent_a_decision_request(match, round_no, match_info) do
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

  defp agent_b_decision_request(match, round_no, match_info) do
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

  defp tally_round(action_a, action_b, start_date) do
    {score_a, score_b} =
      case {action_a, action_b} do
        {:cooperate, :cooperate} -> {3, 3}
        {:cooperate, :defect} -> {0, 5}
        {:defect, :cooperate} -> {5, 0}
        {:defect, :defect} -> {1, 1}
      end

    %Round{
      action_a: action_a,
      action_b: action_b,
      score_a: score_a,
      score_b: score_b,
      start_date: start_date,
      end_date: DateTime.utc_now()
    }
  end

end
