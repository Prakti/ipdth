defmodule Ipdth.Repo.Migrations.PutRoundsIntoSeparateTable do
  use Ecto.Migration

  def up do
    create table(:rounds) do
      add :action_a, :string
      add :action_b, :string
      add :score_a, :integer
      add :score_b, :integer
      add :start_date, :utc_datetime_usec
      add :end_date, :utc_datetime_usec
      add :match_id, references(:matches)
    end

    alter table(:matches) do
      remove :rounds
    end
  end

  def down do
    drop table(:rounds)

    alter table(:matches) do
      add :rounds, {:array, :jsonb}, default: []
    end
  end
end
