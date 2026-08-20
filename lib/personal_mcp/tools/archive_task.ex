defmodule PersonalMcp.Tools.ArchiveTask do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name}) do
    case Vault.archive_task(task_name) do
      :ok -> {:ok, "Task '#{task_name}' archived to 06 Completed/."}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_), do: {:error, "task_name is required"}
end
