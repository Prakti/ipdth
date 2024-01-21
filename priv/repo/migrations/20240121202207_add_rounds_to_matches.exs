defmodule Ipdth.Repo.Migrations.AddRoundsToMatches do
  use Ecto.Migration

  def up do
    alter table(:matches) do
      add :rounds, {:array, :jsonb}, default: []
    end
  end

  def down do
    alter table(:matches) do
      remove :rounds
    end
  end
end
