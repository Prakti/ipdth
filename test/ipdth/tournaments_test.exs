defmodule Ipdth.TournamentsTest do
  use Ipdth.DataCase

  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Tournament
  alias Ipdth.Tournaments.Participation

  import Ipdth.TournamentsFixtures
  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures

  # TODO: 2024-07-24 - Refactor to "describe fuction/arity" blocks

  describe "tournaments" do
    @invalid_attrs %{
      name: nil,
      status: nil,
      description: nil,
      start_date: nil,
      round_number: nil,
      random_seed: nil
    }

    test "list_tournaments/0 returns all tournaments for admins" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      assert Tournaments.list_tournaments(admin.id) == [tournament]
    end

    test "list_tournaments/0 returns no tournaments in status :created for anonymous users" do
      assert Tournaments.list_tournaments() == []
    end

    test "list_tournaments/0 returns no tournaments in status :created for normal users" do
      user = user_fixture()
      assert Tournaments.list_tournaments(user.id) == []
    end

    test "get_tournament!/1 returns the tournament with given id for an admin" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      assert Tournaments.get_tournament!(tournament.id, admin.id) == tournament
    end

    test "get_tournament!/1 does not return the tournament with given id for a normal user" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      user = user_fixture()
      assert nil == Tournaments.get_tournament!(tournament.id, user.id)
    end

    test "get_tournament!/1 does not return the tournament with given id for a anonymous user" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      assert nil == Tournaments.get_tournament!(tournament.id)
    end

    test "create_tournament/1 as an admin with valid data creates a tournament" do
      admin = admin_user_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        start_date: ~U[2024-01-20 12:56:00Z],
        round_number: 42,
        random_seed: "some random_seed"
      }

      assert {:ok, %Tournament{} = tournament} =
               Tournaments.create_tournament(valid_attrs, admin.id)

      assert tournament.name == "some name"
      assert tournament.status == :created
      assert tournament.description == "some description"
      assert tournament.start_date == ~U[2024-01-20 12:56:00.000000Z]
      assert tournament.round_number == 42
      assert tournament.random_seed == "some random_seed"
    end

    test "create_tournament/1 as a normal user fails with :not_authorized" do
      user = user_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        start_date: ~U[2024-01-20 12:56:00Z],
        round_number: 42,
        random_seed: "some random_seed"
      }

      assert {:error, :not_authorized} = Tournaments.create_tournament(valid_attrs, user.id)
    end

    test "create_tournament/1 with invalid data as an admin returns error changeset" do
      admin = admin_user_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs, admin.id)
    end

    test "publish_tournament/2 as an admin publishes the tournament" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      user = user_fixture()

      # normal and anon user cannot see created tournament!
      assert nil == Tournaments.get_tournament!(tournament.id, user.id)
      assert nil == Tournaments.get_tournament!(tournament.id)

      assert {:ok, tournament} = Tournaments.publish_tournament(tournament, admin.id)

      # normal and anon user can see published tournament!
      assert tournament == Tournaments.get_tournament!(tournament.id, user.id)
      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "publish_tournament/2 as a normal user fails" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      user = user_fixture()

      assert {:error, :not_authorized} = Tournaments.publish_tournament(tournament, user.id)
    end

    test "publish_tournament/2 is an idempotempt operation" do
      admin = admin_user_fixture()

      {:ok, tournament} =
        tournament_fixture(admin.id)
        |> Tournaments.publish_tournament(admin.id)

      assert {:ok, tournament} == Tournaments.publish_tournament(tournament, admin.id)
    end

    test "update_tournament/2 as an admin with valid data updates the tournament" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed"
      }

      assert {:ok, %Tournament{} = tournament} =
               Tournaments.update_tournament(tournament, update_attrs, admin.id)

      assert tournament.name == "some updated name"
      assert tournament.status == :created
      assert tournament.description == "some updated description"
      assert tournament.start_date == ~U[2024-01-21 12:56:00.000000Z]
      assert tournament.round_number == 43
      assert tournament.random_seed == "some updated random_seed"
    end

    test "update_tournament/2 fails if tournament is in state :running" do
      admin = admin_user_fixture()

      tournament =
        tournament_fixture(admin.id)
        |> Tournaments.set_tournament_to_started()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed"
      }

      assert {:error, :tournament_editing_locked} =
               Tournaments.update_tournament(tournament, update_attrs, admin.id)
    end

    test "update_tournament/2 fails if tournament is finished" do
      admin = admin_user_fixture()

      {:ok, tournament} =
        tournament_fixture(admin.id)
        |> Tournaments.finish_tournament()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed"
      }

      assert {:error, :tournament_editing_locked} =
               Tournaments.update_tournament(tournament, update_attrs, admin.id)
    end

    test "update_tournament/2 as a normal user with valid data fails with :not_authorized" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      user = user_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed"
      }

      assert {:error, :not_authorized} =
               Tournaments.update_tournament(tournament, update_attrs, user.id)
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)

      assert {:error, %Ecto.Changeset{}} =
               Tournaments.update_tournament(tournament, @invalid_attrs, admin.id)

      assert tournament == Tournaments.get_tournament!(tournament.id, admin.id)
    end

    test "delete_tournament/1 as an admin deletes the tournament" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament, admin.id)

      assert_raise Ecto.NoResultsError, fn ->
        Tournaments.get_tournament!(tournament.id, admin.id)
      end
    end

    test "delete_tournament/1 as a normal user fails with :not_authorized" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      user = user_fixture()
      assert {:error, :not_authorized} = Tournaments.delete_tournament(tournament, user.id)
      assert tournament == Tournaments.get_tournament!(tournament.id, admin.id)
    end

    test "change_tournament/1 returns a tournament changeset" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      assert %Ecto.Changeset{} = Tournaments.change_tournament(tournament)
    end
  end

  describe "participations" do
    test "sign_up/3 with valid tournament and agent creates a participation with status :signed_up" do
      admin = admin_user_fixture()
      tournament = published_tournament_fixture(admin.id)
      user = user_fixture()
      agent = activated_agent_fixture(user)

      tournament_id = tournament.id
      agent_id = agent.id

      assert {:ok,
              %Participation{
                status: :signed_up,
                tournament_id: ^tournament_id,
                agent_id: ^agent_id
              }} = Tournaments.sign_up(tournament, agent, user.id)
    end

    test "sign_off/3 with valid tournament and agent creates a participation with status :signed_up" do
      admin = admin_user_fixture()
      tournament = published_tournament_fixture(admin.id)
      user = user_fixture()
      agent = activated_agent_fixture(user)

      tournament_id = tournament.id
      agent_id = agent.id

      assert {:ok,
              %Participation{
                status: :signed_up,
                tournament_id: ^tournament_id,
                agent_id: ^agent_id
              }} = Tournaments.sign_up(tournament, agent, user.id)

      assert {:ok,
              %Participation{
                status: :signed_up,
                tournament_id: ^tournament_id,
                agent_id: ^agent_id
              }} = Tournaments.sign_off(tournament, agent, user.id)

      assert nil == Tournaments.get_participation(agent.id, tournament.id)
    end
  end
end
