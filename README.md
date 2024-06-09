# IPDTH - Iterated Prisoner's Dilemma Tournament Hub

The Iterated Prisoner's Dilemma Tournament Hub (IPDTH) is a central platform for organizing and conducting tournaments based on the iterated prisoner's dilemma.

## Iterated Prisoner's Dilemma

The iterated prisoner's dilemma is a classic game theory scenario where two players repeatedly engage in a game where they can either cooperate or defect. Currently, scores are computed as follows:

| Player A's Choice | Player B's Choice | Player A's Score | Player B's Score |
|-------------------|-------------------|------------------|------------------|
| Cooperate         | Cooperate         | 3                | 3                |
| Cooperate         | Defect            | 0                | 5                |
| Defect            | Cooperate         | 5                | 0                |
| Defect            | Defect            | 1                | 1                |

### Explanation:
- **Both players cooperate:** Each player receives a score of 3.
- **Player A cooperates, Player B defects:** Player A receives a score of 0, and Player B receives a score of 5.
- **Player A defects, Player B cooperates:** Player A receives a score of 5, and Player B receives a score of 0.
- **Both players defect:** Each player receives a score of 1.

## Agent Flexibility and API Specification

To allow maximum flexibility, all Agents participating on the hub, have to be hosted individually and adhere to the API specification found in `api_spec`. This in turn gives developers the freedom to choose any technology stack and implentation strategy they like.

## Dependencies

- Erlang/OTP Version >= 26
- Elixir >= 1.16.2
- PostgreSQL >= 16
- NodeJS >= 20

## Running the Hub Locally for development
- Clone the repo
- Get a PostgreSQL server running
- Install required dependencies: `mix deps.get`
- Crate the database: `mix ecto.create`
- Migrate the database: `mix ecto.migrate`
- Start the server: `mix phx.server`
- Visit `http://localhost:4000`

Instead of starting the server via `mix phx.server` you can run it inside an IEx shell via `iex -S mix phx.server`.

### Seeding Data for development
- You can seed example data using `mix run /priv/repo/seeds.exs` (**Warning** creates lots of data!)
- You can reset and reseed the database using `mix ecto.reset`
- If you only want to reset the database: `mix ecto.drop && mix ecto.create && mix ecto.migrate`

### Further Help
Look into the `mix.exs` file for futher aliases and shortcuts. You can get a list of available `mix` commands using `mix help`.

## Running the Hub in Production
Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Contributing
Contributions are welcome! Please read `CODE_OF_CONDUCT.md` before contributing. To contribute, fork the repository, create a new branch for your feature or bugfix, and submit a pull request with a clear description of your changes.

## Licensing
This project is licensed under the MIT license. See the file `LICENSE` for more details.

## Security
Even though the IPDTH is only a hobby project, security will not be neglected. That being said, all contributors to this project are humans and thus infallible. Found a securitiy issue? 
- **Please do not open GitHub issues for security vulnerabilities, those are publicly accessible!!!** Instead se
- Get in touch via e-mail: `myself@prakti.org`

