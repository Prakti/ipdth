defmodule IpdthWeb.ParticipationLiveTest do
  use IpdthWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ipdth.TournamentsFixtures

  @create_attrs %{
    status: :signed_up,
    score: 42,
    ranking: 42,
    sign_up: "2024-01-20T18:04:00.000000Z",
    details: "some details"
  }
  @update_attrs %{
    status: :participating,
    score: 43,
    ranking: 43,
    sign_up: "2024-01-21T18:04:00.000000Z",
    details: "some updated details"
  }
  @invalid_attrs %{status: nil, score: nil, ranking: nil, sign_up: nil, details: nil}

  defp create_participation(_) do
    participation = participation_fixture()
    %{participation: participation}
  end

  describe "Index" do
    setup [:create_participation, :register_and_log_in_user]

    test "lists all participations", %{conn: conn, participation: participation} do
      {:ok, _index_live, html} = live(conn, ~p"/participations")

      assert html =~ "Listing Participations"
      assert html =~ participation.details
    end

    test "saves new participation", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/participations")

      assert index_live |> element("a", "New Participation") |> render_click() =~
               "New Participation"

      assert_patch(index_live, ~p"/participations/new")

      assert index_live
             |> form("#participation-form", participation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#participation-form", participation: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/participations")

      html = render(index_live)
      assert html =~ "Participation created successfully"
      assert html =~ "some details"
    end

    test "updates participation in listing", %{conn: conn, participation: participation} do
      {:ok, index_live, _html} = live(conn, ~p"/participations")

      assert index_live
             |> element("#participations-#{participation.id} a", "Edit")
             |> render_click() =~
               "Edit Participation"

      assert_patch(index_live, ~p"/participations/#{participation}/edit")

      assert index_live
             |> form("#participation-form", participation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#participation-form", participation: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/participations")

      html = render(index_live)
      assert html =~ "Participation updated successfully"
      assert html =~ "some updated details"
    end

    test "deletes participation in listing", %{conn: conn, participation: participation} do
      {:ok, index_live, _html} = live(conn, ~p"/participations")

      assert index_live
             |> element("#participations-#{participation.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#participations-#{participation.id}")
    end
  end

  describe "Show" do
    setup [:create_participation, :register_and_log_in_user]

    test "displays participation", %{conn: conn, participation: participation} do
      {:ok, _show_live, html} = live(conn, ~p"/participations/#{participation}")

      assert html =~ "Show Participation"
      assert html =~ participation.details
    end

    test "updates participation within modal", %{conn: conn, participation: participation} do
      {:ok, show_live, _html} = live(conn, ~p"/participations/#{participation}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Participation"

      assert_patch(show_live, ~p"/participations/#{participation}/show/edit")

      assert show_live
             |> form("#participation-form", participation: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#participation-form", participation: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/participations/#{participation}")

      html = render(show_live)
      assert html =~ "Participation updated successfully"
      assert html =~ "some updated details"
    end
  end
end
