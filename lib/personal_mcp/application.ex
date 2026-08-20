defmodule PersonalMcp.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PersonalMcpWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:personal_mcp, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PersonalMcp.PubSub},
      # Start a worker by calling: PersonalMcp.Worker.start_link(arg)
      # {PersonalMcp.Worker, arg},
      # Start to serve requests, typically the last entry
      PersonalMcpWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PersonalMcp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PersonalMcpWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
