defmodule Ipdth.Tournaments.Scheduler do

  def create_schedule(players) do
    player_count = Enum.count(players)
    split_idx = ceil(player_count/2)
    round_count = player_count - 1

    schedule_round(players, split_idx, 0, round_count, %{})
  end

  defp schedule_round(players, split_idx, round_no, round_count, rounds) when round_no < round_count do
    even_players =
      if rem(round_count, 2) == 0 do
        players ++ [:bye]
      else
        players
      end

    schedule =
      even_players
      |> Enum.split(split_idx)
      |> Tuple.to_list()
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
