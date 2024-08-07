defmodule Ipdth.Repo.Migrations.RemoveRoundNumber do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      remove :round_number
    end
  end

  def down do
    alter table(:tournaments) do
      add :round_number, :integer
    end
  end
end
