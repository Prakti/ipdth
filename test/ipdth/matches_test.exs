defmodule Ipdth.MatchesTest do
  use Ipdth.DataCase

  alias Ipdth.Matches

  describe "matches" do
    alias Ipdth.Matches.Match

    import Ipdth.MatchesFixtures

    @invalid_attrs %{start_date: nil, end_date: nil, score_a: nil, score_b: nil}

    test "list_matches/0 returns all matches" do
      match = match_fixture()
      assert Matches.list_matches() == [match]
    end

    test "get_match!/1 returns the match with given id" do
      match = match_fixture()
      assert Matches.get_match!(match.id) == match
    end

    test "create_match/1 with valid data creates a match" do
      valid_attrs = %{start_date: ~U[2024-01-20 20:00:00.000000Z], end_date: ~U[2024-01-20 20:00:00.000000Z], score_a: 42, score_b: 42}

      assert {:ok, %Match{} = match} = Matches.create_match(valid_attrs)
      assert match.start_date == ~U[2024-01-20 20:00:00.000000Z]
      assert match.end_date == ~U[2024-01-20 20:00:00.000000Z]
      assert match.score_a == 42
      assert match.score_b == 42
    end

    test "create_match/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Matches.create_match(@invalid_attrs)
    end

    test "update_match/2 with valid data updates the match" do
      match = match_fixture()
      update_attrs = %{start_date: ~U[2024-01-21 20:00:00.000000Z], end_date: ~U[2024-01-21 20:00:00.000000Z], score_a: 43, score_b: 43}

      assert {:ok, %Match{} = match} = Matches.update_match(match, update_attrs)
      assert match.start_date == ~U[2024-01-21 20:00:00.000000Z]
      assert match.end_date == ~U[2024-01-21 20:00:00.000000Z]
      assert match.score_a == 43
      assert match.score_b == 43
    end

    test "update_match/2 with invalid data returns error changeset" do
      match = match_fixture()
      assert {:error, %Ecto.Changeset{}} = Matches.update_match(match, @invalid_attrs)
      assert match == Matches.get_match!(match.id)
    end

    test "delete_match/1 deletes the match" do
      match = match_fixture()
      assert {:ok, %Match{}} = Matches.delete_match(match)
      assert_raise Ecto.NoResultsError, fn -> Matches.get_match!(match.id) end
    end

    test "change_match/1 returns a match changeset" do
      match = match_fixture()
      assert %Ecto.Changeset{} = Matches.change_match(match)
    end
  end
end
