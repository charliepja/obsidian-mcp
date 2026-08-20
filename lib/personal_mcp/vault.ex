defmodule McpServer.Vault do
  alias PersonalMcp.Github.Client

  @tasks_folder "01. Current Work"

  def note_path(task_name), do: "#{@tasks_folder}/#{task_name}/#{task_name}.md"
  def log_path(task_name), do: "#{@tasks_folder}/#{task_name}/log.md"

  def task_exists?(task_name), do: Client.file_exists?(note_path(task_name))

  def get_task(task_name) do
    with {:ok, %{content: note}} <- Client.get_file(note_path(task_name)) do
      log =
        case Client.get_file(log_path(task_name)) do
          {:ok, %{content: content}} -> content
          _ -> nil
        end

      {:ok, %{note: note, log: log}}
    end
  end

  def get_task_overview(task_name) do
    with {:ok, %{content: note}} <- Client.get_file(note_path(task_name)) do
      {:ok, extract_section(note, "Overview")}
    end
  end

  def create_task(task_name, fields) do
    with {:ok, _} <-
           Client.put_file(
             note_path(task_name),
             build_note(task_name, fields),
             "task: create #{task_name}"
           ),
         {:ok, _} <-
           Client.put_file(
             log_path(task_name),
             "# Log\n",
             "task: initialise log for #{task_name}"
           ) do
      :ok
    end
  end

  def update_task_note(task_name, fields) do
    with {:ok, %{content: current, sha: sha}} <- Client.get_file(note_path(task_name)) do
      updated = apply_field_updates(current, fields)
      Client.put_file(note_path(task_name), updated, "task: update #{task_name}", sha)
    end
  end

  def update_subtasks(task_name, complete: complete, add: add) do
    with {:ok, %{content: current, sha: sha}} <- Client.get_file(note_path(task_name)) do
      updated =
        current
        |> mark_complete(complete)
        |> append_subtasks(add)

      Client.put_file(note_path(task_name), updated, "task: update subtasks for #{task_name}", sha)
    end
  end

  # Private

  defp build_note(task_name, fields) do
    today = Date.utc_today() |> Date.to_iso8601()
    tags = Jason.encode!(fields[:tags] || [])
    subtasks = Enum.map_join(fields[:subtasks] || [], "\n", &"- [ ] #{&1}")

    """
    ---
    title: #{fields[:title] || task_name}
    type: task
    status: active
    priority: #{fields[:priority] || "medium"}
    due: #{fields[:due] || ""}
    tags: #{tags}
    created: #{today}
    completed:
    demo: false
    summary: #{fields[:summary] || ""}
    ---

    ## Overview

    #{fields[:overview] || ""}

    ## Sub-tasks

    #{subtasks}

    ## Notes

    #{fields[:notes] || ""}

    ## Resources

    #{fields[:resources] || ""}
    """
  end

  defp apply_field_updates(content, fields) do
    Enum.reduce(fields, content, fn
      {_key, nil}, acc ->
        acc

      {:overview, value}, acc ->
        replace_section(acc, "Overview", "Sub-tasks", value)

      {:subtasks, subtasks}, acc ->
        list = Enum.map_join(subtasks, "\n", &"- [ ] #{&1}")
        replace_section(acc, "Sub-tasks", "Notes", list)

      {:notes, value}, acc ->
        replace_section(acc, "Notes", "Resources", value)

      {:resources, value}, acc ->
        Regex.replace(~r/## Resources\n\n.*/s, acc, "## Resources\n\n#{value}")

      {key, value}, acc when key in [:priority, :due, :summary] ->
        Regex.replace(~r/^#{key}: .*$/m, acc, "#{key}: #{value}")

      _, acc ->
        acc
    end)
  end

  defp replace_section(content, from, to, replacement) do
    Regex.replace(
      ~r/(## #{from}\n\n).*?(\n## #{to})/s,
      content,
      "\\1#{replacement}\\2"
    )
  end

  defp mark_complete(content, []), do: content

  defp mark_complete(content, items) do
    Enum.reduce(items, content, fn item, acc ->
      String.replace(acc, "- [ ] #{item}", "- [x] #{item}")
    end)
  end

  defp append_subtasks(content, []), do: content

  defp append_subtasks(content, items) do
    new_items = Enum.map_join(items, "\n", &"- [ ] #{&1}")
    String.replace(content, "\n## Notes", "\n#{new_items}\n\n## Notes")
  end

  defp extract_section(content, name) do
    case Regex.run(~r/## #{name}\n\n(.*?)(?=\n## |\z)/s, content, capture: :all_but_first) do
      [section] -> String.trim(section)
      nil -> ""
    end
  end
end
