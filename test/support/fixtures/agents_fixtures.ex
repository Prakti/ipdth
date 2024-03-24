defmodule Ipdth.AgentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Agents` context.
  """

  @doc """
  Generate a agent.
  """
  def agent_fixture(attrs \\ %{}) do
    {:ok, agent} =
      attrs
      |> Enum.into(%{
        bearer_token: "some bearer_token",
        description: "some description",
        name: "some name",
        status: :active,
        url: "some url"
      })
      |> Ipdth.Agents.create_agent()

    agent
  end

  def agent_fixture_and_mock_service() do
    bypass = Bypass.open()
    attrs = %{
      url: "http://localhost:#{bypass.port}/decide",
      bearer_token: agent_service_bearer_token()
    }

    agent = agent_fixture(attrs)
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

  def agent_service_bearer_token() do
    "0xBABAF00"
  end

end
