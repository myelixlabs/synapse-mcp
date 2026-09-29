---
name: impact
description: Show what depends on a function, class or module and what could break if it changes, using Synapse's code graph. Use when the user asks what calls something, what depends on it, or whether it is safe to change. Needs Synapse Pro.
argument-hint: "<symbol>"
---

# Impact of changing a symbol

The symbol is `$ARGUMENTS`. If it is empty, ask the user which function, class or module they mean.

1. Find the `repo_id` for the current project with `synapse_manage_repos` (action `list`), matching on the project directory. If the project is not registered, stop and suggest `/synapse-mcp:index`.
2. If the name could match more than one definition, call `synapse_search_codebase` with action `symbol` and ask the user to pick. For Elixir, include the arity, for example `Parser.parse/2`.
3. Call `synapse_change_review` with action `impact`, the symbol and the `repo_id`.
4. Report: direct callers, callers further out, the files involved and the tests that cover them. Finish with a one-line judgement of how risky a change is.

If Synapse answers that this needs a Pro licence, say so plainly and point the user to https://synapse-mcp.dev/download. Do not retry or work around it.
