defmodule Ipdth.Tournaments.SchedulerTest do
  use Ipdth.DataCase
  use ExUnitProperties

  alias Ipdth.Tournaments.Scheduler

  describe "tournaments/scheduler" do
    test "create_schedule/1 returns correctly generated schedules with even number of players" do
      players = [:a, :b, :c, :d, :e, :f, :g, :h, :i, :k]
      player_count = Enum.count(players)
      byes_needed = rem(player_count, 2)

      schedule = Scheduler.create_schedule(players)
      no_of_rounds = Enum.count(Map.keys(schedule))

      assert no_of_rounds == player_count - 1

      Enum.reduce(schedule, %{}, fn {_, pairings}, outer_acc ->
        Enum.reduce(pairings, outer_acc, fn {a, b}, inner_acc ->
          pair = if a > b, do: {a, b}, else: {b, a}

          Map.update(inner_acc, pair, 1, fn count ->
            count + 1
          end)
        end)
      end)
      |> Enum.each(fn {pair, count} ->
        assert 1 == count, "Pair #{inspect(pair)} is scheduled #{count} times!"
      end)

      Enum.each(schedule, fn {round_no, round} ->
        Enum.each(players, fn player ->
          occurrence = Enum.count(round, fn {a, b} -> a == player || b == player end)
          message = "player #{player} occurs #{occurrence} times in round #{round_no}"
          assert occurrence == 1, message

          byes_count = Enum.count(round, fn {a, b} -> a == :bye || b == :bye end)

          message =
            "found :bye #{byes_count} times in round #{round_no} but needed #{byes_needed}"

          assert byes_count == byes_needed, message
        end)
      end)
    end

    test "create_schedule/1 returns correctly generated schedules with odd number of players" do
      players = [:a, :b, :c, :d, :e, :f, :g, :h, :i]
      player_count = Enum.count(players)
      byes_needed = rem(player_count, 2)

      schedule = Scheduler.create_schedule(players)
      no_of_rounds = Enum.count(Map.keys(schedule))

      assert no_of_rounds == player_count

      Enum.reduce(schedule, %{}, fn {_, pairings}, outer_acc ->
        Enum.reduce(pairings, outer_acc, fn {a, b}, inner_acc ->
          pair = if a > b, do: {a, b}, else: {b, a}

          Map.update(inner_acc, pair, 1, fn count ->
            count + 1
          end)
        end)
      end)
      |> Enum.each(fn {pair, count} ->
        assert 1 == count, "Pair #{inspect(pair)} is scheduled #{count} times!"
      end)

      Enum.each(schedule, fn {round_no, round} ->
        Enum.each(players, fn player ->
          occurrence = Enum.count(round, fn {a, b} -> a == player || b == player end)
          message = "player #{player} occurs #{occurrence} times in round #{round_no}"
          assert occurrence == 1, message

          byes_count = Enum.count(round, fn {a, b} -> a == :bye || b == :bye end)

          message =
            "found :bye #{byes_count} times in round #{round_no} but needed #{byes_needed}"

          assert byes_count == byes_needed, message
        end)
      end)
    end

    test "create_schedule/1 returns correctly generated schedules with three players" do
      players = [:a, :b, :c]
      player_count = Enum.count(players)
      byes_needed = rem(player_count, 2)

      schedule = Scheduler.create_schedule(players)
      no_of_rounds = Enum.count(Map.keys(schedule))

      assert no_of_rounds == player_count

      Enum.reduce(schedule, %{}, fn {_, pairings}, outer_acc ->
        Enum.reduce(pairings, outer_acc, fn {a, b}, inner_acc ->
          pair = if a > b, do: {a, b}, else: {b, a}

          Map.update(inner_acc, pair, 1, fn count ->
            count + 1
          end)
        end)
      end)
      |> Enum.each(fn {pair, count} ->
        assert 1 == count, "Pair #{inspect(pair)} is scheduled #{count} times!"
      end)

      Enum.each(schedule, fn {round_no, round} ->
        Enum.each(players, fn player ->
          occurrence = Enum.count(round, fn {a, b} -> a == player || b == player end)
          message = "player #{player} occurs #{occurrence} times in round #{round_no}"
          assert occurrence == 1, message

          byes_count = Enum.count(round, fn {a, b} -> a == :bye || b == :bye end)

          message =
            "found :bye #{byes_count} times in round #{round_no} but needed #{byes_needed}"

          assert byes_count == byes_needed, message
        end)
      end)
    end

    property "create_schedule/1 returns correctly generated schedules for arbitrary number of players" do
      check all(players <- uniq_list_of(atom(:alphanumeric), min_length: 2)) do
        player_count = Enum.count(players)
        byes_needed = rem(player_count, 2)

        schedule = Scheduler.create_schedule(players)
        no_of_rounds = Enum.count(Map.keys(schedule))

        if rem(player_count, 2) == 0 do
          assert no_of_rounds == player_count - 1
        else
          assert no_of_rounds == player_count
        end

        Enum.reduce(schedule, %{}, fn {_, pairings}, outer_acc ->
          Enum.reduce(pairings, outer_acc, fn {a, b}, inner_acc ->
            pair = if a > b, do: {a, b}, else: {b, a}

            Map.update(inner_acc, pair, 1, fn count ->
              count + 1
            end)
          end)
        end)
        |> Enum.each(fn {pair, count} ->
          assert 1 == count, "Pair #{inspect(pair)} is scheduled #{count} times!"
        end)

        Enum.each(schedule, fn {round_no, round} ->
          Enum.each(players, fn player ->
            occurrence = Enum.count(round, fn {a, b} -> a == player || b == player end)
            message = "player #{player} occurs #{occurrence} times in round #{round_no}"
            assert occurrence == 1, message

            byes_count = Enum.count(round, fn {a, b} -> a == :bye || b == :bye end)

            message =
              "found :bye #{byes_count} times in round #{round_no} but needed #{byes_needed}"

            assert byes_count == byes_needed, message
          end)
        end)
      end
    end
  end
end
