defmodule Ipdth.Repo.Migrations.CopyRoundNumberToRoundsPerMatch do
  use Ecto.Migration

  def up do
    execute "UPDATE tournaments SET rounds_per_match = round_number WHERE round_number IS NOT NULL"
  end

  def down do
    execute "UPDATE tournaments SET rounds_per_match = NULL"
  end
end
