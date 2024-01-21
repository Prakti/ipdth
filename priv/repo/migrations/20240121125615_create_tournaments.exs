defmodule Ipdth.Repo.Migrations.CreateTournaments do
  use Ecto.Migration

  def change do
    create table(:tournaments) do
      add :name, :string
      add :description, :string
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :round_number, :integer
      add :random_seed, :string
      add :random_trace, :string
      add :status, :string

      timestamps()
    end
  end
end
