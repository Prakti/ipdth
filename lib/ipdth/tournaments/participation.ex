defmodule Ipdth.Tournaments.Participation do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Agents.Agent
  alias Ipdth.Tournaments.Tournament

  schema "participations" do
    field :status, Ecto.Enum, values: [:signed_up, :participating, :done, :disqualified, :error]
    field :score, :integer
    field :ranking, :integer
    field :sign_up, :utc_datetime_usec
    field :details, :string
    belongs_to :agent, Agent
    belongs_to :tournament, Tournament

    timestamps()
  end

  @doc false
  def changeset(participation, attrs) do
    participation
    |> cast(attrs, [:score, :ranking, :sign_up, :status, :details])
    |> validate_required([:score, :ranking, :sign_up, :status, :details])
  end

end
