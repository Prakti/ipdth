defmodule Ipdth.Tournaments.Runner do
  @moduledoc """
  This module manages the execution of a tournament as a concurrent task.
  It does calculation of match schedules and then triggers the execution of
  matches, as the tournament progresses. It finally computes the final scores
  of all participating agents as well as their ranking within the tournament.
  This module also handles edge cases, such as an agent going into an error
  state.
  """
  require Logger

  alias Ipdth.Agents
  alias Ipdth.Agents.Agent
  alias Ipdth.Matches
  alias Ipdth.Matches.Match
  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Tournament

  # TODO: 2024-06-29 - Idea: recompute scores and ranks after each tournament round and send PubSub message for live-updates in the UI

  @supervisor_name Ipdth.Tournaments.Supervisor

  def supervisor_spec, do: {Task.Supervisor, name: @supervisor_name}

  def start(tournament) do
    Task.Supervisor.start_child(@supervisor_name, __MODULE__, :run, [tournament],
      restart: :transient
    )
  end

  def run(%Tournament{} = tournament), do: run(tournament.id)

  def run(tournament_id) do
    # Our runner might have crashed and been restarted.
    # We re-fetch the tournament from DB to avoid working on stale data
    tournament = Tournaments.get_tournament!(tournament_id)

    case tournament.status do
      :published ->
        prepare_and_start_tournament(tournament)

      :signup_closed ->
        prepare_and_start_tournament(tournament)

      :running ->
        check_and_resume_tournament(tournament)

      other ->
        Logger.warning("Attempting to run tournament in status #{other}. Stopping.")
    end
  end

  def report_finished_match(runner_pid, %Match{} = match) do
    Process.send(runner_pid, {:match_finished, match}, [])
  end

  defp prepare_and_start_tournament(tournament) do
    Tournaments.set_tournament_to_started(tournament)
    tournament_rounds = Tournaments.create_round_robin_schedule(tournament)
    {:ok, matches_supervisor} = Task.Supervisor.start_link()

    # TODO: 2024-06-20 - Send Pub/Sub message that tournament was started

    start_next_round(tournament, matches_supervisor, tournament_rounds)
  end

  defp check_and_resume_tournament(tournament) do
    {:ok, matches_supervisor} = Task.Supervisor.start_link()

    participant_count = Tournaments.get_participant_count(tournament.id)
    match_count = Matches.count_matches_in_tournament(tournament.id)

    rounds_to_play = participant_count - 1

    if rounds_to_play * participant_count / 2 == match_count do
      # Correct number of Matches are found - continue tournament
      round_no = Matches.determine_current_tournament_round(tournament.id)
      start_next_round(tournament, matches_supervisor, Enum.to_list(round_no..rounds_to_play))
    else
      # Tournament crashed while generating matches. Clean up and redo!
      Matches.delete_all_matches_of_tournament(tournament.id)

      tournament_rounds = Tournaments.create_round_robin_schedule(tournament)
      start_next_round(tournament, matches_supervisor, tournament_rounds)
    end
  end

  defp start_next_round(tournament, matches_supervisor, [round_no | more_rounds]) do
    # Recompute preliminary score and ranking
    Tournaments.compute_participant_scores(tournament.id)
    Tournaments.compute_participant_ranking(tournament.id)
    # TODO: 2024-06-20 - send Pub/Sub message of completed round

    tournament.id
    |> Matches.get_open_or_started_matches_for_tournament_round(round_no)
    |> start_matches(matches_supervisor)
    |> wait_for_matches(tournament, matches_supervisor, more_rounds)
  end

  defp start_next_round(tournament, matches_supervisor, []) do
    # No more rounds to play, tournament finished.
    Supervisor.stop(matches_supervisor)

    Tournaments.set_participations_to_done(tournament.id)
    Tournaments.compute_participant_scores(tournament.id)
    Tournaments.compute_participant_ranking(tournament.id)

    Tournaments.finish_tournament(tournament)

    # TODO: 2024-06-15 - Sent Pub/Sub message when Tournament is finished!
  end

  defp wait_for_matches([], tournament, matches_supervisor, more_rounds) do
    start_next_round(tournament, matches_supervisor, more_rounds)
  end

  defp wait_for_matches(running_matches, tournament, matches_supervisor, more_rounds) do
    timeout = compute_tournament_round_timeout(tournament)

    receive do
      {:match_finished, match} ->
        remaining_matches = Enum.filter(running_matches, fn m -> m != match.id end)

        case match.status do
          :finished ->
            wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)

          :aborted ->
            handle_aborted_match(match, tournament)
            wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)

          other ->
            Logger.warning("Received :match_finished for match in status #{other}.")
            wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)
        end

      message ->
        Logger.warning(
          "Tournament.Runner for tournament #{tournament.id} received unexpected message #{inspect(message)}"
        )

        wait_for_matches(running_matches, tournament, matches_supervisor, more_rounds)
    after
      # Messages can get lost. For those edge-cases we resort to the database
      # as the source of truth and resume operations from tere
      # The timeout is the maximum time a match can theoertically run, given
      # the possible timeouts for each match round
      timeout ->
        Logger.warning(
          "Tournament.Runner for tournament #{tournament.id} waited for matches to report back for #{timeout} ms. Checking DB."
        )

        remaining_matches = check_for_stalled_matches(running_matches, tournament)
        wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)
    end
  end

  defp check_for_stalled_matches(running_matches, tournament) do
    matches = Matches.list_matches_by_ids(running_matches)
    matches_by_status = Enum.group_by(matches, fn match -> match.status end)

    # We need to handle all the aborted matches
    Enum.each(matches_by_status.aborted, fn match ->
      handle_aborted_match(match, tournament)
    end)

    # Return the matches that could potentially still report back
    matches_by_status.open ++ matches_by_status.running
  end

  defp handle_aborted_match(match, tournament) do
    # TODO: 2024-07-31 - Ensure that all those operations are idempotent
    errored_agents = determine_errored_agents(match)
    Matches.cancel_open_matches_for_errored_agents(errored_agents, tournament)
    Matches.invalidate_past_matches_for_errored_agents(errored_agents, tournament)
    Tournaments.set_participation_to_error_for_errored_agents(errored_agents, tournament)
  end

  defp start_matches(matches, matches_supervisor) do
    errors =
      Enum.map(matches, fn match ->
        Matches.Runner.start(matches_supervisor, [match, self()])
      end)
      |> Enum.filter(fn {status, _} -> status == :error end)

    if errors == [] do
      matches
    else
      errors
    end
  end

  def determine_errored_agents(match) do
    agent_a = Agents.get_agent!(match.agent_a_id)
    agent_b = Agents.get_agent!(match.agent_b_id)

    %Agent{status: status_a} = agent_a
    %Agent{status: status_b} = agent_b

    case {status_a, status_b} do
      {:error, :error} ->
        [agent_a, agent_b]

      {:error, _} ->
        [agent_a]

      {_, :error} ->
        [agent_b]
    end
  end

  def compute_tournament_round_timeout(tournament) do
    Agents.ConnectionManager.compute_timeout() * tournament.rounds_per_match
  end
end
