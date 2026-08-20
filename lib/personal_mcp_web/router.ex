defmodule PersonalMcpWeb.Router do
  use PersonalMcpWeb, :router

  pipeline :mcp do
    plug :accepts, ["json"]
    plug PersonalMcpWeb.Plugs.Auth
  end

  scope "/", PersonalMcpWeb do
    pipe_through :mcp
    post "/mcp", McpController, :handle
  end
end
