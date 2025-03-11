# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mcps_web,
  ecto_repos: [McpsWeb.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :mcps_web, McpsWebWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: McpsWebWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: McpsWeb.PubSub,
  live_view: [signing_salt: "cebkxFTN"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure phoenix_swagger
config :phoenix_swagger, json_library: Jason

# Configure Swagger
config :mcps_web, :phoenix_swagger,
  swagger_files: %{
    "priv/static/swagger.json" => [
      router: McpsWebWeb.Router,
      endpoint: McpsWebWeb.Endpoint
    ]
  }

# Configure rate limiting
config :mcps_web, :rate_limit,
  max_requests: 100,
  interval_seconds: 60

# Configure context size limits
config :mcps_management,
  max_context_size_bytes: 10_485_760,  # 10 MB
  max_contexts_per_user: 1000

# Configure transformation pipeline
config :mcps_transform,
  max_pipeline_steps: 20,
  max_concurrent_transformations: 10

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#
