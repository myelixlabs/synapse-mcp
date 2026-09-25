---
description: Check that the local Synapse MCP server is installed, running, and connected to Claude Code
---

# Synapse Setup

1. Check whether the `synapse` MCP server is connected in this session (its tools are named `ask_synapse`, `synapse_manage_repos`, and so on). If it is, call `ask_synapse` with "health check" and report the result.
2. If it is not connected, ask the user to run `synapse-mcp status` in a terminal.
   - If the command is not found, Synapse is not installed. Tell the user they can install it from https://synapse-mcp.dev/download, or with the installer script (it downloads the Synapse binary from downloads.synapse-mcp.dev and asks them to sign in):
     ```
     curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh
     ```
     Do not run the installer yourself; let the user run it.
   - If Synapse is installed but stopped, ask the user to run `synapse-mcp start`.
   - If Synapse is running but Claude Code is not connected, ask the user to run `synapse-mcp setup ides configure claude-code`, then restart Claude Code.
3. Once connected, ask the user which repository to index and call `ask_synapse` to register it. Then explain that Claude can now query code structure, trace callers, make lint-validated edits with automatic rollback, and review the blast radius of a diff before it is pushed.
