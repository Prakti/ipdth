defmodule Ipdth.Agents.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Tournaments.Participation
  alias Ipdth.Accounts.User

  schema "agents" do
    field :name, :string
    field :status, Ecto.Enum, values: [:inactive, :testing, :active, :error_backoff]
    field :description, :string
    field :url, :string
    field :bearer_token, :string
    has_many :participations, Participation
    belongs_to :owner, User

    timestamps([type: :utc_datetime_usec])
  end

  # TODO: 2024-01-21 - Set some new status on creation
  # TODO: 2024-01-21 - Introduce Validation for url

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [:name, :description, :url, :bearer_token, :status])
    |> validate_required([:name, :url, :bearer_token, :status])
  end
end
