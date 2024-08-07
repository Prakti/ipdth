defmodule Ipdth.Repo.Migrations.NewTournamentFields do
  use Ecto.Migration

  def up do
    alter table(:tournaments) do
      add :progress, :integer
      add :total_rounds, :integer
      add :current_round, :integer
      add :rounds_per_match, :integer
    end
  end

  def down do
    alter table(:tournaments) do
      remove :progress
      remove :total_rounds
      remove :current_round
      remove :rounds_per_match
    end
  end
end
