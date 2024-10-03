defmodule IpdthWeb.TournamentLiveTest do
  use IpdthWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ipdth.TournamentsFixtures
  import Ipdth.AccountsFixtures

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
