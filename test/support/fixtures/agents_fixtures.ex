defmodule Ipdth.AgentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Agents` context.
  """

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

    {:ok, agent} = Ipdth.Agents.create_agent(owner.id, agent_attrs)

    agent
  end

  def activated_agent_fixture(owner) do
    %{agent: inactive_agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

    Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
      conn
      |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
      |> Plug.Conn.resp(200, agent_service_success_response())
    end)

    {:ok, agent} = Ipdth.Agents.activate_agent(inactive_agent, owner.id)

    agent
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

  def agent_service_500_response() do
    ~s<{
      "error": "ProvokedError",
      "details": "Intentionally provoked arror to test error handling."
    }>
  end

  def agent_service_bearer_token() do
    "0xBABAF00"
  end
end
