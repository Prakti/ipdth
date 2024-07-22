defmodule Ipdth.Agents.Connection do
  @moduledoc """
  Module modeling the connection to an Agent and handling the communication
  with an Agent.
  """

  require Logger

  alias Ipdth.Agents.ConnectionManager

  @default_config [
    connect_options: [timeout: 30_000],
    pool_timeout: 5_000,
    receive_timeout: 15_000
  ]

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
    auth = {:bearer, agent.bearer_token}

    # We can assertively use post! here because all error-handling is done
    # in ConnectionManager
    response =
      Req.new(json: decision_request, auth: auth, url: agent.url)
      |> Req.merge(get_config())
      |> Req.post!()

    case response.status do
      200 ->
        decision = evaluate_decision(response.body)
        ConnectionManager.report_decision_result(self(), agent.id, decision)

      # All error-handling is done in ConnectionManager, so we just let the
      # process crash and let it handle backoff and retry
      401 ->
        raise "401 Unauthorized - #{inspect(response.body)}"

      500 ->
        raise "500 Internal Server Error - #{inspect(response.body)}"

      status ->
        raise "HTTP Error - #{inspect(status)} - #{inspect(response.body)}"
    end
  end

  def test(agent) do
    auth = {:bearer, agent.bearer_token}
    test_request = create_test_request()

    response =
      Req.new(json: test_request, auth: auth, url: agent.url)
      |> Req.merge(get_config())
      |> Req.post!()

    result =
      case response.status do
        200 ->
          if response.body["action"] != nil do
            :ok
          else
            {:error, {:no_action_given, response.body}}
          end

        401 ->
          {:error, {:auth_error, response.body}}

        500 ->
          {:error, {:server_error, response.body}}

        _ ->
          {:error, {:undefined_error, response.status, response.body}}
      end

    ConnectionManager.report_test_result(self(), agent.id, result)
  end

  def get_config() do
    Application.get_env(:ipdth, Ipdth.Agents.Connection, @default_config)
  end

  def get_timeout() do
    [
      connect_options: [timeout: connect_timeout],
      pool_timeout: pool_timeout,
      receive_timeout: receive_timeout
    ] = get_config()

    connect_timeout + pool_timeout + receive_timeout
  end

  ###
  # Internal Functionality
  ###

  defp evaluate_decision(response_body) do
    case response_body["action"] do
      "Cooperate" -> {:ok, :cooperate}
      "cooperate" -> {:ok, :cooperate}
      "Defect" -> {:ok, :defect}
      "defect" -> {:ok, :defect}
      decision -> raise "Error: #{inspect(decision)} is not a valid Decision."
    end
  end

  defp create_test_request() do
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
            action: "Defect",
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
