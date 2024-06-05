defmodule Ipdth.Agents.ConnectionTest do
  use Ipdth.DataCase
  use ExUnitProperties

  # Agent has a special meaning in the domain of our app.
  alias Agent, as: Shelf 

  import Ipdth.AgentsFixtures
  import Ipdth.AccountsFixtures

  alias Ipdth.Agents.Connection
  alias Ipdth.Agents.Connection.{PastResult, Request, MatchInfo}

  setup tags do
    if tags[:silence_logger] do
      # Store the current log level
      original_log_level = Logger.level()

      # Set the Logger level to :none to silence it
      :ok = Logger.configure(level: :none)

      # Ensure the Logger level is restored after the test
      on_exit(fn ->
        :ok = Logger.configure(level: original_log_level)
      end)
    end

    # Continue with the test
    :ok
  end

  def validate_req_body(req_body) do
    validate_past_result = fn past_result ->
      validator_map = %{
        "action" => &Dredd.validate_string/1,
        "points" => &Dredd.validate_number(&1, :integer)
      }

      Dredd.validate_map(past_result, validator_map)
    end

    validate_past_results = fn past_results ->
      Dredd.validate_list(past_results, validate_past_result)
    end

    validate_match_info = fn match_info ->
      validator_map = %{
        "type" => &Dredd.validate_string/1,
        "tournament_id" => &Dredd.validate_string/1,
        "match_id" => &Dredd.validate_string/1
      }

      Dredd.validate_map(match_info, validator_map)
    end

    validator_map = %{
      "round_number" => &Dredd.validate_number(&1, :integer),
      "match_info" => validate_match_info,
      "past_results" => validate_past_results
    }

    Dredd.validate_map(req_body, validator_map)
  end

  def http_status_code_gen() do
    ranges = [
      # Common success responses
      200..206,
      # Common redirection messages
      301,
      302,
      304,
      # Common client error responses
      400,
      401,
      403,
      404,
      405,
      406,
      408,
      409,
      410,
      411,
      412,
      413,
      414,
      415,
      422,
      429,
      # Common server error responses
      500,
      501,
      502,
      503,
      504,
      505
    ]

    ranges
    |> Enum.flat_map(fn
      range when is_integer(range) -> [range]
      range -> Enum.to_list(range)
    end)
    |> StreamData.member_of()
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

  describe "Connection.decide/2" do
    test "returns {:ok, decision} if the connected agent responds correctly" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      # Setup Bypass for a success case
      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        # Ensure that our client sends correct Headers
        req_headers = conn.req_headers

        assert Enum.find(req_headers, fn header ->
                 header == {"content-type", "application/json"}
               end)

        assert Enum.find(req_headers, fn header ->
                 header == {"authorization", "Bearer " <> agent_service_bearer_token()}
               end)

        assert Enum.find(req_headers, fn header -> header == {"accept", "application/json"} end)

        conn = Plug.run(conn, [{Plug.Parsers, [parsers: [:json], json_decoder: Jason]}])
        req_body = conn.body_params

        dataset = validate_req_body(req_body)
        assert dataset.valid?

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      assert {:ok, decision} = Connection.decide(agent, create_test_request())
      assert decision == :cooperate or decision == :compete
    end

    test "performs a retry with backoff in case of an error 500" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      {:ok, shelf} = Shelf.start_link(fn -> 0 end)

      Bypass.expect(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        request_count = Shelf.get_and_update(shelf, fn state -> { state, state + 1 } end)
        # We count the number of calls to the endpoint and only succeed on the second call
        if request_count == 1 do
          conn
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
          |> Plug.Conn.resp(500, agent_service_500_response())
        else
          conn
          |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
          |> Plug.Conn.resp(200, agent_service_success_response())
        end
      end)

      assert {:ok, decision} = Connection.decide(agent, create_test_request())
      assert decision == :cooperate or decision == :compete
    end

    property "performs a retry with backoff in case of an malformed data but status 200" do
      owner = user_fixture()

      check all malformed_response <- string(:ascii) do
        %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

        {:ok, store} = Agent.start_link(fn -> 0 end)

        Bypass.expect(bypass, "POST", "/decide", fn conn ->
          assert "POST" == conn.method

          request_count = Agent.get_and_update(store, fn state -> { state, state + 1 } end)
          # We count the number of calls to the endpoint and only succeed on the second call
          if request_count == 1 do
            conn
            |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
            |> Plug.Conn.resp(200, malformed_response)
          else
            conn
            |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
            |> Plug.Conn.resp(200, agent_service_success_response())
          end
        end)

        assert {:ok, decision} = Connection.decide(agent, create_test_request())
        assert decision == :cooperate or decision == :compete
      end
    end

    test "performs a retry with backoff in case the agent is temporarily offline" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      Bypass.expect(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      on_off_task = Task.async(fn ->
        Bypass.down(bypass)
        Process.sleep(4_000)
        Bypass.up(bypass)
        :ok
      end)

      assert {:ok, decision} = Connection.decide(agent, create_test_request())
      assert decision == :cooperate or decision == :compete

      assert :ok = Task.await(on_off_task)
    end
  end

  describe "Connection test/1" do
    test "returns :ok if the connected agent responds correctly" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      # Setup Bypass for a success case
      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
        assert "POST" == conn.method

        # Ensure that our client sends correct Headers
        req_headers = conn.req_headers

        assert Enum.find(req_headers, fn header ->
                 header == {"content-type", "application/json"}
               end)

        assert Enum.find(req_headers, fn header ->
                 header == {"authorization", "Bearer " <> agent_service_bearer_token()}
               end)

        assert Enum.find(req_headers, fn header -> header == {"accept", "application/json"} end)

        conn = Plug.run(conn, [{Plug.Parsers, [parsers: [:json], json_decoder: Jason]}])
        req_body = conn.body_params

        dataset = validate_req_body(req_body)
        assert dataset.valid?

        conn
        |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
        |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      assert :ok == Connection.test(agent)
    end

    test "returns :error if the connected agent is offline" do
      owner = user_fixture()
      agent = agent_fixture(owner, %{url: "http://localhost:4000/"})

      assert {:error, details} = Connection.test(agent)
      assert %Mint.TransportError{reason: :econnrefused} = details
    end

    @tag silence_logger: true
    property "returns :error if the connected agent is responding with garbage" do
      owner = user_fixture()

      check all(
              body <- string(:ascii),
              status <- http_status_code_gen()
            ) do
        %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)
        # Setup Bypass for misbehaving agent
        Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
          Plug.Conn.resp(conn, status, body)
        end)

        assert {:error, _} = Connection.test(agent)
      end
    end
  end
end
