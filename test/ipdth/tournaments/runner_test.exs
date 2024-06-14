defmodule Ipdth.Tournaments.RunnerTest do
  use Ipdth.DataCase

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures
  import Ipdth.MatchesFixtures

  describe "tournaments/runner" do

    test "" do
      admin_user = admin_user_fixture()
      agent_a = agent_fixture(admin_user)
      agent_b = agent_fixture(admin_user)
      tournament = published_tournament_fixture(admin_user.id)

      # TODO: finalize this

    end
  end
end
