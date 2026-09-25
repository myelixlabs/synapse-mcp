---
description: Install and verify the Synapse MCP background server
---

# Synapse Setup

1. Check if Synapse MCP is running on `http://127.0.0.1:8585/mcp`.
2. If it is not responding, instruct the user to install the background service by running:
   ```
   curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh
   ```
3. Wait for the user to confirm installation is complete.
4. Once running, explain that the agent now has a persistent AST map of the entire codebase and can:
   - Query code structure in microseconds instead of grepping files
   - Perform safe writes with in-memory simulation and auto-rollback
   - Resolve stack traces against the AST graph
   - Review changes for blast radius before pushing
