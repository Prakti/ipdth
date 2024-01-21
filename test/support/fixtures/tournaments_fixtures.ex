defmodule Ipdth.TournamentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Tournaments` context.
  """

  @doc """
  Generate a tournament.
  """
  def tournament_fixture(attrs \\ %{}) do
    {:ok, tournament} =
      attrs
      |> Enum.into(%{
        description: "some description",
        end_date: ~U[2024-01-20 12:56:00Z],
        name: "some name",
        random_seed: "some random_seed",
        random_trace: "some random_trace",
        round_number: 42,
        start_date: ~U[2024-01-20 12:56:00Z],
        status: "some status"
      })
      |> Ipdth.Tournaments.create_tournament()

    tournament
  end

  @doc """
  Generate a participation.
  """
  def participation_fixture(attrs \\ %{}) do
    {:ok, participation} =
      attrs
      |> Enum.into(%{
        details: "some details",
        ranking: 42,
        score: 42,
        sign_up: ~U[2024-01-20 18:04:00.000000Z],
        status: :signed_up
      })
      |> Ipdth.Tournaments.create_participation()

    participation
  end
end
