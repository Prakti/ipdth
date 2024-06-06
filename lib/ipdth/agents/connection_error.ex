defmodule Ipdth.Agents.ConnectionError do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Agents.Agent

  schema "connection_errors" do
    field :error_message, :string
    belongs_to :agent, Agent

    timestamps()
  end

  def changeset(error_log, attrs) do
    error_log
    |> cast(attrs, [:error_message, :agent_id])
    |> validate_required([:error_message, :agent_id])
  end
end
