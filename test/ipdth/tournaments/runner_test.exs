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

  describe "run/1" do
    test "correctly runs a tournament for an even number of participants" do
      admin_user = admin_user_fixture()

      %{agents: agents} =
        multiple_activated_agents_one_bypass_fixture(admin_user, 10)

      %{tournament: tournament, participations: participations} =
        published_tournament_with_participants_fixture(admin_user.id, agents, %{
          rounds_per_match: 10
        })

      participant_count = Enum.count(participations)
      assert Enum.count(agents) == participant_count

      matches_to_play_each = participant_count - 1

      # -------------------------------------------------#
      #      vvv----- Actual Test Call happens here     #
      Runner.run(tournament)

      # -------------------------------------------------#
      # Here we stat veryfying all the Post-Conditions  #
      tournament = Repo.get!(Tournament, tournament.id)

      assert :finished == tournament.status

      # Each agent should have played once against the others
      Enum.each(participations, fn participation ->
        query =
          from m in Match,
            where: m.tournament_id == ^participation.tournament_id,
            where:
              m.agent_a_id == ^participation.agent_id or
                m.agent_b_id == ^participation.agent_id,
            select: count(m.id)

        assert Repo.one(query) == matches_to_play_each
      end)

      # There must be no match where agent_a has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on:
            p.tournament_id == m.tournament_id and
              p.agent_id == m.agent_a_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)

      assert Repo.one(query) == 0

      # There must be no match where agent_b has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on: p.tournament_id == m.tournament_id and p.agent_id == m.agent_b_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)

      assert Repo.one(query) == 0

      # Check if the matches were all successful
      query =
        from m in Match,
          where: m.tournament_id == ^tournament.id,
          where: m.status == :finished,
          select: count(m.id)

      match_count = participant_count * matches_to_play_each / 2
      assert Repo.one(query) == match_count
      # assert Repo.one(query) == 45

      query =
        from p in Participation,
          where: p.tournament_id == ^tournament.id,
          select: p

      # All Agents cooperate so each gets 3 points in ever round every match
      expected_score = 3 * tournament.rounds_per_match * matches_to_play_each

      participations = Repo.all(query)

      Enum.each(participations, fn p ->
        # All agents should have same score
        assert expected_score == p.score
        # All agents should be tied for 1st rank
        assert 1 == p.ranking
        assert :done == p.status
      end)
    end

    test "correctly runs a tournament for an odd number of participants" do
      admin_user = admin_user_fixture()

      %{agents: agents} =
        multiple_activated_agents_one_bypass_fixture(admin_user, 9)

      %{tournament: tournament, participations: participations} =
        published_tournament_with_participants_fixture(admin_user.id, agents, %{
          rounds_per_match: 10
        })

      participant_count = Enum.count(participations)
      assert Enum.count(agents) == participant_count

      matches_to_play_each = participant_count - 1

      # -------------------------------------------------#
      #      vvv----- Actual Test Call happens here     #
      Runner.run(tournament)

      # -------------------------------------------------#
      # Here we stat veryfying all the Post-Conditions  #
      tournament = Repo.get!(Tournament, tournament.id)

      assert :finished == tournament.status

      # Each agent should have played once against the others
      Enum.each(participations, fn participation ->
        query =
          from m in Match,
            where: m.tournament_id == ^participation.tournament_id,
            where:
              m.agent_a_id == ^participation.agent_id or
                m.agent_b_id == ^participation.agent_id,
            select: count(m.id)

        assert Repo.one(query) == matches_to_play_each
      end)

      # There must be no match where agent_a has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on:
            p.tournament_id == m.tournament_id and
              p.agent_id == m.agent_a_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)

      assert Repo.one(query) == 0

      # There must be no match where agent_b has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on: p.tournament_id == m.tournament_id and p.agent_id == m.agent_b_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)

      assert Repo.one(query) == 0

      # Check if the matches were all successful
      query =
        from m in Match,
          where: m.tournament_id == ^tournament.id,
          where: m.status == :finished,
          select: count(m.id)

      match_count = participant_count * matches_to_play_each / 2
      assert Repo.one(query) == match_count

      query =
        from p in Participation,
          where: p.tournament_id == ^tournament.id,
          select: p

      # All Agents cooperate so each gets 3 points in ever round every match
      expected_score = 3 * tournament.rounds_per_match * matches_to_play_each

      participations = Repo.all(query)

      Enum.each(participations, fn p ->
        # All agents should have same score
        assert expected_score == p.score
        # All agents should be tied for 1st rank
        assert 1 == p.ranking
        assert :done == p.status
      end)
    end

    @tag silence_logger: true
    test "invalidates matches of failing agents" do
      admin_user = admin_user_fixture()

      %{agents: agents} =
        multiple_activated_agents_one_bypass_fixture(admin_user, 9)

      %{agent: error_agent, bypass: bypass} =
        agent_fixture_and_mock_service(admin_user)

      # Mix the error_agent into all the others:
      agents = [error_agent | Enum.to_list(agents)]

      %{tournament: tournament, participations: participations} =
        published_tournament_with_participants_fixture(admin_user.id, agents, %{
          rounds_per_match: 10
        })

      # Set up an Agent to fail in the third tournament round.
      # An Agent plays 10 Rounds per match, 1 match per tournament round
      # -> Fail in third tournament round: after 20-29 match rounds
      # -> Our pick: 25

      # Set up a Shelf (Elixir Agent) for storing some State
      {:ok, shelf} = Shelf.start_link(fn -> 0 end)

      Bypass.stub(bypass, "POST", "/decide", fn conn ->
        match_round =
          Shelf.get_and_update(shelf, fn round ->
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
          where:
            m.agent_a_id == ^error_agent.id or
              m.agent_b_id == ^error_agent.id,
          where: m.status == :aborted,
          select: count(m.id)

      assert Repo.one(query) == 1

      # All the other matches of that agent should be :ivalidated or cancelled
      # The error agent failed after two matches so 2 matches :invalidated and
      # 2 :cancelled
      query =
        from m in Match,
          where: m.tournament_id == ^tournament.id,
          where:
            m.agent_a_id == ^error_agent.id or
              m.agent_b_id == ^error_agent.id,
          where: m.status == :invalidated,
          select: count(m.id)

      assert Repo.one(query) == 2

      query =
        from m in Match,
          where: m.tournament_id == ^tournament.id,
          where:
            m.agent_a_id == ^error_agent.id or
              m.agent_b_id == ^error_agent.id,
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
      assert nil == error_participation.ranking
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
      expected_score = 3 * tournament.rounds_per_match * finished_matches_each

      participations = Repo.all(query)

      Enum.each(participations, fn p ->
        # All other agents should have same score
        assert expected_score == p.score
        # All other agents should be tied for 1st rank
        assert 1 == p.ranking
        assert :done == p.status
      end)
    end

    test "computes correct scores and ranking" do
      admin_user = admin_user_fixture()

      # Create tournament with three agents and two rounds
      # Agent 1 -> Defects always -> Rank 1 -> Score 16
      # Agent 2 -> Defects in round 2 -> Rank 2 -> Score 9
      # Agent 3 -> Cooperates always -> Ranke 3 -> Score 3
      {agents, _} =
        Enum.map(0..2, fn num ->
          %{agent: agent, bypass: bypass} =
            agent_fixture_and_mock_service(admin_user)

          # Set up a Shelf (Elixir Agent) for storing some State
          {:ok, shelf} = Shelf.start_link(fn -> 0 end)

          Bypass.stub(bypass, "POST", "/decide", fn conn ->
            match_round =
              Shelf.get_and_update(shelf, fn round ->
                {round, rem(round + 1, 2)}
              end)

            action = if num <= match_round, do: :defect, else: :cooperate

            if action == :defect do
              conn
              |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
              |> Plug.Conn.resp(200, agent_defect_reponse())
            else
              conn
              |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
              |> Plug.Conn.resp(200, agent_cooperate_reponse())
            end
          end)

          {agent, bypass}
        end)
        |> Enum.unzip()

      %{tournament: tournament, participations: participations} =
        published_tournament_with_participants_fixture(admin_user.id, agents, %{
          rounds_per_match: 2
        })

      participant_count = Enum.count(participations)
      assert Enum.count(agents) == participant_count

      Runner.run(tournament)

      Enum.with_index(agents)
      |> Enum.each(fn {agent, idx} ->
        query =
          from p in Participation,
            where: p.agent_id == ^agent.id,
            where: p.tournament_id == ^tournament.id,
            select: p

        participation = Repo.one(query)

        assert idx + 1 == participation.ranking

        case idx do
          0 -> assert 16 == participation.score
          1 -> assert 9 == participation.score
          2 -> assert 3 == participation.score
        end
      end)
    end

    @tag silence_logger: true
    test "can resume an interrupted tournament" do
      admin_user = admin_user_fixture()

      %{agents: agents, bypass: bypass} =
        multiple_agents_one_bypass_fixture(admin_user, 6)

      agents = Enum.to_list(agents)

      %{tournament: tournament, participations: participations} =
        published_tournament_with_participants_fixture(admin_user.id, agents, %{
          rounds_per_match: 10
        })

      participant_count = Enum.count(participations)
      assert Enum.count(agents) == participant_count

      matches_to_play_each = participant_count - 1

      # We set up the Bypass to kill the Process running the tournament after
      # the second tournament round; this translates to 3 * 6 * 10 = 180 calls
      # to the bypass since it is shared by all 6 agents

      # Set up a Shelf (Elixir Agent) for counting the calls to the Bypass
      {:ok, counter} = Shelf.start_link(fn -> 0 end)
      {:ok, runner} = Shelf.start_link(fn -> nil end)

      test_pid = self()

      Bypass.stub(bypass, "POST", "/decide", fn conn ->
        count =
          Shelf.get_and_update(counter, fn round ->
            {round, round + 1}
          end)

        if count == 180 do
          # Kill the Process running the tournament (stored in a shelf)
          Shelf.update(runner, fn pid ->
            Process.exit(pid, :kill)
            nil
          end)

          # Now that we have killed the Runner, we notify the test,
          # So it can restart it and perform checks
          send(test_pid, :killed)
        end

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      # We need to delay the start of the tournament, so we have time for
      # all the necessary preparations. We have to start the tournament in
      # a Task so we can kill the corresponding process
      {:ok, pid} =
        Task.start(fn ->
          receive do
            :start -> Runner.run(tournament)
          end
        end)

      # Store the runner-pid for later retrieval by the Bypass
      # see the Bypass setup above
      Shelf.update(runner, fn _ -> pid end)

      Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)

      # ---------------------------------------------------------------------#
      # Now the Tournament.Runner should start working until it gets killed
      send(pid, :start)

      # The Bypass will send us a message once it killed the Runner
      receive do
        # For now: restart the tournament and see if it completes
        :killed -> Runner.run(tournament)
      end

      # -------------------------------------------------#
      # Here we stat veryfying all the Post-Conditions  #
      tournament = Repo.get!(Tournament, tournament.id)

      assert :finished == tournament.status

      # Each agent should have played once against the others
      Enum.each(participations, fn participation ->
        query =
          from m in Match,
            where: m.tournament_id == ^participation.tournament_id,
            where:
              m.agent_a_id == ^participation.agent_id or
                m.agent_b_id == ^participation.agent_id,
            select: count(m.id)

        assert Repo.one(query) == matches_to_play_each
      end)

      # There must be no match where agent_a has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on:
            p.tournament_id == m.tournament_id and
              p.agent_id == m.agent_a_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)

      assert Repo.one(query) == 0

      # There must be no match where agent_b has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on: p.tournament_id == m.tournament_id and p.agent_id == m.agent_b_id,
          where: m.tournament_id == ^tournament.id,
          where: is_nil(p.id),
          select: count(m.id)

      assert Repo.one(query) == 0

      # Check if the matches were all successful
      query =
        from m in Match,
          where: m.tournament_id == ^tournament.id,
          where: m.status == :finished,
          select: count(m.id)

      match_count = participant_count * matches_to_play_each / 2
      assert Repo.one(query) == match_count

      query =
        from p in Participation,
          where: p.tournament_id == ^tournament.id,
          select: p

      # All Agents cooperate so each gets 3 points in ever round every match
      expected_score = 3 * tournament.rounds_per_match * matches_to_play_each

      participations = Repo.all(query)

      Enum.each(participations, fn p ->
        # All agents should have same score
        assert expected_score == p.score
        # All agents should be tied for 1st rank
        assert 1 == p.ranking
        assert :done == p.status
      end)
    end
  end
end
