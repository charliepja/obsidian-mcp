defmodule PersonalMcpWeb.McpController do
  use PersonalMcpWeb, :controller
  alias PersonalMcp.MCP.Protocol

  def handle(conn, params) do
    case Protocol.handle(params) do
      {:ok, response} -> json(conn, response)
      :noreply -> send_resp(conn, 202, "")
    end
  end

  def stream(conn, _params) do
    conn
    |> put_resp_content_type("text/event-stream")
    |> send_resp(200, "")
  end
end
