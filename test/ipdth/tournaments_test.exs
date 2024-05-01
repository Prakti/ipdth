defmodule Ipdth.TournamentsTest do
  use Ipdth.DataCase

  alias Ipdth.Tournaments

  describe "tournaments" do
    alias Ipdth.Tournaments.Tournament

    import Ipdth.TournamentsFixtures
    import Ipdth.AccountsFixtures

    @invalid_attrs %{
      name: nil,
      status: nil,
      description: nil,
      start_date: nil,
      round_number: nil,
      random_seed: nil,
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
        random_seed: "some random_seed",
      }

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs, admin.id)
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
        random_seed: "some random_seed",
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

    # TODO: 2024-04-28 - test update_tournament against status model

    test "update_tournament/2 as an admin with valid data updates the tournament" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed",
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

    test "update_tournament/2 as a normal user with valid data fails with :not_authorized" do
      admin = admin_user_fixture()
      tournament = tournament_fixture(admin.id)
      user = user_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed",
      }

      assert {:error, :not_authorized} = Tournaments.update_tournament(tournament, update_attrs, user.id)
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
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id, admin.id) end
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
    alias Ipdth.Tournaments.Participation

    import Ipdth.TournamentsFixtures

    @invalid_attrs %{status: nil, score: nil, ranking: nil, sign_up: nil, details: nil}

    test "list_participations/0 returns all participations" do
      participation = participation_fixture()
      assert Tournaments.list_participations() == [participation]
    end

    test "get_participation!/1 returns the participation with given id" do
      participation = participation_fixture()
      assert Tournaments.get_participation!(participation.id) == participation
    end

    test "create_participation/1 with valid data creates a participation" do
      valid_attrs = %{
        status: :signed_up,
        score: 42,
        ranking: 42,
        sign_up: ~U[2024-01-20 18:04:00.000000Z],
        details: "some details"
      }

      assert {:ok, %Participation{} = participation} =
               Tournaments.create_participation(valid_attrs)

      assert participation.status == :signed_up
      assert participation.score == 42
      assert participation.ranking == 42
      assert participation.sign_up == ~U[2024-01-20 18:04:00.000000Z]
      assert participation.details == "some details"
    end

    test "create_participation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_participation(@invalid_attrs)
    end

    test "update_participation/2 with valid data updates the participation" do
      participation = participation_fixture()

      update_attrs = %{
        status: :participating,
        score: 43,
        ranking: 43,
        sign_up: ~U[2024-01-21 18:04:00.000000Z],
        details: "some updated details"
      }

      assert {:ok, %Participation{} = participation} =
               Tournaments.update_participation(participation, update_attrs)

      assert participation.status == :participating
      assert participation.score == 43
      assert participation.ranking == 43
      assert participation.sign_up == ~U[2024-01-21 18:04:00.000000Z]
      assert participation.details == "some updated details"
    end

    test "update_participation/2 with invalid data returns error changeset" do
      participation = participation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Tournaments.update_participation(participation, @invalid_attrs)

      assert participation == Tournaments.get_participation!(participation.id)
    end

    test "delete_participation/1 deletes the participation" do
      participation = participation_fixture()
      assert {:ok, %Participation{}} = Tournaments.delete_participation(participation)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_participation!(participation.id) end
    end

    test "change_participation/1 returns a participation changeset" do
      participation = participation_fixture()
      assert %Ecto.Changeset{} = Tournaments.change_participation(participation)
    end
  end
end
