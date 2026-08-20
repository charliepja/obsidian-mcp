defmodule PersonalMcp.Tools.CompleteTask do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name}) do
    with {:ok, overview} <- Vault.get_task_overview(task_name),
         {:ok, %{log: log}} <- Vault.get_task(task_name) do
      log_section = if log, do: "\n\n---\n\n## Log\n\n#{log}", else: "\n\n---\n\n## Log\n\n(empty)"
      {:ok, "## Overview\n\n#{overview}#{log_section}"}
    end
  end

  def call(_), do: {:error, "task_name is required"}
end
