defmodule Ipdth.Tournaments.ManagerTest do
  use Ipdth.DataCase
  use ExUnitProperties

  import Ecto.Query, warn: false

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures
  import Ipdth.TournamentsFixtures

  alias Agent, as: Shelf

  alias Ipdth.Repo
  alias Ipdth.Tournaments.Manager

  describe "tournaments/manager" do
    test "starts due and overdue tournaments on startup" do
      # Set TournamentManager to manual_mode
      # Create Admin user
      # Create two Matches
      # Create Tournament with start-date now, 1 Round per match and 2 Agents
      # Create Tournament with start-date 1h in past, 1 Round per match and 2 Agents
      # Listen to Pub/Sub messages for finished tournaments
      # Set TournamentManager to auto_mode
      # Wait for PubSub Messages that tournaments have finished
    end

    test "does not start tournaments on startup that are not yet due" do
    end

    test "resumes running tournaments on startup" do
    end

  end

end
