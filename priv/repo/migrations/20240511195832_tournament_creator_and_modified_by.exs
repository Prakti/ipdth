defmodule Ipdth.Repo.Migrations.TournamentCreatorAndModifiedBy do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :creator_id, references(:users)
      add :last_modified_by_id, references(:users)
    end
  end

  def down do
    alter table(:tournaments) do
      remove :creator_id
      remove :last_modified_by_id
    end
  end
end
