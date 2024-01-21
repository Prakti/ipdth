defmodule Ipdth.Matches.Match do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Matches.Round

  schema "matches" do
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :score_a, :integer
    field :score_b, :integer
    embeds_many :rounds, Round

    timestamps()
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [:start_date, :end_date, :score_a, :score_b])
    |> validate_required([:start_date])
  end
end
