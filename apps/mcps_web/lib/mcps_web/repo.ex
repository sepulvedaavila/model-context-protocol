defmodule McpsWeb.Repo do
  use Ecto.Repo,
    otp_app: :mcps_web,
    adapter: Ecto.Adapters.Postgres
end
