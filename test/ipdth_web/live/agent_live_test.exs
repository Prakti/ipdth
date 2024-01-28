defmodule IpdthWeb.AgentLiveTest do
  use IpdthWeb.ConnCase

  import Phoenix.LiveViewTest
  import Ipdth.AgentsFixtures

  defp create_agent(_) do
    agent = agent_fixture()
    %{agent: agent}
  end

  describe "Index (logged In)" do
    setup [:create_agent, :register_and_log_in_user]

    test "lists all agents", %{conn: conn, agent: agent} do
      {:ok, _index_live, html} = live(conn, ~p"/agents")

      assert html =~ "Listing Agents"
      assert html =~ agent.name
    end
  end

  describe "Show (logged In)" do
    setup [:create_agent, :register_and_log_in_user]

    test "displays agent", %{conn: conn, agent: agent} do
      {:ok, _show_live, html} = live(conn, ~p"/agents/#{agent}")

      assert html =~ "Show Agent"
      assert html =~ agent.name
    end
  end

  describe "Index (anon)" do
    setup [:create_agent]

    test "lists all agents", %{conn: conn, agent: agent} do
      {:ok, _index_live, html} = live(conn, ~p"/agents")

      assert html =~ "Listing Agents"
      assert html =~ agent.name
    end
  end

  describe "Show (anon)" do
    setup [:create_agent]

    test "displays agent", %{conn: conn, agent: agent} do
      {:ok, _show_live, html} = live(conn, ~p"/agents/#{agent}")

      assert html =~ "Show Agent"
      assert html =~ agent.name
    end
  end
end
