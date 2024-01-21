defmodule Ipdth.Repo.Migrations.LinkAgentToOwningUser do
  use Ecto.Migration

  def up do
    alter table(:agents) do
      add :owner_id, references(:users)
    end
  end

  def down do
    alter table(:agents) do
      remove :owner_id
    end
  end
end
