defmodule PersonalMcp.Tools.DefineTask do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name} = args) do
    fields = %{
      title: args["title"],
      priority: args["priority"],
      due: args["due"],
      tags: args["tags"],
      summary: args["summary"],
      overview: args["overview"],
      subtasks: args["subtasks"],
      notes: args["notes"],
      resources: args["resources"]
    }

    if Vault.task_exists?(task_name) do
      case Vault.update_task_note(task_name, fields) do
        {:ok, _} -> {:ok, "Task '#{task_name}' updated."}
        {:error, reason} -> {:error, reason}
      end
    else
      case Vault.create_task(task_name, fields) do
        :ok -> {:ok, "Task '#{task_name}' created."}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  def call(_), do: {:error, "task_name is required"}
end
