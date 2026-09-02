# Synapse MCP — Quick Install

## 1. Install the binary

**Linux / macOS:**
```sh
curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh
```

**Windows PowerShell:**
```powershell
powershell -c "irm https://downloads.synapse-mcp.dev/install.ps1 | iex"
```

The installer auto-detects your MCP client (Cursor, Claude Code, Windsurf, VS Code, etc.) and writes the correct config.

If auto-detection fails, you can configure manually:

## 2. Manual MCP config

Add to your MCP client's configuration (e.g. `claude_desktop_config.json`, `.cursor/mcp.json`, or `windsurf.json`):

```json
{
  "mcpServers": {
    "synapse": {
      "command": "synapse-mcp",
      "args": []
    }
  }
}
```

## 3. Verify

```sh
synapse-mcp --version
```

## Notes

- Synapse MCP is a **compiled binary** (not an npx package or Docker container)
- Runs 100% locally — no cloud dependency
- 50+ languages indexed out of the box
- After install, run `synapse-mcp register` to index a repository
- See the full README at https://github.com/myelixlabs/synapse-mcp
