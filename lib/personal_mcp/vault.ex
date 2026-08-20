defmodule PersonalMcp.Vault do
  alias PersonalMcp.Github.Client

  @tasks_folder "01. Current Work"
  @completed_folder "06 Completed Work"

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

  def archive_task(task_name) do
    with {:ok, %{content: note, sha: note_sha}} <- Client.get_file(note_path(task_name)),
         {:ok, %{content: log_content, sha: log_sha}} <- Client.get_file(log_path(task_name)),
         {:ok, _} <- Client.put_file("#{@completed_folder}/#{task_name}/#{task_name}.md", note, "task: archive #{task_name}"),
         {:ok, _} <- Client.put_file("#{@completed_folder}/#{task_name}/log.md", log_content, "task: archive log for #{task_name}"),
         :ok <- Client.delete_file(note_path(task_name), note_sha, "task: remove #{task_name} from active"),
         :ok <- Client.delete_file(log_path(task_name), log_sha, "task: remove log for #{task_name} from active") do
      :ok
    end
  end

  def append_log(task_name, entry) do
    with {:ok, %{content: current, sha: sha}} <- Client.get_file(log_path(task_name)) do
      timestamp = DateTime.utc_now() |> DateTime.to_string()
      updated = current <> "\n---\n\n**#{timestamp}**\n\n#{entry}\n"
      Client.put_file(log_path(task_name), updated, "log: update #{task_name}", sha)
    end
  end

  def update_notes(task_name, content) do
    with {:ok, %{content: current, sha: sha}} <- Client.get_file(note_path(task_name)) do
      updated = current
      |> String.replace("\r\n", "\n")
      |> update_section("Notes", "Resources", content)
      Client.put_file(note_path(task_name), updated, "task: update notes for #{task_name}", sha)
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
    content = String.replace(content, "\r\n", "\n")

    content
    |> update_frontmatter_field("priority", fields[:priority])
    |> update_frontmatter_field("due", fields[:due])
    |> update_frontmatter_field("summary", fields[:summary])
    |> update_frontmatter_field("tags", format_tags(fields[:tags]))
    |> update_section("Overview", "Sub-tasks", fields[:overview])
    |> update_section("Sub-tasks", "Notes", format_subtask_list(fields[:subtasks]))
    |> update_section("Notes", "Resources", fields[:notes])
    |> update_last_section("Resources", fields[:resources])
  end

  defp update_frontmatter_field(content, _key, nil), do: content
  defp update_frontmatter_field(content, key, value) do
    String.replace(content, ~r/^#{key}: .*$/m, "#{key}: #{value}")
  end

  defp update_section(content, _from, _to, nil), do: content
  defp update_section(content, from, to, value) do
    Regex.replace(
      ~r/## #{from}\n+.*?\n+## #{to}/s,
      content,
      escape_replacement("## #{from}\n\n#{value}\n\n## #{to}")
    )
  end

  defp update_last_section(content, _name, nil), do: content
  defp update_last_section(content, name, value) do
    Regex.replace(
      ~r/## #{name}\n+.*/s,
      content,
      escape_replacement("## #{name}\n\n#{value}")
    )
  end

  defp update_last_section(content, _name, nil), do: content
  defp update_last_section(content, name, value) do
    Regex.replace(
      ~r/## #{name}\n\n.*/s,
      content,
      escape_replacement("## #{name}\n\n#{value}")
    )
  end

  defp escape_replacement(str), do: String.replace(str, "\\", "\\\\")

  defp format_subtask_list(nil), do: nil
  defp format_subtask_list(subtasks) do
    Enum.map_join(subtasks, "\n", &"- [ ] #{&1}")
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

  defp format_tags(nil), do: nil
  defp format_tags(tags), do: Jason.encode!(tags)
end
