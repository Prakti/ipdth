defmodule Ipdth.Repo do
  use Ecto.Repo,
    otp_app: :ipdth,
    adapter: Ecto.Adapters.Postgres
end
