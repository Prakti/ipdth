defmodule Ipdth.Repo.Migrations.MatchesReferenceAgentsAndTournaments do
  use Ecto.Migration

  def up do
    alter table(:matches) do
      add :agent_a_id, :integer
      add :agent_b_id, :integer
      add :tournament_id, references(:tournaments)
    end
  end

  def down do
    alter table(:matches) do
      remove :tournament_id
      remove :agent_a_id
      remove :agent_b_id
    end
  end
end
