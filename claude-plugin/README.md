# Synapse MCP for Claude

Connects Claude to [Synapse MCP](https://synapse-mcp.dev), a code-knowledge graph that runs on your own machine, and teaches Claude to use it before grep and raw file reads. Works in Claude Code and in Cowork sessions on your computer.

## Before you start

Install Synapse and sign in. The plugin does not install or start it for you. Get it from [synapse-mcp.dev/download](https://synapse-mcp.dev/download), then run `/synapse-mcp:status` to check everything is connected.

## Skills

| Skill | What it does | Plan |
| --- | --- | --- |
| `synapse-mcp` | Steers Claude to the Synapse tools for navigating, editing and reviewing code. Claude applies it on its own. | Free |
| `/synapse-mcp:status` | Whether Synapse is installed, running, signed in and connected, whether this project is indexed, and the tokens saved. | Free |
| `/synapse-mcp:index` | Registers the current project and reports indexing progress. | Free |
| `/synapse-mcp:onboard` | A reading order for a codebase you are new to. | Free |
| `/synapse-mcp:start`, `/synapse-mcp:restart` | Start or restart the Synapse server. Only run when you type them. | Free |
| `/synapse-mcp:review` | Blast radius, broken contracts and tests to run for your current changes. | Pro |
| `/synapse-mcp:impact <symbol>` | What depends on a function or module, and what could break. | Pro |
| `/synapse-mcp:trace` | Maps a stack trace to the code responsible. | Pro |

Your plan is checked by the Synapse server you signed in to, not by this plugin. On the free plan, a Pro skill tells you it needs Pro.

## Settings

**Synapse MCP URL**: where your Synapse server listens. The default, `http://127.0.0.1:8585/mcp`, is right unless you started Synapse on another port.

If you connected Synapse to Claude Code earlier with `synapse-mcp setup ides configure claude-code`, remove that entry with `claude mcp remove synapse -s user`, otherwise the Synapse tools are listed twice.

## What the plugin does and what data it touches

- The plugin contains only Markdown and JSON. It has no hooks and no bundled programs.
- It connects Claude to the Synapse server at the URL above, on your machine. Your source code is indexed and searched there and is never uploaded.
- `/synapse-mcp:start` and `/synapse-mcp:restart` run the `synapse-mcp` command you installed. `/synapse-mcp:review` runs `git diff`. Claude asks before running either.
- The Synapse server itself contacts `api.synapse-mcp.dev` to sign you in and check your plan, and `downloads.synapse-mcp.dev` to install and update. The plugin sends nothing anywhere.

claude.ai chat loads the skills but cannot reach a server on your machine, so the plugin is useful there only as guidance.
