defmodule Ipdth.TournamentsTest do
  use Ipdth.DataCase

  alias Ipdth.Tournaments

  describe "tournaments" do
    alias Ipdth.Tournaments.Tournament

    import Ipdth.TournamentsFixtures

    @invalid_attrs %{name: nil, status: nil, description: nil, start_date: nil, end_date: nil, round_number: nil, random_seed: nil, random_trace: nil}

    test "list_tournaments/0 returns all tournaments" do
      tournament = tournament_fixture()
      assert Tournaments.list_tournaments() == [tournament]
    end

    test "get_tournament!/1 returns the tournament with given id" do
      tournament = tournament_fixture()
      assert Tournaments.get_tournament!(tournament.id) == tournament
    end

    test "create_tournament/1 with valid data creates a tournament" do
      valid_attrs = %{name: "some name", status: "some status", description: "some description", start_date: ~U[2024-01-20 12:56:00Z], end_date: ~U[2024-01-20 12:56:00Z], round_number: 42, random_seed: "some random_seed", random_trace: "some random_trace"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.create_tournament(valid_attrs)
      assert tournament.name == "some name"
      assert tournament.status == "some status"
      assert tournament.description == "some description"
      assert tournament.start_date == ~U[2024-01-20 12:56:00Z]
      assert tournament.end_date == ~U[2024-01-20 12:56:00Z]
      assert tournament.round_number == 42
      assert tournament.random_seed == "some random_seed"
      assert tournament.random_trace == "some random_trace"
    end

    test "create_tournament/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tournaments.create_tournament(@invalid_attrs)
    end

    test "update_tournament/2 with valid data updates the tournament" do
      tournament = tournament_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", description: "some updated description", start_date: ~U[2024-01-21 12:56:00Z], end_date: ~U[2024-01-21 12:56:00Z], round_number: 43, random_seed: "some updated random_seed", random_trace: "some updated random_trace"}

      assert {:ok, %Tournament{} = tournament} = Tournaments.update_tournament(tournament, update_attrs)
      assert tournament.name == "some updated name"
      assert tournament.status == "some updated status"
      assert tournament.description == "some updated description"
      assert tournament.start_date == ~U[2024-01-21 12:56:00Z]
      assert tournament.end_date == ~U[2024-01-21 12:56:00Z]
      assert tournament.round_number == 43
      assert tournament.random_seed == "some updated random_seed"
      assert tournament.random_trace == "some updated random_trace"
    end

    test "update_tournament/2 with invalid data returns error changeset" do
      tournament = tournament_fixture()
      assert {:error, %Ecto.Changeset{}} = Tournaments.update_tournament(tournament, @invalid_attrs)
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
end
