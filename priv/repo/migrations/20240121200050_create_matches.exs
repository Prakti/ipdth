defmodule Ipdth.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches) do
      add :start_date, :utc_datetime_usec
      add :end_date, :utc_datetime_usec
      add :score_a, :integer
      add :score_b, :integer

      timestamps()
    end
  end
end
