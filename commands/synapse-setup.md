---
name: synapse-setup
description: Install, start, and verify the local Synapse MCP server on macOS, Linux, or Windows.
---

# Synapse Setup

1. Check if Synapse MCP is running on `http://127.0.0.1:8585/mcp`.
   `synapse-mcp status` reports the same thing from the CLI. If it prints a stopped
   status, the service is installed — skip to step 4.
2. If `synapse-mcp` is not found, install it. Pick the branch matching the user's
   operating system, show the command, explain that it downloads and runs an install
   script, and let the user confirm before running it.

   **macOS and Linux**
   ```sh
   curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh
   ```

   **Windows**
   ```powershell
   powershell -c "irm https://downloads.synapse-mcp.dev/install.ps1 | iex"
   ```

   Then run `synapse-mcp install`, the first-run wizard. It is interactive and opens a
   browser for device-code sign-in, so hand control back to the user for that part
   rather than trying to drive it. On Windows the installer appends its directory to
   the user PATH; if `synapse-mcp` is still not found afterwards, Cursor needs
   restarting to inherit the updated environment.
3. Start the service with `synapse-mcp start`, and recommend `synapse-mcp enable` so
   it starts at login. Autostart is user-level on all three platforms — launchd,
   a systemd user unit, or Task Scheduler — and needs no root or admin rights.
4. Verify Cursor can reach it. The plugin points at `http://127.0.0.1:8585/mcp`;
   confirm the `synapse` MCP server shows as connected, then call
   `synapse_manage_repos` with the `list` action. If the tools are still unavailable
   after the server reports running, ask the user to reload the Cursor window.
5. Register the repository if it is not already in that list, and let the initial
   index finish before relying on search results.
6. Once running, explain that the agent now has a persistent AST map of the entire codebase and can:
   - Query code structure in microseconds instead of grepping files
   - Perform safe writes with in-memory simulation and auto-rollback
   - Resolve stack traces against the AST graph
   - Review changes for blast radius before pushing

## When 127.0.0.1 is the wrong machine

If Cursor runs somewhere other than where the code lives — WSL, a remote SSH host, a
devcontainer — then Cursor's loopback and the repository's loopback are two different
machines. Synapse must run on whichever side the repository is on, and that side's
port 8585 must be reachable from the side running Cursor. Explain this rather than
reinstalling in a loop.
