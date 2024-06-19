defmodule Ipdth.Tournaments.RunnerTest do
  use Ipdth.DataCase

  import Ecto.Query, warn: false

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures

  alias Agent, as: Shelf

  alias Ipdth.Repo
  alias Ipdth.Tournaments.{Runner, Tournament}
  alias Ipdth.Tournaments.Participation

  alias Ipdth.Matches.Match

  describe "tournaments/runner" do

    test "run/1 correctly runs a tournament for even number of participants" do
      admin_user = admin_user_fixture()
      %{agents: agents} =
          multiple_activated_agents_one_bypass_fixture(admin_user, 10)
      %{tournament: tournament, participations: participations} =
          published_tournament_with_participants_fixture(admin_user.id, agents, %{round_number: 10})

      participant_count = Enum.count(participations)
      assert Enum.count(agents) == participant_count

      matches_to_play_each = participant_count - 1

      # vvvv----- Actual Test Call happens here
      Runner.run(tournament)

      # vvvv----- Veryfiy Post-Conditions
      tournament = Repo.get!(Tournament, tournament.id)

      assert :finished == tournament.status

      # Each agent should have played once against the others
      Enum.each(participations, fn participation ->
        query =
          from m in Match,
            where: m.tournament_id == ^participation.tournament_id,
            where: m.agent_a_id == ^participation.agent_id
                or m.agent_b_id == ^participation.agent_id,
            select: count(m.id)

        assert Repo.one(query) == matches_to_play_each
      end)

      # There must be no match where agent_a has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on: p.tournament_id == m.tournament_id
          and p.agent_id == m.agent_a_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)
      assert Repo.one(query)  == 0

      # There must be no match where agent_b has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
            on: p.tournament_id == m.tournament_id and p.agent_id == m.agent_b_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)
      assert Repo.one(query)  == 0

      # Check if the matches were all successful
      query =
        from m in Match,
        where: m.tournament_id == ^tournament.id,
        where: m.status == :finished,
        select: count(m.id)
      assert Repo.one(query) == 45

      query =
        from p in Participation,
        where: p.tournament_id == ^tournament.id,
        select: p

      # All Agents cooperate so each gets 3 points in ever round every match
      expected_score = 3 * tournament.round_number * matches_to_play_each

      participations = Repo.all(query)
      Enum.each(participations, fn p ->
        assert expected_score == p.score # All agents should have same score
        assert 1 == p.ranking # All agents should be tied for 1st rank
        assert :done == p.status
      end)
    end

    @tag silence_logger: true
    test "run/1 invalidates matches of failing agents" do
      admin_user = admin_user_fixture()
      %{agents: agents} =
        multiple_activated_agents_one_bypass_fixture(admin_user, 9)
      %{agent: error_agent, bypass: bypass} =
        agent_fixture_and_mock_service(admin_user)

      # Mix the error_agent into all the others:
      agents = [error_agent | Enum.to_list(agents)]

      %{tournament: tournament, participations: participations} =
        published_tournament_with_participants_fixture(admin_user.id, agents, %{round_number: 10})

      # Set up an Agent to fail in the third tournament round.
      # An Agent plays 10 Rounds per match, 1 match per tournament round
      # -> Fail in third tournament round: after 20-29 match rounds
      # -> Our pick: 25

      # Set up a Shelf (Elixir Agent) for storing some State
      {:ok, shelf} = Shelf.start_link(fn -> 0 end)

      Bypass.stub(bypass, "POST", "/decide", fn conn ->
        match_round = Shelf.get_and_update(shelf, fn round ->
         {round, round + 1}
        end)

        if match_round < 25 do
          conn
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
          |> Plug.Conn.resp(200, agent_service_success_response())
        else
          conn
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
          |> Plug.Conn.resp(500, agent_service_500_response())
        end
      end)

      participant_count = Enum.count(participations)
      assert Enum.count(agents) == participant_count

      matches_to_play_each = participant_count - 1

      # vvvv----- Actual Test Call happens here
      Runner.run(tournament)

      # vvvv----- Veryfiy Post-Conditions
      tournament = Repo.get!(Tournament, tournament.id)

      assert :finished == tournament.status

      # There should be one match that is in :aborted state
      query =
        from m in Match,
        where: m.tournament_id == ^tournament.id,
        where: m.agent_a_id == ^error_agent.id
            or m.agent_b_id == ^error_agent.id,
        where: m.status == :aborted,
        select: count(m.id)
      assert Repo.one(query) == 1

      # All the other matches of that agent should be :ivalidated or cancelled
      # The error agent failed after two matches so 2 matches :invalidated and
      # 2 :cancelled
      query =
        from m in Match,
        where: m.tournament_id == ^tournament.id,
        where: m.agent_a_id == ^error_agent.id
            or m.agent_b_id == ^error_agent.id,
        where: m.status == :invalidated,
        select: count(m.id)
      assert Repo.one(query) == 2

      query =
        from m in Match,
        where: m.tournament_id == ^tournament.id,
        where: m.agent_a_id == ^error_agent.id
            or m.agent_b_id == ^error_agent.id,
        where: m.status == :cancelled,
        select: count(m.id)
      assert Repo.one(query) == 6

      # All the other matches should be successful
      query =
        from m in Match,
        where: m.tournament_id == ^tournament.id,
        where: m.agent_a_id != ^error_agent.id,
        where: m.agent_b_id != ^error_agent.id,
        where: m.status == :finished,
        select: count(m.id)
      assert Repo.one(query) == 36

      # Errored Agent should have tournament score of 0
      query =
        from p in Participation,
        where: p.tournament_id == ^tournament.id,
        where: p.agent_id == ^error_agent.id,
        select: p

      error_participation = Repo.one(query)
      assert nil == error_participation.score
      assert 10 == error_participation.ranking
      assert :error == error_participation.status

      # All check scores of all other agents
      query =
        from p in Participation,
        where: p.tournament_id == ^tournament.id,
        where: p.agent_id != ^error_agent.id,
        select: p

      # All agents finish with one less match that counts
      finished_matches_each = matches_to_play_each - 1

      # All Agents cooperate so each gets 3 points in ever round every match
      expected_score = 3 * tournament.round_number * finished_matches_each

      participations = Repo.all(query)
      Enum.each(participations, fn p ->
        assert expected_score == p.score # All agents should have same score
        assert 1 == p.ranking # All agents should be tied for 1st rank
        assert :done == p.status
      end)
    end
  end
end
