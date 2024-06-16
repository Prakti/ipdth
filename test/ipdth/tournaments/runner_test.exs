defmodule Ipdth.Tournaments.RunnerTest do
  use Ipdth.DataCase

  import Ecto.Query, warn: false

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures
  import Ipdth.MatchesFixtures

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
      matches_to_play_total = matches_to_play_each * participant_count

      Runner.run(tournament)

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
  end
end
