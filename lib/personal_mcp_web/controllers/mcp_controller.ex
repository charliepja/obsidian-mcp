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
    conn =
      conn
      |> put_resp_header("content-type", "text/event-stream")
      |> put_resp_header("cache-control", "no-cache")
      |> put_resp_header("connection", "keep-alive")
      |> send_chunked(200)

    Stream.repeatedly(fn -> :heartbeat end)
    |> Stream.each(fn _ ->
      chunk(conn, ": heartbeat\n\n")
      Process.sleep(15_000)
    end)
    |> Stream.run()

    conn
  end
end
