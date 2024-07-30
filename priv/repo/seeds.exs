# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Use the contexts to create fixtures. That way you can always have correct
# data seeded into the app.
#

alias Ipdth.Tournaments
alias Ipdth.Accounts
alias Ipdth.Agents

create_user = fn user_params ->
  {:ok, user} = Accounts.seed_user(user_params)
  user
end

Faker.start()

create_users = fn count ->
  Enum.map(1..count, fn _ ->
    user_params = %{
      email: Faker.Internet.user_name() <> "@ipdth.org",
      password: "BarbarasRhabarberBar"
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

create_tournaments = fn admin, count ->
  Enum.map(1..count, fn _ ->
    tournament_attrs = %{
      name: Faker.Fruit.En.fruit() <> " " <> Faker.Nato.callsign(),
      description: Faker.Lorem.paragraph() |> String.slice(0, 254),
      start_date: Faker.DateTime.forward(100),
      round_number: Faker.random_between(50, 200),
      random_seed: Faker.String.base64(20)
    }

    with {:ok, tournament} = Tournaments.create_tournament(tournament_attrs, admin.id) do
      tournament
    end
  end)
end

publish_tournaments = fn admin, tournaments, count ->
  Enum.take_random(tournaments, count)
  |> Enum.map(fn tournament ->
    with {:ok, published_tournament} = Tournaments.publish_tournament(tournament, admin.id) do
      published_tournament
    end
  end)
end

sign_up_agents = fn user, agents, published_tournaments ->
  tournament_count = div(length(published_tournaments), 2)
  agent_count = div(length(agents), 2)

  Enum.take_random(agents, agent_count)
  |> Enum.map(fn agent ->
    Enum.take_random(published_tournaments, tournament_count)
    |> Enum.map(fn tournament ->
      Tournaments.sign_up(tournament, agent, user.id)
    end)
  end)
end

sign_up_all_agents = fn users_with_agents, published_tournaments ->
  Enum.each(users_with_agents, fn {user, agents} ->
    sign_up_agents.(user, agents, published_tournaments)
  end)
end

###
# Generate Users
###
{:ok, genesis_user} =
  Accounts.seed_user(%{
    "email" => "myself@prakti.org",
    "password" => "BarbarasRhabarberBar",
    "roles" => [:tournament_admin, :user_admin]
  })

users = create_users.(20)

###
# Generate Agents
###
admin_agents = create_agents_for_user.(genesis_user, 10)
users_with_agents = create_agents_for_users.(users, 10)

###
# Generate Tournaments
###
tournaments = create_tournaments.(genesis_user, 50)
published_tournaments = publish_tournaments.(genesis_user, tournaments, 25)

###
# Sign Up Agents to Tournament
###

sign_up_agents.(genesis_user, admin_agents, published_tournaments)
sign_up_all_agents.(users_with_agents, published_tournaments)
