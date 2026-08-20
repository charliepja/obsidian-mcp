import Config

config :mcp_server, :github,
  token: System.fetch_env!("GITHUB_TOKEN"),
  owner: System.fetch_env!("GITHUB_OWNER"),
  repo: System.fetch_env!("GITHUB_REPO")

config :mcp_server, :auth,
  api_key: System.fetch_env!("MCP_API_KEY")

config :mcp_server, McpServerWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4000"))],
  url: [host: System.fetch_env!("HOST"), scheme: "https"],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE")
