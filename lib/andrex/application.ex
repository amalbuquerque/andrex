defmodule Andrex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AndrexWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Andrex.PubSub},
      # Start the Endpoint (http/https)
      AndrexWeb.Endpoint,

      Andrex.Blog.Cache,
      {
        Andrex.Blog.Refresher,
        [
          {Andrex.Blog, :refresh_cache, []},
          {Andrex.Main, :refresh_cache, []}
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Andrex.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AndrexWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
