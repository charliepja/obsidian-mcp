defmodule PersonalMcp.Tools.UpdateTask do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name} = args) do
    complete = args["complete_subtasks"] || []
    add = args["new_subtasks"] || []

    case Vault.update_subtasks(task_name, complete: complete, add: add) do
      {:ok, _} -> {:ok, "Subtasks updated for '#{task_name}'."}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_), do: {:error, "task_name is required"}
end
