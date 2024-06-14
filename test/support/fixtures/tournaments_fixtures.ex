defmodule Ipdth.TournamentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ipdth.Tournaments` context.
  """

  alias Ipdth.Tournaments

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
        start_date: ~U[2024-01-20 12:56:00Z]
      })
      |> Tournaments.create_tournament(admin_id)

    tournament
  end

  def published_tournament_fixture(admin_id, attrs \\ %{}) do
    {:ok, tournament} =
      tournament_fixture(admin_id, attrs)
      |> Tournaments.publish_tournament(admin_id)

    tournament
  end

  def published_tournament_with_participants_fixture(admin_id, participants) do
    tournament = published_tournament_fixture(admin_id)
    Enum.map(participants, fn agent ->
      Tournaments.sign_up(tournament, agent, admin_id)
    end)
  end
end
