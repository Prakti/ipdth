defmodule Ipdth.AgentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Agents` context.
  """

  alias Ipdth.AccountsFixtures

  @doc """
  Generate a agent.
  """
  def agent_fixture(attrs \\ %{}) do
    user = AccountsFixtures.user_fixture()

    agent_attrs = Enum.into(attrs, %{
      bearer_token: "some bearer_token",
      description: "some description",
      name: "some name",
      status: :active,
      url: "some url"
    })

    {:ok, agent} = Ipdth.Agents.create_agent(user.id, agent_attrs)

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
