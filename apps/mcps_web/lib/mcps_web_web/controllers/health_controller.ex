defmodule McpsWebWeb.HealthController do
  use McpsWebWeb, :controller
  use PhoenixSwagger

  alias MCPS.Management.Repo

  # Swagger documentation
  swagger_path :check do
    get "/api/health"
    summary "Health check"
    description "Check the health of the system"
    response 200, "Success", Schema.object(%{
      status: %Schema{type: :string, description: "System status"},
      version: %Schema{type: :string, description: "System version"},
      components: %Schema{
        type: :object,
        description: "Component statuses",
        properties: %{
          database: %Schema{type: :string, description: "Database status"},
          api: %Schema{type: :string, description: "API status"}
        }
      },
      timestamp: %Schema{type: :string, description: "Current timestamp"}
    })
  end

  def check(conn, _params) do
    # Check database connection
    db_status = case check_database() do
      :ok -> "healthy"
      {:error, _} -> "unhealthy"
    end

    # Get system version
    version = Application.spec(:mcps_web, :vsn) || "unknown"

    # Build response
    response = %{
      status: if(db_status == "healthy", do: "healthy", else: "degraded"),
      version: to_string(version),
      components: %{
        database: db_status,
        api: "healthy"
      },
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    conn
    |> json(response)
  end

  # Check database connection
  defp check_database do
    try do
      # Simple query to check if database is responsive
      Repo.__adapter__().query(Repo, "SELECT 1", [])
      :ok
    rescue
      e -> {:error, e}
    end
  end
end
