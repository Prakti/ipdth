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

  @derive {
    Flop.Schema,
    filterable: [
      :owner_email
    ],
    sortable: [
      :ranking
    ],
    default_order: %{
      order_by: [:ranking],
      order_directions: [:asc]
    },
    default_limit: 50,
    adapter_opts: [
      join_fields: [
        agent_id: [
          binding: :agent,
          field: :id,
          ecto_type: :integer
        ],
        agent_name: [
          binding: :agent,
          field: :name,
          ecto_type: :string
        ],
        agent_status: [
          binding: :agent,
          field: :status,
          ecto_type: Ecto.Enum
        ],
        agent_description: [
          binding: :agent,
          field: :description,
          ecto_type: :string
        ],
        owner_email: [
          binding: :owner,
          field: :email,
          ecto_type: :string,
          path: [:agent, :owner, :email]
        ]
      ]
    ]
  }

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

  def set_to_error(participation) do
    change(participation, status: :error, score: nil, ranking: nil)
  end

  def update_score(participation, score) do
    change(participation, score: score)
  end

  def set_rank(participation, rank) do
    change(participation, ranking: rank)
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
