defmodule Ipdth.MatchesTest do
  use Ipdth.DataCase

  alias Ipdth.Matches
  alias Ipdth.Matches.Match

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures
  import Ipdth.MatchesFixtures

  describe "matches" do

    test "list_matches/0 returns all matches" do
      admin_user = admin_user_fixture()
      agent_a = agent_fixture(admin_user)
      agent_b = agent_fixture(admin_user)
      tournament = published_tournament_fixture(admin_user.id)
      match = match_fixture(agent_a, agent_b, tournament, 1)

      match = Matches.get_match!(match.id)

      assert Matches.list_matches() == [match]
    end

    test "get_match!/1 returns the match with given id" do
      admin_user = admin_user_fixture()
      agent_a = agent_fixture(admin_user)
      agent_b = agent_fixture(admin_user)
      tournament = published_tournament_fixture(admin_user.id)

      match = match_fixture(agent_a, agent_b, tournament, 1)

      assert Matches.get_match!(match.id, [:agent_a, :agent_b, :tournament]) == match
    end

    test "create_match/1 with valid data creates a match" do
      admin_user = admin_user_fixture()
      agent_a = agent_fixture(admin_user)
      agent_b = agent_fixture(admin_user)
      tournament = published_tournament_fixture(admin_user.id)

      {:ok, match} = Matches.create_match(agent_a, agent_b, tournament, 1)

      assert Matches.get_match!(match.id, [:agent_a, :agent_b, :tournament]) == match
    end

    test "delete_match/1 deletes the match" do
      admin_user = admin_user_fixture()
      agent_a = agent_fixture(admin_user)
      agent_b = agent_fixture(admin_user)
      tournament = published_tournament_fixture(admin_user.id)
      match = match_fixture(agent_a, agent_b, tournament, 1)

      assert {:ok, %Match{}} = Matches.delete_match(match)
      assert_raise Ecto.NoResultsError, fn -> Matches.get_match!(match.id) end
    end

  end
end
