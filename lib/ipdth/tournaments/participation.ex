defmodule Ipdth.Tournaments.Participation do
  @moduledoc """
  Database Entity for modeling a many-to-many relationhsip between Agents and
  Tournaments. Also stores additional metadata regarding an Agent's
  participation at a tournament, like score and ranking.
  """

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

  def sign_up(participation, tournament, agent) do
    change(
      participation,
      tournament_id: tournament.id,
      agent_id: agent.id,
      sign_up: DateTime.utc_now(),
      status: :signed_up
    )
  end
end
