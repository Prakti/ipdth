defmodule Ipdth.Tournaments.Tournament do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ipdth.Tournaments.{Participation, Tournament}
  alias Ipdth.Matches.Match

  @status_values [:created, :published, :signup_closed, :running, :aborted, :finished]

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
      :end_date,
      :round_number,
      :random_seed,
      :random_trace,
      :status
    ])
    |> validate_required([:name, :start_date, :round_number])
  end

  def update(%Tournament{status: :created} = tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :description, :start_date, :round_number, :random_seed])
    |> validate_required([:name, :start_date, :round_number])
    # TODO: 2024-08-28 - We need a 'signup_deadline' field
    # TODO: 2024-08-28 - We need a validator ensuring that 'signup_deadline' is earlier than start_date
  end

  def update(%Tournament{status: :published} = tournament, attrs) do
    tournament
    |> cast(attrs, [:name, :description])
    |> validate_required([:name, :start_date, :round_number])
  end

  def new(tournament, attrs) do
    tournament
    |> update(attrs)
    # TODO: 2024-04-28 - Introduce a Creator field and set creator
  end

  def publish(tournament) do
    change(tournament, status: :published)
  end

  def unpublish(tournament) do
    change(tournament, status: :created)
  end

  def close_signup(tournament) do
    change(tournament, status: :signup_closed)
  end

  def start(tournament) do
    change(tournament, status: :running)
  end

  def abort(tournament) do
    change(tournament, status: :aborted)
    # TODO: 2024-04-28 - Set the end date on abort
  end

  def finish(tournament) do
    change(tournament, status: :finished)
    # TODO: 2024-04-28 - Set the end date on finish
  end

end
