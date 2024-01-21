defmodule Ipdth.Repo.Migrations.CreateParticipations do
  use Ecto.Migration

  def change do
    create table(:participations) do
      add :score, :integer
      add :ranking, :integer
      add :sign_up, :utc_datetime_usec
      add :status, :string
      add :details, :text

      timestamps()
    end
  end
end
