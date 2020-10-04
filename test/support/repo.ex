defmodule ExZample.Repo do
  use Ecto.Repo,
    otp_app: :ex_zample,
    adapter: Ecto.Adapters.Postgres

  def count(queryable), do: aggregate(queryable, :count, :id)
end

Mox.defmock(ExZample.MockRepo, for: Ecto.Repo)
