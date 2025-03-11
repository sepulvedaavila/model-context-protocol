import Config

if config_env() == :prod do
  # Database configuration
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

    config :mcps_management, MCPS.Management.Repo,
      url: database_url,
      pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
      ssl: true,  # Enable SSL for production
      ssl_opts: [
        verify: :verify_peer,
        cacertfile: System.get_env("SSL_CACERT_FILE"),
        server_name_indication: System.get_env("DB_HOSTNAME")
      ]

  # Web configuration
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :mcps_web, MCPS.Web.Endpoint,
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base,
    server: true

  # Redis configuration (if using)
  redis_url = System.get_env("REDIS_URL")
  if redis_url do
    config :mcps_management,
      redis_url: redis_url
  end

  # Logging
  config :logger, level: String.to_atom(System.get_env("LOG_LEVEL") || "info")
end
