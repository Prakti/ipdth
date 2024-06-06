defmodule Ipdth.Repo.Migrations.CreateConnectionErrors do
  use Ecto.Migration

  def change do
    create table(:connection_errors) do
      add :error_message, :text
      add :agent_id, references(:agents, on_delete: :delete_all)

      timestamps()
    end

    create index(:connection_errors, [:agent_id])
  end
end
