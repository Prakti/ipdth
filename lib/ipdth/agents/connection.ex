defmodule Ipdth.Agents.Connection do
  @moduledoc """
  Module modeling the connection to an Agent and handling the communication
  with an Agent.
  """

  # TODO: 2024-05-26 - Read config values for backoff and retries
  @max_retries 3
  @backoff_duration 5_000

  defmodule State do
    @moduledoc """
    Struct representing the internal state of the connection
    """
    defstruct agent: nil, decision_request: nil, errors: [], retries: 0
  end

  defmodule Request do
    @moduledoc """
    Struct representing the Request sent to an Agent.
    """

    @derive Jason.Encoder
    defstruct round_number: -1, past_results: [], match_info: %{}
  end

  defmodule PastResult do
    @moduledoc """
    Struct representing a past result from a round.
    """

    @derive Jason.Encoder
    defstruct action: "", points: 0
  end

  defmodule MatchInfo do
    @moduledoc """
    Struct representing information around a match.
    """

    @derive Jason.Encoder
    defstruct type: "Test Match", tournament_id: "", match_id: ""
  end

  def decide(agent, decision_request) do
    decide(%State{ agent: agent, decision_request: decision_request })
  end

  def decide(%State{} = state) do
    agent = state.agent
    decision_request = state.decision_request
    auth = {:bearer, agent.bearer_token}
    try do
      req = Req.new(json: decision_request, auth: auth, url: agent.url)

      case Req.post(req) do
        {:ok, response} ->
          handle_http_response(state, response)
        {:error, exception} ->
          log_exception_and_backoff(state, exception)
      end
    rescue
      exception -> log_exception_and_backoff(state, exception)
    end
  end

  defp handle_http_response(%State{} = state, response) do
    case response.status do
      200 ->
        # TODO: 2024-05-29 - Ensure that Agent is 'active'
        interpret_decision(response)
      _ ->
        {:error, log_http_error_and_backoff(state, response) }
    end
  end

  defp log_http_error_and_backoff(%State{} = state, response) do
    details =
      case response.status do
        401 -> "Authentification Error: " <> response.body <> "\n"
        500 -> "Internal Server Error: " <> response.body <> "\n"
        _ -> "Undefined Error: " <> response.body <> "\n"
      end

    # TODO: 2024-05-29 - TODO: write error into DB (not via 'Agents' module)

    state = %State{state | errors: [details | state.errors]}

    if state.retries <= @max_retries do
      # TODO: 2024-05-28 - Compute backoff duration
      Process.sleep(@backoff_duration)
      decide(%State{ state | retries: state.retries + 1 })
    else
      {:agent_nonresponsive, state.errors}
    end
  end

  defp log_exception_and_backoff(%State{} = state, exception) do
    details = "Exception: " <> Exception.message(exception) <> "\n"
    state = %State{state | errors: [details | state.errors]}

    # TODO: 2024-05-29 - TODO: write error into DB (not via 'Agents' module)

    if state.retries <= @max_retries do
      # TODO: 2024-05-29 - Compute backoff duration
      decide(%State{ state | retries: state.retries + 1 })
    else
      {:runtime_exception, state.errors}
    end
  end

  def test(agent) do
    pid =
      Task.Supervisor.async_nolink(Ipdth.ConnectionTestSupervisor, fn ->
        auth = {:bearer, agent.bearer_token}
        test_request = create_test_request()

        req = Req.new(json: test_request, auth: auth, url: agent.url)

        with {:ok, response} <- Req.post(req) do
          case response.status do
            200 -> validate_body(response)
            401 -> {:error, {:auth_error, response.body}}
            500 -> {:error, {:server_error, response.body}}
            _ -> {:error, {:undefined_error, response.body}}
          end
        end
      end)

    case Task.yield(pid) do
      {:ok, result} ->
        Task.shutdown(pid)
        result

      {:exit, {exception, _stacktrace}} when is_exception(exception) ->
        Task.shutdown(pid)
        {:error, {:runtime_exception, Exception.message(exception)}}

      {:exit, {reason, details}} ->
        Task.shutdown(pid)
        {:error, {reason, details}}
    end
  end

  def interpret_decision(response) do
    json = response.body

    case json["action"] do
      "Cooperate" -> {:ok, :cooperate}
      "cooperate" -> {:ok, :cooperate}
      _ -> {:ok, :compete}
    end
  end

  def validate_body(response) do
    json = response.body

    if json["action"] != nil do
      :ok
    else
      {:error, {:no_action_given, json}}
    end
  end

  def create_test_request() do
    past_results =
      Enum.map(1..100, fn num ->
        modnum = Integer.mod(num, 2)

        if modnum == 0 do
          %PastResult{
            action: "Cooperate",
            points: modnum
          }
        else
          %PastResult{
            action: "Compete",
            points: modnum + 1
          }
        end
      end)

    %Request{
      round_number: 1,
      match_info: %MatchInfo{},
      past_results: past_results
    }
  end
end
