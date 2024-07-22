defmodule Ipdth.MatchesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Matches` context.
  """

  @doc """
  Generate a match.
  """
  def match_fixture(agent_a, agent_b, tournament, tournament_round, rounds_to_play) do
    {:ok, match} =
      Ipdth.Matches.create_match(agent_a, agent_b, tournament, tournament_round, rounds_to_play)

    match
  end
end
