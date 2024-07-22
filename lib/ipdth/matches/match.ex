defmodule Ipdth.Matches.Match do
  @moduledoc """
  Database Entity of one Match in a Tournament. Embeds multiple Rounds.
  Has relationships to the two competing Agents and the tournament the Match
  is part of.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Matches.{Match, Round}
  alias Ipdth.Agents.Agent
  alias Ipdth.Tournaments.Tournament

  schema "matches" do
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :score_a, :integer
    field :score_b, :integer
    field :rounds_to_play, :integer

    field :status, Ecto.Enum,
      values: [:open, :started, :finished, :invalidated, :aborted, :cancelled]

    field :tournament_round, :integer
    has_many :rounds, Round
    belongs_to :agent_a, Agent
    belongs_to :agent_b, Agent
    belongs_to :tournament, Tournament

    timestamps()
  end

  def new(agent_a, agent_b, tournament, tournament_round, rounds_to_play) do
    change(%Match{},
      status: :open,
      agent_a: agent_a,
      agent_b: agent_b,
      tournament: tournament,
      tournament_round: tournament_round,
      rounds_to_play: rounds_to_play
    )
    |> validate_required([:agent_a, :agent_b, :tournament, :rounds_to_play])
    |> validate_number(:rounds_to_play, greater_than: 0)
  end

  def start(match) do
    change(match,
      status: :started,
      start_date: DateTime.utc_now()
    )
  end

  def abort(match) do
    change(match, status: :aborted, end_date: DateTime.utc_now())
  end

  def finish(match, total_scores) do
    match
    |> cast(total_scores, [:score_a, :score_b])
    |> change(status: :finished, end_date: DateTime.utc_now())
  end

  def invalidate(match) do
    change(match, status: :invalidated)
  end
end
