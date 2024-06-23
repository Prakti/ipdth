defmodule Ipdth.Tournaments.Manager do
  use GenServer

  alias Ipdth.Tournaments

  #@max_interval :timer.minutes(1)

  ## Client API

  def start_link(%{manual_mode: manual_mode}) when is_boolean(manual_mode) do
    start_link(manual_mode)
  end

  def start_link(manual_mode) when is_boolean(manual_mode) do
    GenServer.start_link(__MODULE__, %{manual_mode: manual_mode}, name: __MODULE__)
  end

  def set_manual_mode do
    GenServer.call(__MODULE__, :set_manual_mode)
  end

  def set_auto_mode do
    GenServer.call(__MODULE__, :set_auto_mode)
  end

  ## Server Callbacks

  @impl true
  def init(state) do
    unless state.manual_mode do
      {:ok, state, {:continue, :resume_auto_mode}}
    end

    {:ok, state}
  end

  @impl true
  def handle_continue(:resume_auto_mode, state) do
    # TODO: 2024-05-20 - Check if there are running tournaments that need to be restarted after a crash
    {:ok, _started_tournaments} = check_and_start_tournaments(DateTime.utc_now())

    # TODO: 2024-05-20 - Determine when the next check for due tournaments should happen
    # TODO: 2024-05-20 - Schedule the next check for due tournaments
    # TODD: 2024-06-16 - Don't start Tournaments with only one parcitipant
    {:noreply, state}
  end

  @impl true
  def handle_call(:set_manual_mode, _from, _state) do
    {:reply, :ok, %{manual_mode: true}}
  end

  @impl true
  def handle_call(:set_auto_mode, _from, _state) do
    # TODO: 2024-05-20 - Check if there are running tournaments that need to be restarted after a crash
    # TODO: 2024-05-20 - Check if there are due or overdue tournaments thatneed to be started and start them
    # TODO: 2024-05-20 - Determine when the next check for due tournaments should happen
    # TODO: 2024-05-20 - Schedule the next check for due tournaments
    {:reply, :ok, %{manual_mode: false}}
  end

  @impl true
  def handle_info({:check_and_and_start_tournaments, timestamp}, state) do
    check_and_start_tournaments(timestamp)

    unless state.manual_mode do
      # TODO: 2024-05-20 - Determine when the next check for due tournaments should happen
      # TODO: 2024-05-20 - Schedule the next check for due tournaments
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:trigger_check}, state) do
    unless state.manual_mode do
      Process.send(self(), {:check_and_and_start_tournaments, DateTime.utc_now()}, [])
    end

    {:noreply, state}
  end

  ## Internal Implementation

  defp check_and_start_tournaments(timestamp) do
    # TODO: 2024-05-20 - Spawn a TournamentRunner for each tournament
    Tournaments.list_due_and_overdue_tournaments(timestamp)
    |> Enum.each(&start_tournament/1)
  end

  defp start_tournament(_tournament) do
    # TODO: 2024-06-13 - Start a TournamentRunner as a Task
  end

  #defp next_check_interval() do
    # Just check each x seconds and be done!


  #end

end
