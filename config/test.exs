use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :upsilon_garden, UpsilonGardenWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :upsilon_garden, UpsilonGarden.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "gardener",
  password: "iamaloftygardenerfromearth",
  database: "garden_test",
  hostname: "46.101.225.43",
  pool: Ecto.Adapters.SQL.Sandbox
