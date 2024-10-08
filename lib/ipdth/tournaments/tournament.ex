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

  @derive {
    Flop.Schema,
    filterable: [
      :name,
      :description,
      :status,
      :creator_email,
      :editor_email,
      :start_date,
      :rounds_per_match
    ],
    sortable: [
      :name,
      :status,
      :start_date,
      :end_date,
      :rounds_per_match
    ],
    default_order: %{
      order_by: [
        :name,
        :status,
        :start_date,
        :end_date,
        :rounds_per_match
      ],
      order_directions: [:asc, :asc, :desc, :desc, :asc]
    },
    default_limit: 10,
    adapter_opts: [
      join_fields: [
        creator_email: [
          binding: :creator,
          field: :email,
          ecto_type: :string
        ],
        editor_email: [
          binding: :last_modified_by,
          field: :email,
          ecto_type: :string
        ]
      ]
    ]
  }

  schema "tournaments" do
    field :name, :string
    field :status, Ecto.Enum, values: @status_values, default: :created
    field :description, :string
    field :start_date, :utc_datetime_usec
    field :end_date, :utc_datetime_usec
    field :random_seed, :string
    field :random_trace, :string
    field :progress, :integer
    field :total_rounds, :integer
    field :current_round, :integer
    field :rounds_per_match, :integer
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
      :rounds_per_match,
      :random_seed,
      :status
    ])
    |> validate_required([:name, :start_date, :rounds_per_match])
  end

  def update(%Tournament{status: :created} = tournament, attrs, actor_id) do
    tournament
    |> cast(attrs, [:name, :description, :start_date, :rounds_per_match, :random_seed])
    |> put_change(:last_modified_by_id, actor_id)
    |> validate_required([:name, :start_date, :rounds_per_match])

    # TODO: 2024-08-28 - We need a 'signup_deadline' field
    # TODO: 2024-08-28 - We need a validator ensuring that 'signup_deadline' is earlier than start_date
  end

  def update(%Tournament{status: :published} = tournament, attrs, actor_id) do
    tournament
    |> cast(attrs, [:name, :description])
    |> put_change(:last_modified_by_id, actor_id)
    |> validate_required([:name, :start_date, :rounds_per_match])
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
