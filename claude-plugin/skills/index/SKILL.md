---
name: index
description: Register the current project with Synapse so it is indexed into the code graph, or report progress if it already is. Use when the user asks to index, register or add a project to Synapse.
argument-hint: "[path]"
---

# Index a project

The project to index is `$ARGUMENTS` if the user gave a path, otherwise the current project directory.

1. Call `synapse_manage_repos` with action `list`. If the project is already registered, skip to step 3.
2. Call `synapse_manage_repos` with action `register` and the project's root path. Use the `repo_id` exactly as the response gives it.
3. Call `synapse_indexer_control` with action `status` and that `repo_id`. Report the phase and percentage.
4. Tell the user what to expect: search works as soon as the first pass is ready, and semantic search improves while embeddings finish in the background. There is no need to wait.
