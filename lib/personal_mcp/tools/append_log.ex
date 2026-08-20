defmodule PersonalMcp.Tools.AppendLog do
  alias PersonalMcp.Vault

  def call(%{"task_name" => task_name, "entry" => entry}) do
    case Vault.append_log(task_name, entry) do
      {:ok, _} -> {:ok, "Log updated for '#{task_name}'."}
      {:error, reason} -> {:error, reason}
    end
  end

  def call(_), do: {:error, "task_name and entry are required"}
end
