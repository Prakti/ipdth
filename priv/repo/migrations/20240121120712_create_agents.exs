defmodule Ipdth.Repo.Migrations.CreateAgents do
  use Ecto.Migration

  def change do
    create table(:agents) do
      add :name, :string
      add :description, :string
      add :url, :string
      add :bearer_token, :string
      add :status, :string

      timestamps()
    end
  end
end
