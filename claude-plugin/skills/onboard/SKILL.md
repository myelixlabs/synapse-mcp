---
name: onboard
description: Give a guided reading order for this codebase using Synapse's code graph. Use when the user is new to a repository, or asks where to start or how the code is organised.
argument-hint: "[area or path]"
---

# Onboard to a codebase

1. Find the `repo_id` for the current project with `synapse_manage_repos` (action `list`), matching on the project directory. If the project is not registered, stop and suggest `/synapse-mcp:index`.
2. Call `synapse_get_context` with action `onboard` and that `repo_id`. If the user named an area or path (`$ARGUMENTS`), pass it as the focus.
3. Present the result as a short reading order: where to start, the main entry points, the modules that matter most and how they connect. Link each item to its file.

Keep it to what someone needs on their first day. Offer to go deeper on any item.
