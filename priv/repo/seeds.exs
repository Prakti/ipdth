# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Use the contexts to create fixtures. That way you can always have correct
# data seeded into the app.
#

alias Ipdth.Accounts
alias Ipdth.Accounts.User
alias Ipdth.Agents
alias Ipdth.Repo


create_user = fn user_params -> 
  with {:ok, user} <- Accounts.register_user(user_params) do
    Accounts.deliver_user_confirmation_instructions(user, fn token ->
      Accounts.confirm_user(token)
      "<irrelevant>"
    end)

    user
  end
end

Faker.start()

create_users = fn count ->
  Enum.map(1..count, fn _ ->
    user_params = %{
      email: Faker.Internet.user_name() <> "@ipdth.org",
      password: "0xBABAF0000000000000"
    }
    
    create_user.(user_params)
  end)
end

create_agents_for_user = fn user, count ->
  Enum.map(1..count, fn _ ->
    agent_attrs = %{
      bearer_token: "some bearer_token",
      description: Faker.Lorem.paragraph() |> String.slice(0, 254),
      name: Faker.Pokemon.name(),
      url: "http://localhost:4004/api/examples/pushover"
    }

    with {:ok, agent} = Agents.create_agent(user.id, agent_attrs) do
      agent
    end
  end)
end

create_agents_for_users = fn users, count ->
  Enum.map(users, fn user ->
    agents = create_agents_for_user.(user, count)
    {user, agents}
  end)
end


create_user.(%{
  email: "myself@prakti.org",
  password: "0xBABAF00000"
})

genesis_user = Accounts.get_user_by_email("myself@prakti.org")
               |> User.add_role(:user_admin)
               |> User.add_role(:tournament_admin)
               |> Repo.update()

users = create_users.(20)
users_with_agents = create_agents_for_users.(users, 10)
