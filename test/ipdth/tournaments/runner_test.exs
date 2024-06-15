defmodule Ipdth.Tournaments.RunnerTest do
  use Ipdth.DataCase

  import Ecto.Query, warn: false

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures
  import Ipdth.MatchesFixtures

  alias Ipdth.Repo
  alias Ipdth.Tournaments.Runner
  alias Ipdth.Tournaments.Participation

  alias Ipdth.Matches.Match

  describe "tournaments/runner" do

    test "run/1 computes correct matches for even number of participants" do
      admin_user = admin_user_fixture()
      %{agents: agents} =
          multiple_activated_agents_one_bypass_fixture(admin_user, 10)
      %{tournament: tournament, participations: participations} =
          published_tournament_with_participants_fixture(admin_user.id, agents)

      assert Enum.count(agents) == Enum.count(participations)

      Runner.run(tournament)

      Enum.each(participations, fn participation ->
        query =
          from m in Match,
            where: m.tournament_id == ^participation.tournament_id,
            where: m.agent_a_id == ^participation.agent_id or m.agent_b_id == ^participation.agent_id,
            select: count(m.id)

        # Each agent must play once against the others
        assert Repo.one(query) == Enum.count(agents) - 1
      end)

      # There must be no match where agent_a has no participation record
      query =
        from m in Match,
          left_join: p in Participation,
          on: p.tournament_id == m.tournament_id and p.agent_id == m.agent_a_id,
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

    end
  end
end
