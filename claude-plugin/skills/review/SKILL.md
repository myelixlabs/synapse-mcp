---
name: review
description: Review the current code changes for blast radius, broken contracts and the tests to run, using Synapse's code graph. Use before committing or opening a pull request. Needs Synapse Pro.
argument-hint: "[base branch or commit]"
---

# Review changes

1. Find the `repo_id` for the current project with `synapse_manage_repos` (action `list`), matching on the project directory. If the project is not registered, stop and suggest `/synapse-mcp:index`.
2. Get the diff. Use the working tree changes (`git diff HEAD`). If there are none, diff against `$ARGUMENTS` if the user gave a base, otherwise against the repository's main branch.
3. Call `synapse_change_review` with action `review_diff`, the diff and the `repo_id`.
4. Report the findings most serious first: what could break and why, which callers are affected, which contracts changed, and which tests to run.

Report only. Do not change any code unless the user asks.

If Synapse answers that this needs a Pro licence, say so plainly and point the user to https://synapse-mcp.dev/download. Do not retry or work around it.
