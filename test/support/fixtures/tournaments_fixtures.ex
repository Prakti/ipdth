defmodule Ipdth.TournamentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Tournaments` context.
  """

  @doc """
  Generate a tournament.
  """
  def tournament_fixture(admin_id, attrs \\ %{}) do
    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name",
        random_seed: "some random_seed",
        round_number: 42,
        start_date: ~U[2024-01-20 12:56:00Z],
      })
      |> Ipdth.Tournaments.create_tournament(admin_id)

    tournament
  end

  def published_tournament_fixture(admin_id, attrs \\ %{}) do
    {:ok, tournament} =
      tournament_fixture(admin_id, attrs)
      |> Ipdth.Tournaments.publish_tournament(admin_id)

    tournament
  end

end
