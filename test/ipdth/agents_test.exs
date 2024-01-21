defmodule Ipdth.AgentsTest do
  use Ipdth.DataCase

  alias Ipdth.Agents

  describe "agents" do
    alias Ipdth.Agents.Agent

    import Ipdth.AgentsFixtures

    @invalid_attrs %{name: nil, status: nil, description: nil, url: nil, bearer_token: nil}

    test "list_agents/0 returns all agents" do
      agent = agent_fixture()
      assert Agents.list_agents() == [agent]
    end

    test "get_agent!/1 returns the agent with given id" do
      agent = agent_fixture()
      assert Agents.get_agent!(agent.id) == agent
    end

    test "create_agent/1 with valid data creates a agent" do
      valid_attrs = %{name: "some name", status: "some status", description: "some description", url: "some url", bearer_token: "some bearer_token"}

      assert {:ok, %Agent{} = agent} = Agents.create_agent(valid_attrs)
      assert agent.name == "some name"
      assert agent.status == "some status"
      assert agent.description == "some description"
      assert agent.url == "some url"
      assert agent.bearer_token == "some bearer_token"
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Agents.create_agent(@invalid_attrs)
    end

    test "update_agent/2 with valid data updates the agent" do
      agent = agent_fixture()
      update_attrs = %{name: "some updated name", status: "some updated status", description: "some updated description", url: "some updated url", bearer_token: "some updated bearer_token"}

      assert {:ok, %Agent{} = agent} = Agents.update_agent(agent, update_attrs)
      assert agent.name == "some updated name"
      assert agent.status == "some updated status"
      assert agent.description == "some updated description"
      assert agent.url == "some updated url"
      assert agent.bearer_token == "some updated bearer_token"
    end

    test "update_agent/2 with invalid data returns error changeset" do
      agent = agent_fixture()
      assert {:error, %Ecto.Changeset{}} = Agents.update_agent(agent, @invalid_attrs)
      assert agent == Agents.get_agent!(agent.id)
    end

    test "delete_agent/1 deletes the agent" do
      agent = agent_fixture()
      assert {:ok, %Agent{}} = Agents.delete_agent(agent)
      assert_raise Ecto.NoResultsError, fn -> Agents.get_agent!(agent.id) end
    end

    test "change_agent/1 returns a agent changeset" do
      agent = agent_fixture()
      assert %Ecto.Changeset{} = Agents.change_agent(agent)
    end
  end
end
