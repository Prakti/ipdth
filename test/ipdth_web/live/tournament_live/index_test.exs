defmodule IpdthWeb.TournamentLive.IndexTest do
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

  def create_tournaments(_) do
    admin = admin_user_fixture()
    {created_tournaments, published_tournaments} = tournament_list_fixture(admin.id, 10, 2)

    %{
      admin: admin,
      created_tournaments: created_tournaments,
      published_tournaments: published_tournaments
    }
  end

  describe "Admin on Index page" do
    setup [:create_tournament, :register_and_log_in_admin]

    test "can see a paginated list of tournaments with default sorting and all necessary controls.",
         %{conn: conn, tournament: tournament} do
      {:ok, _index_live, html} = live(conn, ~p"/tournaments")

      assert html =~ "Listing Tournaments"
      assert html =~ tournament.name

      # TODO: Admins have the "New Tournament" Button
      # TODO: Admins have an Edit Button for each Tournament
      # TODO: Admins see all Tournaments inclding "created"
      # TODO: Admins see all filter options incl. "created"
      # TODO: Admins see all pagination controls
    end

    test "can create a new tournament", %{conn: conn} do
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

    test "can edit a tournament", %{conn: conn, tournament: tournament} do
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

    # TODO: Admins can paginate correctly
    # TODO: Admins can change page-size correctly
    # TODO: Admins can filter correctly
    # TODO: Admins can sort correctly
    # TODO: Admins can abort a Tournament correctly
  end

  describe "Normal user on Index page" do
    setup [:create_tournaments, :register_and_log_in_user]

    test "can list all tournaments in state published or later", %{
      conn: conn,
      created_tournaments: created_tournaments,
      published_tournaments: published_tournaments
    } do
      {:ok, _index_live, html} = live(conn, ~p"/tournaments")

      assert html =~ "Listing Tournaments"

      # Assert that all published tournaments are visible
      Enum.each(published_tournaments, fn tournament ->
        assert html =~ tournament.name
      end)

      # Assert that no create tournament is visible
      Enum.each(created_tournaments, fn tournament ->
        refute html =~ tournament.name
      end)
    end

    # TODO: Normal users do not have the "New Tournament" Button
    # TODO: Normal users do not have the "Edit" button for any tournament
    # TODO: Normal users cannot see Tournaments that are in status "created"
    # TODO: Normal users see all filter options except "created"
    # TODO: Normal users see all pagination controls
  end

  describe "Anonymous user on Index page" do
    setup [:create_tournaments]

    test "can lists all tournaments in state published or later", %{
      conn: conn,
      created_tournaments: created_tournaments,
      published_tournaments: published_tournaments
    } do
      {:ok, _index_live, html} = live(conn, ~p"/tournaments")

      assert html =~ "Listing Tournaments"

      # Assert that all published tournaments are visible
      Enum.each(published_tournaments, fn tournament ->
        assert html =~ tournament.name
      end)

      # Assert that no create tournament is visible
      Enum.each(created_tournaments, fn tournament ->
        refute html =~ tournament.name
      end)
    end

    # TODO: Anonymous users do not have the "New Tournament" Button
    # TODO: Anonymous users do not have the "Edit" button for any tournament
    # TODO: Anonymous users cannot see Tournaments that are in status "created"
    # TODO: Anonymous users see all filter options except "created"
    # TODO: Anonymous users see all pagination controls
  end
end
