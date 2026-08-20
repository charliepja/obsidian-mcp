defmodule PersonalMcp.Github.Client do
  @base_url "https://api.github.com"

  defp config, do: Application.get_env(:personal_mcp, :github)

  defp headers do
    [
      {"Authorization", "token #{config()[:token]}"},
      {"Accept", "application/vnd.github.v3+json"},
      {"User-Agent", "obsidian-mcp/1.0"}
    ]
  end

  defp repo_url(path) do
    encoded =
      path
      |> String.split("/")
      |> Enum.map_join("/", &URI.encode/1)

    "#{@base_url}/repos/#{config()[:owner]}/#{config()[:repo]}/contents/#{encoded}"
  end

  def get_file(path) do
    case Req.get(repo_url(path), headers: headers()) do
      {:ok, %{status: 200, body: body}} ->
        content =
          body["content"]
          |> String.replace("\n", "")
          |> Base.decode64!()

        {:ok, %{content: content, sha: body["sha"]}}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status, body: body}} ->
        {:error, "GitHub API error #{status}: #{inspect(body["message"])}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  def put_file(path, content, message, sha \\ nil) do
    body = %{"message" => message, "content" => Base.encode64(content)}
    body = if sha, do: Map.put(body, "sha", sha), else: body

    case Req.put(repo_url(path), json: body, headers: headers()) do
      {:ok, %{status: status, body: resp_body}} when status in [200, 201] ->
        {:ok, get_in(resp_body, ["content", "sha"])}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, "GitHub API error #{status}: #{inspect(resp_body["message"])}"}

      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  def delete_file(path, sha, message) do
    body = %{"message" => message, "sha" => sha}

    case Req.delete(repo_url(path), json: body, headers: headers()) do
      {:ok, %{status: 200}} -> :ok
      {:ok, %{status: status, body: resp_body}} ->
        {:error, "GitHub API error #{status}: #{inspect(resp_body["message"])}"}
      {:error, reason} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end

  def file_exists?(path) do
    match?({:ok, _}, get_file(path))
  end
end
