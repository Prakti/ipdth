defmodule IpdthWeb.AuthZTest do
  use Ipdth.DataCase
  use ExUnitProperties

  alias IpdthWeb.AuthZ

  import Ipdth.AccountsFixtures
  import Ipdth.AgentsFixtures

  describe "user_admin?" do
    test "authorizes a user that has the user_admin role" do
      admin = admin_user_fixture()

      assert AuthZ.user_admin?(admin)
      assert AuthZ.user_admin?(admin.id)
    end

    test "rejects a user that does not have the user_amin role" do
      user = user_fixture()

      refute AuthZ.user_admin?(user)
      refute AuthZ.user_admin?(user.id)
    end

    property "rejects integers that have no user" do
      check all(illegal <- integer()) do
        refute AuthZ.user_admin?(illegal)
      end
    end

    property "rejects illegal values" do
      check all(illegal <- term()) do
        refute AuthZ.user_admin?(illegal)
      end
    end
  end

  describe "tournament_admin?" do
    test "authorizes a user that has the tournament_admin role" do
      admin = admin_user_fixture()

      assert AuthZ.tournament_admin?(admin)
      assert AuthZ.tournament_admin?(admin.id)
    end

    test "rejects a user that does not have the tournament_amin role" do
      user = user_fixture()

      refute AuthZ.tournament_admin?(user)
      refute AuthZ.tournament_admin?(user.id)
    end

    property "rejects integers that have no user" do
      check all(illegal <- integer()) do
        refute AuthZ.tournament_admin?(illegal)
      end
    end

    property "rejects illegal values" do
      check all(illegal <- term()) do
        refute AuthZ.tournament_admin?(illegal)
      end
    end
  end

  describe "agent_owner?" do
    test "authorizes the owner of an agent" do
      user = user_fixture()
      agent = agent_fixture(user)

      assert AuthZ.agent_owner?(user, agent)
      assert AuthZ.agent_owner?(user.id, agent)
    end

    test "rejects other users" do
      user = user_fixture()
      agent = agent_fixture(user)
      wrong_user = user_fixture()

      refute AuthZ.agent_owner?(wrong_user, agent)
      refute AuthZ.agent_owner?(wrong_user.id, agent)
    end

    property "rejects integers that have no user" do
      user = user_fixture()
      agent = agent_fixture(user)

      check all(illegal <- integer()) do
        refute AuthZ.agent_owner?(illegal, agent)
      end
    end

    property "rejects illegal values" do
      user = user_fixture()
      agent = agent_fixture(user)

      check all(illegal <- term()) do
        refute AuthZ.agent_owner?(illegal, agent)
      end
    end
  end
end
