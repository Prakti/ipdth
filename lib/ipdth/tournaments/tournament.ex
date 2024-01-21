defmodule Ipdth.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tournaments" do
    field :name, :string
    field :status, :string
    field :description, :string
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :round_number, :integer
    field :random_seed, :string
    field :random_trace, :string

    timestamps([type: :utc_datetime_usec])
  end

  # TODO: 2024-01-21 - Introduce Status model
  # TODO: 2024-01-21 - Set status automatically on create

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :description, :start_date, :end_date, :round_number, :random_seed, :random_trace, :status])
    |> validate_required([:name, :start_date, :round_number])
  end
end
