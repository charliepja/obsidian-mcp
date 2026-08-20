defmodule PersonalMcp.Tools.ReviewTask do
  alias McpServer.Vault

  def call(%{"task_name" => task_name}) do
    case Vault.get_task(task_name) do
      {:ok, %{note: note, log: log}} ->
        log_section = if log, do: "\n\n---\n\n## Log\n\n#{log}", else: "\n\n---\n\n## Log\n\n(empty)"
        {:ok, "#{note}#{log_section}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def call(_), do: {:error, "task_name is required"}
end
