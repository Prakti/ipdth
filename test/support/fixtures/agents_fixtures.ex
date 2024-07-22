defmodule Ipdth.AgentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Agents` context.
  """

  alias Ipdth.Agents

  @doc """
  Generate a agent.
  """
  def agent_fixture(owner, attrs \\ %{}) do
    agent_attrs =
      Enum.into(attrs, %{
        bearer_token: "some bearer_token",
        description: "some description",
        name: "some name",
        status: :active,
        url: "http://example.com"
      })

    {:ok, agent} = Agents.create_agent(owner.id, agent_attrs)

    agent
  end

  def activated_agent_fixture(owner) do
    %{agent: inactive_agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

    Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
      conn
      |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
      |> Plug.Conn.resp(200, agent_service_success_response())
    end)

    {:ok, agent} = Agents.activate_agent(inactive_agent, owner.id)

    agent
  end

  def multiple_agents_one_bypass_fixture(owner, count) do
    bypass = Bypass.open()

    generator =
      Stream.unfold(1, fn n ->
        attrs = %{
          name: "Agent #{n}",
          url: "http://localhost:#{bypass.port}/decide",
          bearer_token: agent_service_bearer_token()
        }

        {agent_fixture(owner, attrs), n + 1}
      end)

    %{agents: Stream.take(generator, count), bypass: bypass}
  end

  def multiple_activated_agents_one_bypass_fixture(owner, count) do
    %{agents: agents, bypass: bypass} = multiple_agents_one_bypass_fixture(owner, count)

    Bypass.stub(bypass, "POST", "/decide", fn conn ->
      conn
      |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
      |> Plug.Conn.resp(200, agent_service_success_response())
    end)

    active_agents =
      Stream.map(agents, fn agent ->
        {:ok, agent} = Agents.activate_agent(agent, owner.id)
        agent
      end)

    %{agents: active_agents, bypass: bypass}
  end

  def agent_fixture_and_mock_service(owner) do
    bypass = Bypass.open()

    attrs = %{
      url: "http://localhost:#{bypass.port}/decide",
      bearer_token: agent_service_bearer_token()
    }

    agent = agent_fixture(owner, attrs)
    %{agent: agent, bypass: bypass}
  end

  def agent_service_success_response() do
    ~s<{
      "roundNumber": 0,
      "action": "Cooperate",
      "matchInfo": {
        "type": "Tournament",
        "tournamentId": "string",
        "matchId": "string"
      }
    }>
  end

  def agent_cooperate_reponse() do
    ~s<{
      "roundNumber": 0,
      "action": "Cooperate",
      "matchInfo": {
        "type": "Tournament",
        "tournamentId": "string",
        "matchId": "string"
      }
    }>
  end

  def agent_defect_reponse() do
    ~s<{
      "roundNumber": 0,
      "action": "Defect",
      "matchInfo": {
        "type": "Tournament",
        "tournamentId": "string",
        "matchId": "string"
      }
    }>
  end

  def agent_service_500_response() do
    ~s<{
      "error": "ProvokedError",
      "details": "Intentionally provoked error, to test error handling."
    }>
  end

  def agent_service_bearer_token() do
    "0xBABAF00"
  end
end
