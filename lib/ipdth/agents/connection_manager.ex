defmodule Ipdth.Agents.ConnectionManager do

  import Ecto.Query, warn: false

  require Logger

  alias Ipdth.Repo
  alias Ipdth.Agents
  alias Ipdth.Agents.{Agent, Connection, ConnectionError}

  use GenServer

  # TODO: 2024-05-26 - Read config values for backoff and retries
  @max_retries 3
  @backoff_duration 5_000

  ###
  # Public API
  ###

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def decide(%Agent{id: agent_id}, decision_request) do
    timeout = (@max_retries + 1) * @backoff_duration
    GenServer.call(__MODULE__, {:decide, agent_id, decision_request}, timeout)
  end

  def decide(agent_id, decision_request) do
    timeout = (@max_retries + 1) * @backoff_duration
    GenServer.call(__MODULE__, {:decide, agent_id, decision_request}, timeout)
  end

  def test(%Agent{id: agent_id}) do
    timeout = (@max_retries + 1) * @backoff_duration
    GenServer.call(__MODULE__, {:test, agent_id}, timeout)
  end

  def test(agent_id) do
    timeout = (@max_retries + 1) * @backoff_duration
    GenServer.call(__MODULE__, {:test, agent_id}, timeout)
  end

  def report_decision_result(task_pid, agent_id, decision) do
    GenServer.cast(__MODULE__, {:decision_result, task_pid, agent_id, decision})
  end

  def report_test_result(task_pid, agent_id, result) do
    GenServer.cast(__MODULE__, {:test_result, task_pid, agent_id, result})
  end

  ###
  # Internal Callback Implementation
  ###

  defmodule BackoffInfo do
    defstruct [
      agent_id: nil,
      retry_count: nil,
      backoff_duration: nil,
    ]
  end

  defmodule TaskInfo do
    defstruct [
      task_pid: nil,
      agent_id: nil,
      caller_pid: nil,
      decision_request: nil,
      test?: false
    ]
  end

  defmodule State do
    defstruct backoff_info: %{}, task_info: %{}, task_supervisor: nil
  end

  @impl true
  def init(_) do
    {:ok, pid} = Task.Supervisor.start_link()
    {:ok, %State{ task_supervisor: pid}}
  end

  @impl true
  def handle_call({:decide, agent_id, decision_request}, from, state) do
    Process.send(self(), {:try_decide, agent_id, decision_request, from}, [])
    {:noreply, state}
  end

  @impl true
  def handle_call({:test, agent_id}, from, state) do
    case Map.get(state.backoff_info, agent_id) do
      nil ->
          with {:ok, task_pid} <- start_test_task(state, agent_id) do
            Process.monitor(task_pid)

            task_info = %TaskInfo{
              task_pid: task_pid,
              agent_id: agent_id,
              caller_pid: from,
              test?: true
            }

            {:noreply, %State{ state |
              task_info: Map.put(state.task_info, task_pid, task_info)
            }}
          else
            error ->
              {:reply, {:error, error}}
          end
      _ ->
          {:reply, {:error, :agent_in_backoff}, state}
    end
  end

  @impl true
  def handle_info({:try_decide, agent_id, decision_request, from}, state) do
    case Map.get(state.backoff_info, agent_id) do
      nil ->
          # Agent is not backing off, do a request
          message = {:do_decide, agent_id, decision_request, from}
          Process.send(self(), message, [])
          {:noreply, state}
      %BackoffInfo{} = backoff_info ->
        # Agent is already in backof, postpone request by current backoff_duration
        if backoff_info.retry_count < @max_retries do
          message = {:try_decide, agent_id, decision_request, from}
          Process.send_after(self(), message, backoff_info.backoff_duration)
          {:noreply, state}
        else
          GenServer.reply(from, {:error, :max_retries_exceeded})
          {:noreply, state}
        end
    end
  end

  @impl true
  def handle_info({:do_decide, agent_id, decision_request, from}, state) do
    with {:ok, task_pid} <- start_decision_task(state, agent_id, decision_request) do
      Process.monitor(task_pid)

      task_info = %TaskInfo{
        task_pid: task_pid,
        agent_id: agent_id,
        caller_pid: from,
        decision_request: decision_request
      }

      {:noreply, %State{ state |
        task_info: Map.put(state.task_info, task_pid, task_info)
      }}
      # TODO: 2024-06-10 - We need to handle the error case here!
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    case reason do
      :normal ->
        {:noreply, state}
      :noproc ->
        {:noreply, state}
      reason ->
        handle_crash(state, pid, reason)
    end
  end

  @impl true
  def handle_cast({:decision_result, task_pid, agent_id, decision}, state) do
    activate_agent(agent_id)
    task_info = Map.get(state.task_info, task_pid)
    GenServer.reply(task_info.caller_pid, decision)

    updated_backoff_info = Map.delete(state.backoff_info, agent_id)
    updated_task_info = Map.delete(state.task_info, task_pid)

    updated_state = %State{ state |
      backoff_info: updated_backoff_info,
      task_info: updated_task_info
    }

    {:noreply, updated_state}
  end

  @impl true
  def handle_cast({:test_result, task_pid, agent_id, result}, state) do
    case result do
      :ok ->
        activate_agent(agent_id)
      {:error, reason} ->
        log_error(agent_id, reason)
        error_agent(agent_id)
    end

    task_info = Map.get(state.task_info, task_pid)
    GenServer.reply(task_info.caller_pid, result)

    updated_backoff_info = Map.delete(state.backoff_info, agent_id)
    updated_task_info = Map.delete(state.task_info, task_pid)

    updated_state = %State{ state |
      backoff_info: updated_backoff_info,
      task_info: updated_task_info
    }

    {:noreply, updated_state}
  end

  ###
  # Private Internals
  ###

  defp start_decision_task(state, agent_id, decision_request) do
    try do
      agent = Agents.get_agent!(agent_id)
      Task.Supervisor.start_child(state.task_supervisor, Connection, :decide, [agent, decision_request])
    rescue
      error -> Logger.warning("Could not start task for decision request. Maybe a deleted Agent. #{inspect(error)}")
    end
  end

  defp start_test_task(state, agent_id) do
    try do
      agent = Agents.get_agent!(agent_id)
      Task.Supervisor.start_child(state.task_supervisor, Connection, :test, [agent])
    rescue
      error -> Logger.warning("Could not start task for test request. Maybe a deleted Agent. #{inspect(error)}")
    end
  end

  defp log_error(agent_id, reason) do
    try do
      error_message =
        if is_exception(reason) do
          Exception.message(reason)
        else
          inspect(reason, pretty: true)
        end

      Repo.transaction(fn ->
        %ConnectionError{}
        |> ConnectionError.changeset(%{agent_id: agent_id, error_message: error_message})
        |> Repo.insert()

        query = from e in ConnectionError,
                where: e.agent_id == ^agent_id,
                order_by: [desc: e.inserted_at],
                offset: 50,
                select: e.id

        Repo.delete_all(from e in ConnectionError, where: e.id in subquery(query))
      end)
    rescue
      error ->
        message = "Could not write ErrorLog for agent #{agent_id}, " <>
                  "because #{inspect(error, pretty: true)}; " <>
                  "initial error was #{inspect(reason, pretty: true)}"
        Logger.warning(message)
    end
  end

  defp handle_crash(state, pid, reason) do
    try do
      task_info = Map.get(state.task_info, pid)

      log_error(task_info.agent_id, reason)

      if task_info.test? do
        handle_test_crash(state, task_info, pid, reason)
      else
        handle_decision_crash(state, task_info, pid)
      end
    rescue
      error ->
        msg = "ConnectionManager cannot handle :DOWN message from Connection. " <>
              "Reason: #{inspect(error, pretty: true)}. " <>
              ":DOWN reason was #{inspect(reason, pretty: true)}"
        Logger.warning(msg)
        {:noreply, state}
    end
  end

  defp handle_decision_crash(state, task_info, pid) do
    %TaskInfo{
      agent_id: agent_id,
      caller_pid: caller_pid,
      decision_request: decision_request,
    } = task_info

    backoff_agent(agent_id)

    backoff_info =
      case Map.get(state.backoff_info, agent_id) do
        nil ->
          %BackoffInfo{
            agent_id: agent_id,
            retry_count: 0,
            backoff_duration: @backoff_duration,
          }

        backoff_info ->
          %BackoffInfo{ backoff_info |
            retry_count: backoff_info.retry_count + 1
          }
      end

    if backoff_info.retry_count < @max_retries do
      message = {:do_decide, agent_id, decision_request, caller_pid}
      updated_state = %State{ state |
        backoff_info: Map.put(state.backoff_info, agent_id, backoff_info),
        task_info: Map.delete(state.task_info, pid)
      }
      Process.send_after(self(), message, @backoff_duration)
      {:noreply, updated_state}
    else
      updated_state = %State{ state |
        backoff_info: Map.delete(state.backoff_info, agent_id),
        task_info: Map.delete(state.task_info, pid)
      }

      GenServer.reply(caller_pid, {:error, :max_retries_exceeded})
      {:noreply, updated_state}
    end
  end

  def handle_test_crash(state, task_info, pid, reason) do
    %TaskInfo{
      agent_id: agent_id,
      caller_pid: caller_pid,
    } = task_info

    error_agent(agent_id)

    updated_state = %State{ state |
      backoff_info: Map.delete(state.backoff_info, agent_id),
      task_info: Map.delete(state.task_info, pid)
    }

    GenServer.reply(caller_pid, {:error, reason})
    {:noreply, updated_state}
  end

  defp activate_agent(agent_id) do
    try do
      Agents.get_agent!(agent_id)
      |> Agent.activate()
      |> Repo.update()
    rescue
      error -> Logger.warning("Could not update Agent. Maybe a deleted Agent. #{inspect(error)}")
    end
  end

  defp backoff_agent(agent_id) do
    try do
      Agents.get_agent!(agent_id)
      |> Agent.backoff()
      |> Repo.update()
    rescue
      error -> Logger.warning("Could not update Agent. Maybe a deleted Agent. #{inspect(error)}")
    end
  end

  defp error_agent(agent_id) do
    try do
      Agents.get_agent!(agent_id)
      |> Agent.error()
      |> Repo.update()
    rescue
      error -> Logger.warning("Could not update Agent. Maybe a deleted Agent. #{inspect(error)}")
    end
  end

end
