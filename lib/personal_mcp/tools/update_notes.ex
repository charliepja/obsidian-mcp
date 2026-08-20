defmodule PersonalMcp.Tools.UpdateNotes do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name, "content" => content}) do
    case Vault.update_notes(task_name, content) do
      {:ok, _} -> {:ok, "Notes updated for '#{task_name}'."}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_), do: {:error, "task_name and content are required"}
end
