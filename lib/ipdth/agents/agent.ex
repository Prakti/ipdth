defmodule Ipdth.Agents.Agent do
  @moduledoc """
  Database Entity representing an Agent. Has relationships to User (owner) and
  Tournament Participation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Tournaments.Participation
  alias Ipdth.Accounts.User
  alias Ipdth.Agents.{Agent, ConnectionError}

  schema "agents" do
    field :name, :string
    field :status, Ecto.Enum, values: [:inactive, :testing, :active, :backoff, :error]
    field :description, :string
    field :url, :string
    field :bearer_token, :string
    has_many :participations, Participation
    has_many :connection_errors, ConnectionError
    belongs_to :owner, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc false
  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [:name, :description, :url, :bearer_token, :status])
    |> validate_required([:name, :url, :bearer_token, :status])
    |> validate_inclusion(:status, Ecto.Enum.values(Agent, :status))
    |> validate_url(:url)
  end

  def update(agent, attrs) do
    agent
    |> cast(attrs, [:name, :description, :url, :bearer_token])
    |> validate_required([:name, :url, :bearer_token])
    |> validate_url(:url)
  end

  def new(agent, owner_id, attrs) do
    agent
    |> update(attrs)
    |> put_change(:owner_id, owner_id)
    |> put_change(:status, :inactive)
  end

  def activate(agent) do
    change(agent, status: :active)
  end

  def backoff(agent) do
    change(agent, status: :backoff)
  end

  def error(agent) do
    change(agent, status: :error)
  end

  def deactivate(agent) do
    change(agent, status: :inactive)
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      case Regex.match?(~r/^https?:\/\/[^\s$.?#].[^\s]*$/, value) do
        true -> []
        false -> [{field, "is not a valid URL"}]
      end
    end)
  end
end
