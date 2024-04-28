defmodule Ipdth.TournamentsTest do
  use Ipdth.DataCase

  alias Ipdth.Tournaments

  describe "tournaments" do
    alias Ipdth.Tournaments.Tournament

    import Ipdth.TournamentsFixtures

    @invalid_attrs %{
      name: nil,
      status: nil,
      description: nil,
      start_date: nil,
      round_number: nil,
      random_seed: nil,
    }

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      valid_attrs = %{
        name: "some name",
        description: "some description",
        start_date: ~U[2024-01-20 12:56:00Z],
        round_number: 42,
        random_seed: "some random_seed",
      }

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.name == "some name"
      assert tournament.status == :created
      assert tournament.description == "some description"
      assert tournament.start_date == ~U[2024-01-20 12:56:00.000000Z]
      assert tournament.round_number == 42
      assert tournament.random_seed == "some random_seed"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      # TODO: 2024-04-28 - test update_tournament against status model
      tournament = tournament_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        start_date: ~U[2024-01-21 12:56:00Z],
        round_number: 43,
        random_seed: "some updated random_seed",
      }

      assert {:ok, %Tournament{} = tournament} =
               Tournaments.update_tournament(tournament, update_attrs)

      assert tournament.name == "some updated name"
      assert tournament.status == :created
      assert tournament.description == "some updated description"
      assert tournament.start_date == ~U[2024-01-21 12:56:00.000000Z]
      assert tournament.round_number == 43
      assert tournament.random_seed == "some updated random_seed"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      # TODO: 2024-04-28 - test update_tournament against status model
      tournament = tournament_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Tournaments.update_tournament(tournament, @invalid_attrs)

      assert tournament == Tournaments.get_tournament!(tournament.id)
    end

    test "delete_tournament/1 deletes the tournament" do
      tournament = tournament_fixture()
      assert {:ok, %Tournament{}} = Tournaments.delete_tournament(tournament)
      assert_raise Ecto.NoResultsError, fn -> Tournaments.get_tournament!(tournament.id) end
    end

    test "change_tournament/1 returns a tournament changeset" do
      tournament = tournament_fixture()
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
