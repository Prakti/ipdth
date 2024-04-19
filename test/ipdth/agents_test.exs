defmodule Ipdth.AgentsTest do
  use Ipdth.DataCase

  alias Ipdth.Agents

  setup tags do
    if tags[:silence_logger] do
      # Store the current log level
      original_log_level = Logger.level()

      # Set the Logger level to :none to silence it
      :ok = Logger.configure(level: :none)

      # Ensure the Logger level is restored after the test
      on_exit(fn ->
        :ok = Logger.configure(level: original_log_level)
      end)
    end

    # Continue with the test
    :ok
  end

  describe "agents" do
    alias Ipdth.Agents.Agent

    import Ipdth.AgentsFixtures
    import Ipdth.AccountsFixtures

    @invalid_attrs %{name: nil, status: nil, description: nil, url: nil, bearer_token: nil}

    test "list_agents/0 returns all agents" do
      owner = user_fixture()
      agent = Agents.load_owner(agent_fixture(owner))

      assert Agents.list_agents() == [agent]
    end

    test "get_agent!/1 returns the agent with given id" do
      owner = user_fixture()
      agent = agent_fixture(owner)
      assert Agents.get_agent!(agent.id) == agent
    end

    test "create_agent/1 with valid data creates a agent" do
      owner = user_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        url: "http://example.com",
        bearer_token: "some bearer_token"
      }

      assert {:ok, %Agent{} = agent} = Agents.create_agent(owner.id, valid_attrs)
      assert agent.name == "some name"
      assert agent.status == :inactive
      assert agent.description == "some description"
      assert agent.url == "http://example.com"
      assert agent.bearer_token == "some bearer_token"
    end

    test "create_agent/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Agents.create_agent(@invalid_attrs)
    end

    test "activate_agent/1 with responsive, deactivated agent activates the agent" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      assert {:ok, %Agent{} = activated_agent} = Agents.activate_agent(agent, owner.id)
      assert activated_agent.status == :active
    end

    test "activate_agent/1 handles unresponsive agents and error_backoff properly" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      Bypass.down(bypass)

      assert {:error, _reason} = Agents.activate_agent(agent, owner.id)

      Bypass.up(bypass)

      assert {:ok, %Agent{} = activated_agent} = Agents.activate_agent(agent, owner.id)
      assert activated_agent.status == :active
    end

    test "deactivate_agent/1 with active agent results in deavtivated agent" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      assert {:ok, %Agent{} = activated_agent} = Agents.activate_agent(agent, owner.id)
      assert activated_agent.status == :active

      assert {:ok, %Agent{} = deactivated_agent} =
               Agents.deactivate_agent(activated_agent, owner.id)

      assert deactivated_agent.status == :inactive
    end

    @tag silence_logger: true
    test "deactivate_agent/1 with agent in error_backoff results in deavtivated agent" do
      owner = user_fixture()
      agent = agent_fixture(owner)

      assert {:error, _reason} = Agents.activate_agent(agent, owner.id)
      error_agent = Agents.get_agent!(agent.id)
      assert error_agent.status == :error_backoff

      assert {:ok, %Agent{} = deactivated_agent} = Agents.deactivate_agent(error_agent, owner.id)
      assert deactivated_agent.status == :inactive
    end

    test "update_agent/2 with valid data updates the agent" do
      owner = user_fixture()
      agent = agent_fixture(owner)

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        url: "http://localhost:4004/api/examples/pushover",
        bearer_token: "some updated bearer_token"
      }

      assert {:ok, %Agent{} = agent} = Agents.update_agent(agent, owner.id, update_attrs)
      assert agent.name == "some updated name"
      assert agent.status == :inactive
      assert agent.description == "some updated description"
      assert agent.url == "http://localhost:4004/api/examples/pushover"
      assert agent.bearer_token == "some updated bearer_token"
    end

    test "update_agent/2 with invalid data returns error changeset" do
      owner = user_fixture()
      agent = agent_fixture(owner)
      assert {:error, %Ecto.Changeset{}} = Agents.update_agent(agent, owner.id, @invalid_attrs)
      assert agent == Agents.get_agent!(agent.id)
    end

    test "delete_agent/1 deletes the agent" do
      owner = user_fixture()
      agent = agent_fixture(owner)
      assert {:ok, %Agent{}} = Agents.delete_agent(agent, owner.id)
      assert_raise Ecto.NoResultsError, fn -> Agents.get_agent!(agent.id) end
    end

    test "change_agent/1 returns an agent changeset" do
      owner = user_fixture()
      agent = agent_fixture(owner)
      assert %Ecto.Changeset{} = Agents.change_agent(agent)
    end
  end
end
