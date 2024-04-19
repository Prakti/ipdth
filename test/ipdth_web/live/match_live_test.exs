defmodule IpdthWeb.MatchLiveTest do
  use IpdthWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ipdth.MatchesFixtures

  @create_attrs %{
    start_date: "2024-01-20T20:00:00.000000Z",
    end_date: "2024-01-20T20:00:00.000000Z",
    score_a: 42,
    score_b: 42
  }
  @update_attrs %{
    start_date: "2024-01-21T20:00:00.000000Z",
    end_date: "2024-01-21T20:00:00.000000Z",
    score_a: 43,
    score_b: 43
  }
  @invalid_attrs %{start_date: nil, end_date: nil, score_a: nil, score_b: nil}

  defp create_match(_) do
    match = match_fixture()
    %{match: match}
  end

  describe "Index" do
    setup [:create_match, :register_and_log_in_user]

    test "lists all matches", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/matches")

      assert html =~ "Listing Matches"
    end

    test "saves new match", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/matches")

      assert index_live |> element("a", "New Match") |> render_click() =~
               "New Match"

      assert_patch(index_live, ~p"/matches/new")

      assert index_live
             |> form("#match-form", match: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#match-form", match: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/matches")

      html = render(index_live)
      assert html =~ "Match created successfully"
    end

    test "updates match in listing", %{conn: conn, match: match} do
      {:ok, index_live, _html} = live(conn, ~p"/matches")

      assert index_live |> element("#matches-#{match.id} a", "Edit") |> render_click() =~
               "Edit Match"

      assert_patch(index_live, ~p"/matches/#{match}/edit")

      assert index_live
             |> form("#match-form", match: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#match-form", match: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/matches")

      html = render(index_live)
      assert html =~ "Match updated successfully"
    end

    test "deletes match in listing", %{conn: conn, match: match} do
      {:ok, index_live, _html} = live(conn, ~p"/matches")

      assert index_live |> element("#matches-#{match.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#matches-#{match.id}")
    end
  end

  describe "Show" do
    setup [:create_match, :register_and_log_in_user]

    test "displays match", %{conn: conn, match: match} do
      {:ok, _show_live, html} = live(conn, ~p"/matches/#{match}")

      assert html =~ "Show Match"
    end

    test "updates match within modal", %{conn: conn, match: match} do
      {:ok, show_live, _html} = live(conn, ~p"/matches/#{match}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Match"

      assert_patch(show_live, ~p"/matches/#{match}/show/edit")

      assert show_live
             |> form("#match-form", match: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#match-form", match: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/matches/#{match}")

      html = render(show_live)
      assert html =~ "Match updated successfully"
    end
  end
end
