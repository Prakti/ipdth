defmodule Ipdth.Tournaments.ManagerTest do
  use ExUnit.Case, async: true

  alias Ipdth.Tournaments.Manager

  describe "tournaments/manager" do
    test "correctly handles :check_and_start_tournaments message to itself" do
      fake_tournaments = [:a, :b, :c, :d]
      ts_now = DateTime.utc_now()

      get_tournaments = fn timestamp ->
        assert ts_now == timestamp
        fake_tournaments
      end

      start_tournament = fn tournament ->
        assert Enum.member?(fake_tournaments, tournament)
      end

      state = %Manager.State{
        auto_mode: true,
        # get_tournaments: &Tournaments.list_due_and_overdue_tournaments/1,
        get_tournaments: get_tournaments,
        start_tournament: start_tournament
      }

      Manager.handle_cast({:check_and_start_tournaments, ts_now}, state)

      assert_receive :trigger_check, 2_000
    end

    test "checks and starts tournaments in the expected interval" do
      test_pid = self()

      get_tournaments = fn timestamp ->
        send(test_pid, {:get_tournaments, timestamp})
        [timestamp]
      end

      # Here we check that the retrieved tournaments are also correctly
      # handed over to the start function, by hadning over the timestamp.
      # In our assertions we compare the timestamps
      start_tournament = fn timestamp ->
        send(test_pid, {:start_tournaments, timestamp})
        {:ok, timestamp}
      end

      config = [
        auto_mode: true,
        get_tournaments: get_tournaments,
        start_tournament: start_tournament,
        check_interval: 500
      ]

      {:ok, _} = Manager.start_link(config, :manager_test)

      assert_receive {:get_tournaments, timestamp}, 600
      assert_receive {:start_tournaments, ^timestamp}, 600

      # Also check that the check and start is triggered regularly
      for _ <- 1..10 do
        assert_receive {:get_tournaments, timestamp}, 600
        assert_receive {:start_tournaments, ^timestamp}, 600
      end
    end
  end
end
