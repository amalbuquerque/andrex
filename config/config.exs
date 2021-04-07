# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :andrex, AndrexWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "434VF2FLtHfVGM//TyhS2NFW9l/k7V8ZAgCRXN7lZQKA9ld7fvsKgNe1yFetrbFX",
  render_errors: [view: AndrexWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Andrex.PubSub,
  live_view: [signing_salt: "A2x3y9cl"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"