defmodule Ipdth.Repo.Migrations.AddTournamentRoundToMatch do
  use Ecto.Migration

  def up do
    alter table(:matches) do
      modify :agent_a_id, references(:agents)
      modify :agent_b_id, references(:agents)
      add :tournament_round, :integer
    end
  end

  def down do
    alter table(:matches) do
      remove :agent_a_id
      remove :agent_b_id
      remove :tournament_round
      add :agent_a_id, :integer
      add :agent_b_id, :integer
    end
  end
end
