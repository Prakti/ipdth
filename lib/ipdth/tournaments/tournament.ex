defmodule Ipdth.Tournaments.Tournament do
  @moduledoc """
  Database Entity representing tournaments. Has relationships to participating
  Agents, Users (creator and last editor) and the Matches performed within the
  scope of the tournament.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Tournaments.{Participation, Tournament}
  alias Ipdth.Matches.Match
  alias Ipdth.Accounts.User

  @status_values [:created, :published, :signup_closed, :running, :aborted, :finished]

  # TODO: 2027-07-31 - Introduce progress field in percent (int)
  # TODO: 2027-07-31 - Introduce tournament_rounds field (int)
  # TODO: 2027-07-31 - Introduce current_tournament_round field (int)
  # TODO: 2027-07-31 - Migrate round_number to rounds_per_match

  schema "tournaments" do
    field :name, :string
    field :status, Ecto.Enum, values: @status_values, default: :created
    field :description, :string
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :round_number, :integer
    field :random_seed, :string
    field :random_trace, :string
    has_many :participations, Participation
    has_many :matches, Match
    belongs_to :creator, User
    belongs_to :last_modified_by, User

    timestamps(type: :utc_datetime_usec)
  end

  # TODO: 2024-04-28 - Tournament Notes Idea: type: comment, change, note: text

  @doc false
  def changeset(tournament, attrs) do
    tournament
    |> cast(attrs, [
      :name,
      :description,
      :start_date,
      :round_number,
      :random_seed,
      :status
    ])
    |> validate_required([:name, :start_date, :round_number])
  end

  def update(%Tournament{status: :created} = tournament, attrs, actor_id) do
    tournament
    |> cast(attrs, [:name, :description, :start_date, :round_number, :random_seed])
    |> put_change(:last_modified_by_id, actor_id)
    |> validate_required([:name, :start_date, :round_number])

    # TODO: 2024-08-28 - We need a 'signup_deadline' field
    # TODO: 2024-08-28 - We need a validator ensuring that 'signup_deadline' is earlier than start_date
  end

  def update(%Tournament{status: :published} = tournament, attrs, actor_id) do
    tournament
    |> cast(attrs, [:name, :description])
    |> put_change(:last_modified_by_id, actor_id)
    |> validate_required([:name, :start_date, :round_number])
  end

  def new(tournament, attrs, creator_id) do
    tournament
    |> update(attrs, creator_id)
    |> put_change(:creator_id, creator_id)
  end

  def publish(tournament, actor_id) do
    change(tournament, status: :published, last_modified_by_id: actor_id)
  end

  def unpublish(tournament, actor_id) do
    change(tournament, status: :created, last_modified_by_id: actor_id)
  end

  def close_signup(tournament, actor_id) do
    change(tournament, status: :signup_closed, last_modified_by_id: actor_id)
  end

  def start(tournament) do
    change(tournament, status: :running)
  end

  def abort(tournament) do
    change(tournament, status: :aborted)
    # TODO: 2024-04-28 - Set the end date on abort
  end

  def finish(tournament) do
    change(tournament, status: :finished, end_date: DateTime.utc_now())
  end
end
