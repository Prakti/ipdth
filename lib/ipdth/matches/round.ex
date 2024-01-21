defmodule Ipdth.Matches.Round do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ipdth.Matches.Round

  embedded_schema do
    field :score_a, :integer
    field :score_b, :integer
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
  end

  @doc false
  def changeset(%Round{} = round, attrs) do
    round
    |> cast(attrs, [:score_a, :score_b, :start_date, :end_date])
    |> validate_required([:score_a, :score_b, :start_date, :end_date])
  end
end
