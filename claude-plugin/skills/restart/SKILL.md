---
name: restart
description: Restart the Synapse MCP server on this machine, for example after an update or when it stops responding.
disable-model-invocation: true
---

# Restart Synapse

Tell the user first that Synapse tools will be unavailable for a few seconds.

1. Run `synapse-mcp restart` in the shell.
2. If the command is not found, Synapse is not installed: suggest `/synapse-mcp:setup` and stop.
3. Run `synapse-mcp status` and report whether the server is running again.
4. If the Synapse tools do not come back in this session, ask the user to reconnect the server from `/mcp`.
