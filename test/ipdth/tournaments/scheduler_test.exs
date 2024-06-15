defmodule Ipdth.Tournaments.SchedulerTest do
  use Ipdth.DataCase
  use ExUnitProperties

  alias Ipdth.Tournaments.Scheduler

  describe "tournaments/scheduler" do
    property "create_schedule/1 returns correctly generated schedules" do
      check all players <- uniq_list_of(atom(:alphanumeric), min_length: 2) do
        player_count = Enum.count(players)
        byes_needed = rem(player_count, 2)

        schedule = Scheduler.create_schedule(players)
        no_of_rounds = Enum.count(Map.keys(schedule))

        assert no_of_rounds == player_count - 1

        Enum.each(schedule, fn {round_no, round} ->
          Enum.each(players, fn player ->
            occurrence = Enum.count(round, fn {a, b} -> a == player || b == player end)
            message = "player #{player} occurs #{occurrence} times in round #{round_no}"
            assert occurrence == 1, message

            byes_count = Enum.count(round, fn {a, b} -> a == :bye || b == :bye end)
            message = "found :bye #{byes_count} times in round #{round_no} but needed #{byes_needed}"
            assert byes_count == byes_needed, message
          end)
        end)
      end
    end
  end
end
