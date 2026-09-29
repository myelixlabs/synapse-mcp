---
name: trace
description: Resolve a stack trace or error message to the code responsible, using Synapse's code graph. Use when the user pastes a stack trace or asks where an error comes from. Needs Synapse Pro.
argument-hint: "<stack trace>"
---

# Resolve a stack trace

The trace is `$ARGUMENTS`. If it is empty, use the stack trace the user pasted most recently in this conversation, or ask for one.

1. Find the `repo_id` for the current project with `synapse_manage_repos` (action `list`), matching on the project directory. If the project is not registered, stop and suggest `/synapse-mcp:index`.
2. Call `synapse_debug_trace` with action `resolve_stack`, the trace and the `repo_id`.
3. Report which frames map to which code, linking each to its file and line, and the most likely cause.

Synapse maps the trace to candidates without running the code, so present the cause as likely, not proven, and say what would confirm it.

If Synapse answers that this needs a Pro licence, say so plainly and point the user to https://synapse-mcp.dev/download. Do not retry or work around it.
