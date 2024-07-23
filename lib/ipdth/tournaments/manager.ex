defmodule Ipdth.Tournaments.Manager do
  @moduledoc """
  This module regularly checks if a tournament has to be started as per it's
  official start date. In case one or more tournaments are identified to be
  started, this module spawns a Tournament.Runner task for each.
  """

  use GenServer

  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Runner

  # TODO: 2024-06-25 - Make check_interval configurable
  # One Second
  @check_interval 1_000

  defmodule State do
    @moduledoc false
    defstruct auto_mode: true,
              get_tournaments: &Tournaments.list_due_and_overdue_tournaments/1,
              start_tournament: &Runner.start/1
  end

  ## Client API

  def start_link(%State{} = state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link(_) do
    # TODO: 2024-07-23 - Think about loading initial state from config.
    case Application.get_env(:ipdth, :environment, :prod) do
      :test ->
        start_link(%State{
          auto_mode: false,
          # TODO: 2024-06-25 - Replace dummy functions with better ones
          get_tournaments: fn _timestamp -> [] end,
          start_tournament: fn _tournament -> {:ok, nil} end
        })

      :dev ->
        start_link(%State{
          auto_mode: false
        })

      _ ->
        start_link(%State{})
    end
  end

  def set_manual_mode do
    GenServer.call(__MODULE__, :set_manual_mode)
  end

  def set_auto_mode do
    GenServer.call(__MODULE__, :set_auto_mode)
  end

  def check_and_start_tournaments(timestamp) do
    GenServer.cast(__MODULE__, {:check_and_and_start_tournaments, timestamp})
  end

  ## Server Callbacks

  @impl true
  def init(state) do
    if state.auto_mode do
      check_and_start_tournaments(DateTime.utc_now())
    end

    {:ok, state}
  end

  @impl true
  def handle_call(:set_manual_mode, _from, state) do
    {:reply, :ok, %State{state | auto_mode: false}}
  end

  @impl true
  def handle_call(:set_auto_mode, _from, state) do
    schedule_next_check(@check_interval)
    {:reply, :ok, %State{state | auto_mode: true}}
  end

  @impl true
  def handle_cast({:check_and_start_tournaments, timestamp}, state) do
    # We're using dependency-injected Functions here for besster testability
    # Otherwise the SQL Sandbox of Ecto would break, breaking all other tests!
    state.get_tournaments.(timestamp)
    |> Enum.each(state.start_tournament)

    if state.auto_mode do
      schedule_next_check(@check_interval)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:trigger_check, state) do
    if state.auto_mode do
      check_and_start_tournaments(DateTime.utc_now())
    end

    {:noreply, state}
  end

  ## Internal Implementation

  def schedule_next_check(wait_time) do
    Process.send_after(self(), :trigger_check, wait_time)
  end
end
