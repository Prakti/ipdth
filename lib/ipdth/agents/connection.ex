defmodule Ipdth.Agents.Connection do

  defmodule Request do
    @derive Jason.Encoder
    defstruct round_number: -1, past_results: [], match_info: %{}
  end

  defmodule PastResult do
    @derive Jason.Encoder
    defstruct action: "", points: 0
  end

  defmodule MatchInfo do
    @derive Jason.Encoder
    defstruct type: "Test Match", tournament_id: "", match_id: ""
  end

  def decide(_agent, _decision_request) do
    # TODO: 2024-03-17 - Implement
  end

  def test(agent) do
    # Do something
    auth = {:bearer, agent.bearer_token}
    test_request = create_test_request()

    req = Req.new(json: test_request, auth: auth, url: agent.url)

    with {:ok, response} <- Req.post(req) do
      case response.status do
        200 -> validate_body(response, test_request)
        401 -> {:error, fill_error_details(:auth_error, response)}
        500 -> {:error, fill_error_details(:server_error, response)}
        _ -> {:error, fill_error_details(:undefined_error, response)}
      end
    end
  end

  def validate_body(response, _test_request) do
    json =  response.body
    if json["action"]  != nil do
      :ok
    else
      {:error, {:no_action_given, json}}
    end
  end

  def fill_error_details(error, _response) do
    # TODO: 2024-03-17 - Do proper inspection of response body.
    {error, "TODO: fill in more details!"}
  end


  def create_test_request() do
    past_results = Enum.map(1..100, fn num -> 
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
