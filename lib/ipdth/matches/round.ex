defmodule Ipdth.Matches.Round do
  @moduledoc """
  Database Entity of one Round of a Tournament. Is embedded in a Match
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Matches.Round
  alias Ipdth.Matches.Match

  schema "rounds" do
    field :action_a, Ecto.Enum, values: [:cooperate, :defect]
    field :action_b, Ecto.Enum, values: [:cooperate, :defect]
    field :score_a, :integer
    field :score_b, :integer
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    belongs_to :match, Match
  end

  @doc false
  def new(match_id, action_a, action_b, score_a, score_b, start_date) do
    change(%Round{},
      action_a: action_a,
      action_b: action_b,
      score_a: score_a,
      score_b: score_b,
      start_date: start_date,
      end_date: DateTime.utc_now(),
      match_id: match_id
    )
  end
end
