defmodule PersonalMcpWeb.Plugs.Auth do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    expected = Application.get_env(:mcp_server, :auth)[:api_key]

    case get_req_header(conn, "authorization") do
      ["Bearer " <> key] when key == expected ->
        conn

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Unauthorized"}))
        |> halt()
    end
  end
end
