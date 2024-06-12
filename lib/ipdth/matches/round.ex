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
  def new(%Round{} = round, attrs) do
    round
    |> cast(attrs, [:action_a, :action_b, :score_a, :score_b])
    # Put in start_date and end_date as utc_now
    |> validate_required([:action_a, :action_b, :score_a, :score_b])
  end
end
