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
        status: "some status",
        url: "some url"
      })
      |> Ipdth.Agents.create_agent()

    agent
  end
end
