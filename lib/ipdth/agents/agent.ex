defmodule Ipdth.Agents.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "agents" do
    field :name, :string
    field :status, :string
    field :description, :string
    field :url, :string
    field :bearer_token, :string

    timestamps([type: :utc_datetime_usec])
  end

  # TODO: 2024-01-21 - Introduce Status-Model
  # TODO: 2024-01-21 - Set some new status on creation
  # TODO: 2024-01-21 - Introduce Validation for url

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [:name, :description, :url, :bearer_token, :status])
    |> validate_required([:name, :url, :bearer_token, :status])
  end
end
