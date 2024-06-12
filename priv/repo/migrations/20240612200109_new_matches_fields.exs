defmodule Ipdth.Repo.Migrations.NewMatchesFields do

  use Ecto.Migration

  def up do
    alter table(:matches) do
      add :rounds_to_play, :integer
      add :status, :string
    end
  end

  def down do
    alter table(:matches) do
      remove :rounds_to_play
      remove :status
    end
  end

end
