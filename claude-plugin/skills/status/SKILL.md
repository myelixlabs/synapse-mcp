---
name: status
description: Report whether Synapse MCP is installed, running, signed in and connected, and whether the current project is indexed, with the fix for anything missing. Use when the user asks about Synapse's status or to set it up, or when Synapse tools are missing or failing.
---

# Synapse status

Work through these in order and stop at the first thing that needs the user.

1. If the Synapse tools are available, call `synapse_indexer_control` with action `health`. Report in one or two lines: whether the server is healthy, whether the user is signed in, and how many repositories are registered.
2. Call `synapse_manage_repos` with action `list`. Say whether the current project is registered and how far its indexing has got. If it is not registered, suggest `/synapse-mcp:index`.
3. If the health result shows the user is not signed in, ask them to run `synapse-mcp auth` in a terminal.
4. If the Synapse tools are not available, ask the user to run `synapse-mcp status` in a terminal and tell you what it prints.
   - Command not found: Synapse is not installed. Point the user to https://synapse-mcp.dev/download. Do not download or run an installer yourself.
   - Installed but stopped: suggest `/synapse-mcp:start`.
   - Running, but the tools are still missing: the plugin's Synapse URL may not match. The default is `http://127.0.0.1:8585/mcp`. Ask the user to check it under `/plugin`, then reconnect the server from `/mcp`.

Keep the report short. Do not list every tool or repository unless the user asks.
