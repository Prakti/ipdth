defmodule Ipdth.Tournaments.Runner do

  import Ecto.Query, warn: false

  require Logger

  alias Ipdth.Repo
  alias Ipdth.Agents
  alias Ipdth.Agents.Agent
  alias Ipdth.Matches
  alias Ipdth.Matches.Match
  alias Ipdth.Tournaments.{Tournament, Participation, Scheduler}

  # TODO: 2024-06-19 - Idea: register all Runners via name "Tournament.Runner-#ID"

  @supervisor_name Ipdth.Tournaments.Supervisor

  def supervisor_spec, do: {Task.Supervisor, name: @supervisor_name}

  def start(args) do
    Task.Supervisor.start_child(@supervisor_name, __MODULE__, :run,
                                args, restart: :transient)
  end

  def run(%Tournament{} = tournament), do: run(tournament.id)

  def run(tournament_id) do
    # Our runner might have crashed and been restarted.
    # We re-fetch the tournament from DB to avoid working on stale data
    tournament = Repo.get!(Tournament, tournament_id)

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
    update_status(tournament)
    tournament_rounds = create_round_robin_schedule(tournament)
    {:ok, matches_supervisor} = Task.Supervisor.start_link()

    start_next_round(tournament, matches_supervisor, tournament_rounds)
  end

  defp update_status(tournament) do
    Repo.transaction(fn ->
      tournament
      |> Tournament.start()
      |> Repo.update!()

     Participation
      |> where([p], p.tournament_id == ^tournament.id)
      |> Repo.update_all(set: [status: :participating])

    end)

    Repo.get!(Tournament, tournament.id)
  end

  defp create_round_robin_schedule(tournament) do
    agents = Repo.all(from p in Participation, where: p.tournament_id == ^tournament.id, select: p.agent_id)

    tournament_schedule = Scheduler.create_schedule(agents)

    Enum.each(tournament_schedule, fn {round_no, round_schedule} ->
      matches =
        round_schedule
        |> Enum.filter(fn {a, b} -> a != :bye and b != :bye end)
        |> Enum.map(fn {agent_a, agent_b} ->
          %{
            status: :open,
            agent_a_id: agent_a,
            agent_b_id: agent_b,
            tournament_id: tournament.id,
            tournament_round: round_no,
            rounds_to_play: tournament.round_number,
            inserted_at: NaiveDateTime.utc_now(:second),
            updated_at: NaiveDateTime.utc_now(:second)
          }
        end)

      Matches.create_multiple_matches(matches)
    end)

    Map.keys(tournament_schedule)
  end

  defp check_and_resume_tournament(tournament) do
    {:ok, matches_supervisor} = Task.Supervisor.start_link()

    query = from p in Participation,
            where: p.tournament_id == ^tournament.id,
            select: count(p.id)
    participant_count = Repo.one(query)

    query = from m in Match,
            where: m.tournament_id == ^tournament.id,
            select: count(m.id)
    match_count = Repo.one(query)

    rounds_to_play = ceil(participant_count / 2)

    if rounds_to_play * (participant_count - 1) == match_count do
      # Correct number of Matches are found - continue tournament

      # Determine in which round we crashed
      query = from m in Match,
              where: m.tournament_id == ^tournament.id,
              where: m.status == :open or m.status == :started,
              select: min(m.tournament_round)

      round_no = Repo.one(query)
      start_next_round(tournament, matches_supervisor, [round_no..rounds_to_play])
    else
      # Delete all matches associated with this tournament
      query = from m in Match,
              where: m.tournament_id == ^tournament.id,
              select: m

      Repo.delete_all(query)

      tournament_rounds = create_round_robin_schedule(tournament)
      start_next_round(tournament, matches_supervisor, tournament_rounds)
    end
  end

  defp start_next_round(tournament, matches_supervisor, [round_no | more_rounds]) do
    query = from m in Match,
            where: m.tournament_id == ^tournament.id,
            where: m.tournament_round == ^round_no,
            where: m.status == :open or m.status == :started,
            select: m.id

    round_matches = Repo.all(query)

    running_matches = start_matches(round_matches, matches_supervisor)
    wait_for_matches(running_matches, tournament, matches_supervisor, more_rounds)
  end

  defp start_next_round(tournament, matches_supervisor, []) do
    # No more rounds to play, tournament finished.
    Supervisor.stop(matches_supervisor)

    tournament
    |> set_parcicipations_to_done()
    |> compute_participant_scores()
    |> compute_tournament_rankings()
    |> Tournament.finish() |> Repo.update!()

    # TODO: 2024-06-15 - What else to do when tournament is finished? PubSub?
  end

  defp wait_for_matches([], tournament, matches_supervisor, more_rounds) do
    start_next_round(tournament, matches_supervisor, more_rounds)
  end

  defp wait_for_matches(running_matches, tournament, matches_supervisor, more_rounds) do
    receive do
      {:match_finished, match} ->
        remaining_matches = Enum.filter(running_matches, fn m -> m != match.id end)
        case match.status do
          :finished ->
            wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)
          :aborted ->
            determine_errored_agent(match)
            |> invalidate_past_matches_for_errored_agents(tournament)
            |> cancel_upcoming_matches_for_errored_agents(tournament)
            |> set_participation_to_error_for_errored_agents(tournament)

            wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)
          other ->
            Logger.warning("Received :match_finished for match in status #{other}.")
            wait_for_matches(remaining_matches, tournament, matches_supervisor, more_rounds)
        end

      message ->
        Logger.warning("Tournament.Runner for tournament #{tournament.id} received unexpected message #{inspect(message)}")
        wait_for_matches(running_matches, tournament, matches_supervisor, more_rounds)
    end
  end

  defp start_matches(matches, matches_supervisor) do
    Enum.map(matches, fn match ->
      {:ok, _} = Matches.Runner.start(matches_supervisor, [match, self()])
    end)
    matches
  end

  defp set_parcicipations_to_done(tournament) do
    query = from p in Participation,
            where: p.tournament_id == ^tournament.id,
            where: p.status == :participating
    Repo.update_all(query, set: [status: :done])

    # Return for pipelining
    tournament
  end

  def compute_participant_scores(tournament) do
    # TODO: 2024-06-19 - We're basically violating the context-boundary to matches here. We should refactor this.
    # TODO: 2024-06-19 - We need a distinction between the facade used by the Web-Layer / UI and internal Context API
    #                    Idea: Use main Ipdth module as Facade to Web-Layer and do permission checks there!
    #                    Then we can leave out permission checks from the internal contexts which is more consistent
    query_a = from p in Participation,
              join: m_a in Match, on: p.tournament_id == m_a.tournament_id
                                  and p.agent_id == m_a.agent_a_id,
              where: p.tournament_id == ^tournament.id,
              where: m_a.status == :finished,
              group_by: p.id,
              select: { p.id, sum(m_a.score_a) }

    query_b = from p in Participation,
              join: m_b in Match, on: p.tournament_id == m_b.tournament_id
                                  and p.agent_id == m_b.agent_b_id,
              where: p.tournament_id == ^tournament.id,
              where: m_b.status == :finished,
              group_by: p.id,
              select: { p.id, sum(m_b.score_b) }

    scores_a = Repo.all(query_a) |> Map.new()
    scores_b = Repo.all(query_b) |> Map.new()

    scores = Map.merge(scores_a, scores_b, fn _id, score_a, score_b ->
      score_a + score_b
    end)

    Repo.transaction(fn ->
      Enum.each(scores, fn {id, score} ->
        Repo.get!(Participation, id)
        |> Participation.update_score(score)
        |> Repo.update()
      end)
    end)

    # Return for pipelining
    tournament
  end

  def compute_tournament_rankings(tournament) do
    query = from p in Participation,
            where: p.tournament_id == ^tournament.id,
            select: {p.id, rank() |> over(order_by: p.score)}

    ranking = Repo.all(query)

    Repo.transaction(fn ->
      Enum.each(ranking, fn {id, rank} ->
        Repo.get!(Participation, id)
        |> Participation.set_rank(rank)
        |> Repo.update()
      end)
    end)

    # Return for pipelining
    tournament
  end

  def determine_errored_agent(match) do
    agent_a = Agents.get_agent!(match.agent_a_id)
    agent_b = Agents.get_agent!(match.agent_b_id)

    %Agent{ status: status_a } = agent_a
    %Agent{ status: status_b } = agent_b

    case {status_a, status_b} do
      {:error, :error} ->
        [agent_a, agent_b]
      {:error, _} ->
        [agent_a]
      {_, :error} ->
        [agent_b]
    end
  end

  def invalidate_past_matches_for_errored_agents(agents, tournament) do
    # TODO: 2024-06-19 - We're basically violating the context-boundary to matches here. We should refactor this.
    Repo.transaction(fn ->
      Enum.each(agents, fn agent ->
        query = from m in Match,
                where: m.tournament_id == ^tournament.id,
                where: m.agent_a_id == ^agent.id
                    or m.agent_b_id == ^agent.id,
                where: m.status == :finished,
                update: [set: [status: :invalidated]]
        Repo.update_all(query, [])
      end)
    end)

    # Return agents for pipelining
    agents
  end

  def cancel_upcoming_matches_for_errored_agents(agents, tournament) do
    # TODO: 2024-06-19 - We're basically violating the context-boundary to matches here. We should refactor this.
    Repo.transaction(fn ->
      Enum.each(agents, fn agent ->
        query = from m in Match,
                where: m.tournament_id == ^tournament.id,
                where: m.agent_a_id == ^agent.id
                    or m.agent_b_id == ^agent.id,
                where: m.status == :open,
                update: [set: [status: :cancelled]]
        Repo.update_all(query, [])
      end)
    end)

    # Return agents for pipelining
    agents
  end

  def set_participation_to_error_for_errored_agents(agents, tournament) do
    Repo.transaction(fn ->
      Enum.each(agents, fn agent ->
        Repo.get_by!(Participation, [tournament_id: tournament.id, agent_id: agent.id])
        |> Participation.set_to_error()
        |> Repo.update()
      end)
    end)
    # Return agents for pipelining
    agents
  end
end
