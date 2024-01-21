defmodule Ipdth.Repo.Migrations.LinkParticipationToAgentAndTournament do
  use Ecto.Migration

  def up do
    alter table(:participations) do
      add :tournament_id, references(:tournaments)
      add :agent_id, references(:agents)
    end
  end

  def down do
    alter table(:participations) do
      remove :tournament_id
      remove :agent_id
    end
  end
end
