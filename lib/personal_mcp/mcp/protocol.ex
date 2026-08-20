defmodule PersonalMcp.MCP.Protocol do
  alias PersonalMcp.Tools.{DefineTask, UpdateTask, CompleteTask, ReviewTask}

  @protocol_version "2024-11-05"

  def handle(%{"method" => "initialize", "id" => id}) do
    reply(id, %{
      protocolVersion: @protocol_version,
      capabilities: %{tools: %{}},
      serverInfo: %{name: "obsidian-mcp", version: "1.0.0"}
    })
  end

  def handle(%{"method" => "notifications/initialized"}), do: :noreply

  def handle(%{"method" => "tools/list", "id" => id}) do
    reply(id, %{tools: tool_definitions()})
  end

  def handle(%{"method" => "tools/call", "id" => id, "params" => %{"name" => name, "arguments" => args}}) do
    result =
      case name do
        "define_task" -> DefineTask.call(args)
        "update_task" -> UpdateTask.call(args)
        "complete_task" -> CompleteTask.call(args)
        "review_task" -> ReviewTask.call(args)
        _ -> {:error, "Unknown tool: #{name}"}
      end

    case result do
      {:ok, text} -> reply(id, %{content: [%{type: "text", text: text}]})
      {:error, reason} -> error(id, -32_000, reason)
    end
  end

  def handle(%{"id" => id}), do: error(id, -32_601, "Method not found")
  def handle(_), do: :noreply

  # Private

  defp reply(id, result), do: {:ok, %{jsonrpc: "2.0", id: id, result: result}}
  defp error(id, code, message), do: {:ok, %{jsonrpc: "2.0", id: id, error: %{code: code, message: message}}}

  defp tool_definitions do
    [
      %{
        name: "define_task",
        description: """
        Create or update a task in the Obsidian vault. Auto-detects whether the task \
        already exists — if it does, updates the existing note; if not, creates the folder, \
        note, and log from scratch.
        """,
        inputSchema: %{
          type: "object",
          properties: %{
            task_name: %{type: "string", description: "Used as the folder and file name"},
            title: %{type: "string"},
            priority: %{type: "string", enum: ["low", "medium", "high"]},
            due: %{type: "string", description: "ISO date YYYY-MM-DD"},
            tags: %{type: "array", items: %{type: "string"}},
            summary: %{type: "string", description: "One-line summary for standup reports"},
            overview: %{type: "string"},
            subtasks: %{type: "array", items: %{type: "string"}},
            notes: %{type: "string"},
            resources: %{type: "string"}
          },
          required: ["task_name"]
        }
      },
      %{
        name: "update_task",
        description: "Mark subtasks as complete and/or add new subtasks to an existing task.",
        inputSchema: %{
          type: "object",
          properties: %{
            task_name: %{type: "string"},
            complete_subtasks: %{
              type: "array",
              items: %{type: "string"},
              description: "Exact subtask text to mark as complete"
            },
            new_subtasks: %{
              type: "array",
              items: %{type: "string"},
              description: "New subtasks to append"
            }
          },
          required: ["task_name"]
        }
      },
      %{
        name: "complete_task",
        description: """
        Returns the task overview and log.md for a PR-style review. Only the overview \
        is returned (not the full note) to avoid biasing the review with sub-task state.
        """,
        inputSchema: %{
          type: "object",
          properties: %{
            task_name: %{type: "string"}
          },
          required: ["task_name"]
        }
      },
      %{
        name: "review_task",
        description: "Returns the full task note and log. Use when re-orientating on what is being worked on.",
        inputSchema: %{
          type: "object",
          properties: %{
            task_name: %{type: "string"}
          },
          required: ["task_name"]
        }
      }
    ]
  end
end
