defmodule Ipdth.Tournaments.ManagerTest do
  use Ipdth.DataCase

  import Ecto.Query, warn: false

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures

  alias Ipdth.Tournaments
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
        #get_tournaments: &Tournaments.list_due_and_overdue_tournaments/1,
        get_tournaments: get_tournaments,
        start_tournament: start_tournament,
      }

      Manager.handle_cast({:check_and_start_tournaments, ts_now}, state)

      assert_receive :trigger_check, 2_000

    end
  end

end
