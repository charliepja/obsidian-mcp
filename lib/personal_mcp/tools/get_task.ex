defmodule PersonalMcp.Tools.GetTask do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name}) do
    case Vault.get_task(task_name) do
      {:ok, %{note: note}} -> {:ok, note}
      {:error, :not_found} -> {:ok, "Task '#{task_name}' does not exist yet."}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_), do: {:error, "task_name is required"}
end
