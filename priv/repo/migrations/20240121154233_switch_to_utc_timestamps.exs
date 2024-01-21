defmodule Ipdth.Repo.Migrations.SwitchToUtcTimestamps do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
      modify :confirmed_at, :utc_datetime_usec
    end

    alter table(:agents) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end

    alter table(:tournaments) do
      modify :inserted_at, :utc_datetime_usec
      modify :updated_at, :utc_datetime_usec
    end
  end

  def down do
    alter table(:users) do
      modify :inserted_at, :naive_datetime
      modify :updated_at, :naive_datetime
      modify :confirmed_at, :naive_datetime
    end

    alter table(:agents) do
      modify :inserted_at, :naive_datetime
      modify :updated_at, :naive_datetime
    end

    alter table(:tournaments) do
      modify :inserted_at, :naive_datetime
      modify :updated_at, :naive_datetime
    end
  end
end
