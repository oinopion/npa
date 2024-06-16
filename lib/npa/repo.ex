defmodule NPA.Repo do
  use Ecto.Repo,
    otp_app: :npa,
    adapter: Ecto.Adapters.Postgres
end
