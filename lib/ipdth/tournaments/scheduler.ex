defmodule Ipdth.Tournaments.Scheduler do
  @moduledoc """
  This module calculates a round-robin schedule for a tournament.
  It is mostly used by the Tournaments.Runner module at startup of a
  tournament. We have extracted the functionality for testing purposes.
  """

  def create_schedule(players) do
    even_players =
      if rem(Enum.count(players), 2) == 1 do
        players ++ [:bye]
      else
        players
      end

    player_count = Enum.count(even_players)
    split_idx = div(player_count, 2)
    round_count = player_count - 1

    schedule_round(even_players, split_idx, 0, round_count, %{})
  end

  defp schedule_round(players, split_idx, round_no, round_count, rounds)
       when round_no < round_count do
    schedule =
      players
      |> Enum.split(split_idx)
      |> then(fn {left, right} -> [left, Enum.reverse(right)] end)
      |> Enum.zip()

    [pivot | other] = players
    updated_rounds = Map.put(rounds, round_no, schedule)
    updated_other = Enum.slide(other, 0, -1)
    schedule_round([pivot | updated_other], split_idx, round_no + 1, round_count, updated_rounds)
  end

  defp schedule_round(_, _, _, _, rounds) do
    rounds
  end
end
