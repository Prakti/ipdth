defmodule Ipdth.Tournaments.Runner do

  alias Ipdth.Matches.Match

  def report_finished_match(runner_pid, %Match{} = match) do
    Process.send(runner_pid, {:match_finished, match}, [])
  end
end
