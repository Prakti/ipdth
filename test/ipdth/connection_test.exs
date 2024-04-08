defmodule Ipdth.Agents.ConnectionTest do
  use Ipdth.DataCase

  import Ipdth.AgentsFixtures
  import Ipdth.AccountsFixtures

  alias Ipdth.Agents.Agent
  alias Ipdth.Agents.Connection

  # TODO: 2024-03-23 - Property Test the Connection using StreamData

  def validate_req_body(req_body) do
    validate_past_result = fn past_result ->
      validator_map = %{
        "action" => &Dredd.validate_string/1,
        "points" =>  &Dredd.validate_number(&1, :integer)
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

  describe "Connection" do

    test "test/1 returns :ok if the connected agent responds correctly" do
      owner = user_fixture()
      %{agent: agent, bypass: bypass} = agent_fixture_and_mock_service(owner)

      # Setup Bypass for a success case
      Bypass.expect_once(bypass, "POST", "/decide", fn conn ->
            assert "POST" == conn.method

            # Ensure that our client sends correct Headers
            req_headers = conn.req_headers
            assert Enum.find(req_headers, fn header -> header == {"content-type", "application/json"} end)
            assert Enum.find(req_headers, fn header -> header == {"authorization", "Bearer " <> agent_service_bearer_token()} end)
            assert Enum.find(req_headers, fn header -> header == {"accept", "application/json"} end)

            conn = Plug.run(conn, [{Plug.Parsers, [parsers: [:json], json_decoder: Jason]}])
            req_body = conn.body_params

            dataset = validate_req_body(req_body)
            assert dataset.valid?

            conn
            |> Plug.Conn.merge_resp_headers([{"content-type", "application/json"}])
            |> Plug.Conn.resp(200, agent_service_success_response())
      end)

      assert :ok == Ipdth.Agents.Connection.test(agent)
    end

  end

end
