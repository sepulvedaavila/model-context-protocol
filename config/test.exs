import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mcps_web, McpsWeb.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mcps_web_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

config :mcps_management, MCPS.Management.Repo,
  database: "mcps_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mcps_web, McpsWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ncJb6BGEk11oZuv60pyOE9OAtReuotI/6/NqlAXFX9d7V9xv23ftPV8+GNKn2UMy",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mcps_web, McpsWeb.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mcps_web_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mcps_web, McpsWebWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "JTy029BuJO10N0klZSbSFyfU8qw6I5r1Gso5MTfduWs7le60GNWNkxn4iILsgUcG",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
