defmodule IpdthWeb.TournamentLiveTest do
  use IpdthWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ipdth.TournamentsFixtures
  import Ipdth.AccountsFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    start_date: "2024-01-20T12:56:00Z",
    rounds_per_match: 42,
    random_seed: "some random_seed"
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    start_date: "2024-01-21T12:56:00Z",
    rounds_per_match: 43,
    random_seed: "some updated random_seed"
  }
  @invalid_attrs %{
    name: nil,
    description: nil,
    start_date: nil,
    rounds_per_match: nil,
    random_seed: nil
  }

  defp create_tournament(_) do
    admin = admin_user_fixture()
    tournament = tournament_fixture(admin.id)
    %{admin: admin, tournament: tournament}
  end

  # TODO: 20204-04-29 -- Test with normal user!
  # TODO: 20204-04-29 -- Test with anonymous user!
  describe "Index (with admin user)" do
    setup [:create_tournament, :register_and_log_in_admin]

    test "lists all tournaments", %{conn: conn, tournament: tournament} do
      {:ok, _index_live, html} = live(conn, ~p"/tournaments")

      assert html =~ "Listing Tournaments"
      assert html =~ tournament.name
    end

    test "saves new tournament", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/tournaments")

      assert index_live |> element("a", "New Tournament") |> render_click() =~
               "New Tournament"

      assert_patch(index_live, ~p"/tournaments/new")

      assert index_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tournament-form", tournament: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tournaments")

      html = render(index_live)
      assert html =~ "Tournament created successfully"
      assert html =~ "some name"
    end

    test "updates tournament in listing", %{conn: conn, tournament: tournament} do
      {:ok, index_live, _html} = live(conn, ~p"/tournaments")

      assert index_live |> element("#tournaments-#{tournament.id} a", "Edit") |> render_click() =~
               "Edit Tournament"

      assert_patch(index_live, ~p"/tournaments/#{tournament}/edit")

      assert index_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#tournament-form", tournament: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/tournaments")

      html = render(index_live)
      assert html =~ "Tournament updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes tournament in listing", %{conn: conn, tournament: tournament} do
      {:ok, index_live, _html} = live(conn, ~p"/tournaments")

      assert index_live |> element("#tournaments-#{tournament.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#tournaments-#{tournament.id}")
    end
  end

  # TODO: 20204-04-29 -- Test with normal user!
  # TODO: 20204-04-29 -- Test with anonymous user!
  describe "Show (with admin user)" do
    setup [:create_tournament, :register_and_log_in_admin]

    test "displays tournament", %{conn: conn, tournament: tournament} do
      {:ok, _show_live, html} = live(conn, ~p"/tournaments/#{tournament}")

      assert html =~ "Show Tournament"
      assert html =~ tournament.name
    end

    test "updates tournament within modal", %{conn: conn, tournament: tournament} do
      {:ok, show_live, _html} = live(conn, ~p"/tournaments/#{tournament}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Tournament"

      assert_patch(show_live, ~p"/tournaments/#{tournament}/show/edit")

      assert show_live
             |> form("#tournament-form", tournament: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#tournament-form", tournament: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/tournaments/#{tournament}")

      html = render(show_live)
      assert html =~ "Tournament updated successfully"
      assert html =~ "some updated name"
    end
  end
end
