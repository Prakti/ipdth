defmodule Ipdth.AgentsTest do
  use Ipdth.DataCase

  alias Ipdth.Agents

  describe "agents" do
    alias Ipdth.Agents.Agent

    import Ipdth.AgentsFixtures
    import Ipdth.AccountsFixtures

    @invalid_attrs %{name: nil, status: nil, description: nil, url: nil, bearer_token: nil}

    test "list_agents/0 returns all agents" do
      agent = Agents.load_owner(agent_fixture())

      assert Agents.list_agents() == [agent]
    end

    test "get_agent!/1 returns the agent with given id" do
      agent = agent_fixture()
      assert Agents.get_agent!(agent.id) == agent
    end

    test "create_agent/1 with valid data creates a agent" do
      owner = user_fixture()
      valid_attrs = %{name: "some name", description: "some description", url: "some url", bearer_token: "some bearer_token"}

      assert {:ok, %Agent{} = agent} = Agents.create_agent(owner.id, valid_attrs)
      assert agent.name == "some name"
      assert agent.status == :inactive
      assert agent.description == "some description"
      assert agent.url == "some url"
      assert agent.bearer_token == "some bearer_token"
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Agents.create_agent(@invalid_attrs)
    end

    test "activate_agent/1 with responsive agent activates the agent" do
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service()

      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      assert {:ok, %Agent{} = activated_agent} = Agents.activate_agent(agent)
      assert activated_agent.status == :active
    end

    test "activate_agent/1 with unresponsive agent service puts agent into error_backoff" do
      assert false, "Implement Test"
    end

    test "update_agent/2 with valid data updates the agent" do
      agent = agent_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", url: "some updated url", bearer_token: "some updated bearer_token"}

      assert {:ok, %Agent{} = agent} = Agents.update_agent(agent, update_attrs)
      assert agent.name == "some updated name"
      assert agent.status == :inactive
      assert agent.description == "some updated description"
      assert agent.url == "some updated url"
      assert agent.bearer_token == "some updated bearer_token"
    end

    test "update_agent/2 with invalid data returns error changeset" do
      agent = agent_fixture()
      assert {:error, %Ecto.Changeset{}} = Agents.update_agent(agent, @invalid_attrs)
      assert agent == Agents.get_agent!(agent.id)
    end

    # TODO: 2024-03-18 - We need a test for activation
    # TODO: 2024-03-18 - We need a test for deactivation
    # TODO: 2024-03-18 - We need a test for error_backoff

    test "delete_agent/1 deletes the agent" do
      agent = agent_fixture()
      assert {:ok, %Agent{}} = Agents.delete_agent(agent)
      assert_raise Ecto.NoResultsError, fn -> Agents.get_agent!(agent.id) end
    end

    test "change_agent/1 returns an agent changeset" do
      agent = agent_fixture()
      assert %Ecto.Changeset{} = Agents.change_agent(agent)
    end
  end
end
