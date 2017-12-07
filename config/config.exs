# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :upsilon_garden,
  ecto_repos: [UpsilonGarden.Repo]

# Configures the endpoint
config :upsilon_garden, UpsilonGardenWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "fgX0++g+1IqX5HmkVdQiAuWHuDbTOckkYAr0ZtO0+jIdZ3FnwK+452aXlq2+0264",
  render_errors: [view: UpsilonGardenWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: UpsilonGarden.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
