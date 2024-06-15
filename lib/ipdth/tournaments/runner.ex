defmodule Ipdth.Tournaments.Runner do

  import Ecto.Query, warn: false

  alias Ipdth.Repo
  alias Ipdth.Matches
  alias Ipdth.Matches.Match
  alias Ipdth.Tournaments.{Tournament, Participation, Scheduler}

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

    update_status(tournament)
    create_round_robin_schedule(tournament)

    :ok
  end

  defp update_status(tournament) do
    Repo.transaction(fn ->
      tournament
      |> Ecto.Changeset.change(status: :running)
      |> Repo.update!()

     Participation
      |> where([p], p.tournament_id == ^tournament.id)
      |> Repo.update_all(set: [status: :participating])

    end)
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
      Repo.insert_all(Match, matches)
    end)
  end

  def report_finished_match(runner_pid, %Match{} = match) do
    Process.send(runner_pid, {:match_finished, match}, [])
  end

end
