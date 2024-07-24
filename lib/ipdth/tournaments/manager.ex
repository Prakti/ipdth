defmodule Ipdth.Tournaments.Manager do
  @moduledoc """
  This module regularly checks if a tournament has to be started as per it's
  official start date. In case one or more tournaments are identified to be
  started, this module spawns a Tournament.Runner task for each.
  """

  use GenServer

  alias Ipdth.Tournaments
  alias Ipdth.Tournaments.Runner

  defmodule State do
    @moduledoc false
    defstruct auto_mode: true,
              get_tournaments: &Tournaments.list_due_and_overdue_tournaments/1,
              start_tournament: &Runner.start/1,
              check_interval: 1_000
  end

  ## Client API
  def start_link(:load_config) do
    Application.get_env(:ipdth, __MODULE__)
    |> start_link()
  end

  def start_link(config, id \\ __MODULE__) do
    GenServer.start_link(__MODULE__, config, name: id)
  end

  def set_manual_mode do
    GenServer.call(__MODULE__, :set_manual_mode)
  end

  def set_auto_mode do
    GenServer.call(__MODULE__, :set_auto_mode)
  end

  def check_and_start_tournaments(timestamp) do
    check_and_start_tournaments(__MODULE__, timestamp)
  end

  def check_and_start_tournaments(server, timestamp) do
    GenServer.cast(server, {:check_and_start_tournaments, timestamp})
  end

  ## Server Callbacks
  @impl true
  def init(config) do
    init(config, %State{})
  end

  def init([{:check_interval, check_interval} | rest], %State{} = state) do
    init(rest, %State{state | check_interval: check_interval})
  end

  def init([{:start_tournament, start_tournament} | rest], %State{} = state) do
    init(rest, %State{state | start_tournament: start_tournament})
  end

  def init([{:get_tournaments, get_tournaments} | rest], %State{} = state) do
    init(rest, %State{state | get_tournaments: get_tournaments})
  end

  def init([{:auto_mode, auto_mode} | rest], %State{} = state) do
    init(rest, %State{state | auto_mode: auto_mode})
  end

  def init([_ | rest], %State{} = state) do
    init(rest, state)
  end

  def init([], %State{} = state) do
    if state.auto_mode do
      check_and_start_tournaments(self(), DateTime.utc_now())
    end

    {:ok, state}
  end

  @impl true
  def handle_call(:set_manual_mode, _from, state) do
    {:reply, :ok, %State{state | auto_mode: false}}
  end

  @impl true
  def handle_call(:set_auto_mode, _from, state) do
    schedule_next_check(state.check_interval)
    {:reply, :ok, %State{state | auto_mode: true}}
  end

  @impl true
  def handle_cast({:check_and_start_tournaments, timestamp}, state) do
    # We're using dependency-injected Functions here for besster testability
    # Otherwise the SQL Sandbox of Ecto would break, breaking all other tests!
    state.get_tournaments.(timestamp)
    |> Enum.each(state.start_tournament)

    if state.auto_mode do
      schedule_next_check(state.check_interval)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:trigger_check, state) do
    if state.auto_mode do
      check_and_start_tournaments(self(), DateTime.utc_now())
    end

    {:noreply, state}
  end

  ## Internal Implementation

  def schedule_next_check(wait_time) do
    Process.send_after(self(), :trigger_check, wait_time)
  end
end
