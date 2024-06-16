defmodule Ipdth.Matches.RunnerTest do
  use Ipdth.DataCase

  alias Ipdth.Matches
  alias Ipdth.Matches.{Runner}

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures
  import Ipdth.MatchesFixtures

  describe "matches/runner" do
    test "run/2 successfully runs a match with two agents" do
      admin_user = admin_user_fixture()
      %{agent: agent_a, bypass: bypass_a} = agent_fixture_and_mock_service(admin_user)

      Bypass.expect(bypass_a, "POST", "/decide", fn conn ->
        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      %{agent: agent_b, bypass: bypass_b} = agent_fixture_and_mock_service(admin_user)

      Bypass.expect(bypass_b, "POST", "/decide", fn conn ->
        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      tournament = published_tournament_fixture(admin_user.id)
      match = match_fixture(agent_a, agent_b, tournament, 1, 5)

      Runner.run(match, self())

      assert_receive {:match_finished, finished_match}

      assert finished_match.id == match.id
      assert finished_match.status == :finished

      match = Matches.get_match!(match.id, [:rounds])
      assert match.rounds_to_play == Enum.count(match.rounds)

      # Both Agents cooperate always -> 3 points per round
      assert match.score_a == 3 * match.rounds_to_play
      assert match.score_b == 3 * match.rounds_to_play
    end

    @tag silence_logger: true
    test "run/2 aborts a match with one failing agent" do
      admin_user = admin_user_fixture()
      %{agent: agent_a, bypass: bypass_a} = agent_fixture_and_mock_service(admin_user)

      Bypass.expect(bypass_a, "POST", "/decide", fn conn ->
        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      %{agent: agent_b, bypass: bypass_b} = agent_fixture_and_mock_service(admin_user)

      Bypass.expect(bypass_b, "POST", "/decide", fn conn ->
        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(500, agent_service_500_response())
      end)

      tournament = published_tournament_fixture(admin_user.id)
      match = match_fixture(agent_a, agent_b, tournament, 1, 1)

      Runner.run(match, self())

      assert_receive {:match_finished, finished_match}

      assert finished_match.id == match.id
      assert finished_match.status == :aborted
    end
  end

end
