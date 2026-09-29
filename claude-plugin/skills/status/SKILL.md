---
name: status
description: Report whether Synapse MCP is running and signed in, how far the current project's indexing has got, and how many tokens Synapse has saved. Use when the user asks how Synapse is doing, whether it is running, or whether a project is indexed yet.
---

# Synapse status

Give a short report, five lines at most. This is a quick check, not a troubleshooting session.

1. Call `synapse_indexer_control` with action `health`. If the Synapse tools are not available or the call fails, say that Synapse is not answering, suggest `/synapse-mcp:setup`, and stop.
2. Call `synapse_manage_repos` with action `list` and find the current project by its directory.
3. If the project is registered and still indexing, call `synapse_indexer_control` with action `status` and its `repo_id` for the detail. Always pass the `repo_id`: the call is slow without one.
4. Report:
   - Server: healthy or not, signed in or not, and the plan if the health result gives one.
   - This project: registered or not, indexing phase and percentage, and whether embeddings are still being built. If it is not registered, suggest `/synapse-mcp:index`.
   - Savings: tokens saved this session and all time, from the health result.

Mention other repositories only if one needs attention, and then in one line.
