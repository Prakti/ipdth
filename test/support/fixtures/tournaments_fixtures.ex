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
        rounds_per_match: 42,
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

  def published_tournament_with_participants_fixture(admin_id, agents, attrs \\ %{}) do
    tournament = published_tournament_fixture(admin_id, attrs)

    participations =
      Enum.map(agents, fn agent ->
        {:ok, participation} = Tournaments.sign_up(tournament, agent, admin_id)
        participation
      end)

    %{participations: participations, agents: agents, tournament: tournament}
  end

  def tournament_list_fixture(admin_id, total_count, published_count) do
    Enum.map(1..total_count, fn n ->
      tournament_fixture(admin_id, %{
        name: "Tournament-#{n}"
      })
    end)
    |> Enum.split(published_count)
    |> then(fn {to_publish, tournaments} ->
      {
        tournaments,
        Enum.map(to_publish, fn t ->
          {:ok, p} = Ipdth.Tournaments.publish_tournament(t, admin_id)
          p
        end)
      }
    end)
  end
end
