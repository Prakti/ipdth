defmodule Ipdth.Matches.Runner do

  alias Ipdth.Matches
  alias Ipdth.Matches.{Match, Round}

  alias Ipdth.Agents.Connection

  def run_match(%Match{} = match, rounds_to_play, tournament_runner_pid) do
    round_no = Enum.count(match.rounds)
    if round_no < rounds_to_play do
      start_date = DateTime.utc_now()
      match_info = %Connection.MatchInfo{
        type: "Tournament Match",
        tournament_id: match.tournament_id,
        match_id: match.id
      }

      # TODO: 2024-05-24 - Execute with Task and try-rescue
      result_a =
        try do
          agent_a_decision_request(match, round_no, match_info)
        rescue
          _ -> {:error, :unknown}
          # TODO: 2024-05-26 - Set error status on match and report to tournament_runner
        end

      result_b =
        try do
          agent_b_decision_request(match, round_no, match_info)
        rescue
          _ -> {:error, :unknown}
          # TODO: 2024-05-26 - Set error status on match and report to tournament_runner
        end

      round = tally_round(result_a, result_b, start_date)

      #{:ok, updated_match} = Matches.save_match_round(match, round)
      #run_match(updated_match, rounds_to_play, tournament_runner_pid)
    else
      TournamentRunner.report_complete_match(tournament_runner_pid, match)
    end
  end

  defp agent_a_decision_request(match, round_no, match_info) do
    past_results_a = Enum.map(match.rounds, fn round ->
      %Connection.PastResult{ action: round.action_a, points: round.score_a }
    end)

    request_a = %Connection.Request{
      round_number: round_no,
      past_results: past_results_a,
      match_info: match_info
    }

    Connection.decide(match.agent_a, request_a)
  end

  defp agent_b_decision_request(match, round_no, match_info) do
    past_results_b = Enum.map(match.rounds, fn round ->
      %Connection.PastResult{ action: round.action_b, points: round.score_b }
    end)

    request_b = %Connection.Request{
      round_number: round_no,
      past_results: past_results_b,
      match_info: match_info
    }

    Connection.decide(match.agent_b, request_b)
  end

  defp tally_round(result_a, result_b, start_date) do
    action_a = case result_a["action"] do
      "cooperate" -> :cooperate
      "Cooperate" -> :cooperate
      _ -> :compete
    end

    action_b = case result_b["action"] do
      "cooperate" -> :cooperate
      "Cooperate" -> :cooperate
      _ -> :compete
    end

    {score_a, score_b} = case {action_a, action_b} do
      {:cooperate, :cooperate} -> {1,1}
      {:cooperate, :compete} -> {0, 2}
      {:compete, :cooperate} -> {2, 0}
      {:compete, :compete} -> {0,0}
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
