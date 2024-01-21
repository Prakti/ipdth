defmodule Ipdth.MatchesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Matches` context.
  """

  @doc """
  Generate a match.
  """
  def match_fixture(attrs \\ %{}) do
    {:ok, match} =
      attrs
      |> Enum.into(%{
        end_date: ~U[2024-01-20 20:00:00.000000Z],
        score_a: 42,
        score_b: 42,
        start_date: ~U[2024-01-20 20:00:00.000000Z]
      })
      |> Ipdth.Matches.create_match()

    match
  end
end
