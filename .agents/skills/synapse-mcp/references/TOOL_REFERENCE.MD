# Synapse MCP — Complete Tool Reference

This reference documents the default `ask_synapse` façade and every granular
compatibility tool. Load granular parameter detail only when a known direct
action or declared compatibility fallback is required.

---

## Global Parameters & Response Envelope

All Synapse tools accept:
- `wait_for_ready_ms` (integer): Time in milliseconds (e.g., `30000`) to block and wait if the repository is currently warming up, eliminating the need for LLMs to poll.

### Standardized `_synapse` Response Envelope
Every tool response contains a standardized `_synapse` metadata block:
- `boot` (string): `"ready"` when indexer is online.
- `ready` (boolean): `true` when system is operational.
- `repo_status` (map): Preserved top-level on repository-scoped calls.
- `diagnostic` (map, conditional): Present on empty or degraded outcomes with `classification` (`empty_recoverable`, `empty_expected`, `invalid_target`, `terminal_error`) and `hint` or `note`.
- `suggested_retry` (list of maps, conditional): Present when recovery is possible. Contains executable tool call parameters (`tool`, `action`, `args`, `reason`, `attempt_limit`).
- `suggested_next` (list of maps, conditional): Present after successful workflow steps to nudge the next logical tool call.

---
## Default Entry Point: `ask_synapse`

`ask_synapse` is the preferred natural-language interface for codebase
questions, deletion-safety checks, edits, reviews, debugging, test discovery,
repository/index administration, and capability discovery. All granular tools
remain advertised and directly dispatchable during the additive compatibility
stage. For "can I delete X?", "is X still used?", or "should I keep X?",
provide `inputs.chunk_id` when a previous Synapse result already identified the
target. Otherwise provide `repo_id` plus an arity-qualified exact target in
`inputs.symbol` so routing can select `synapse_codebase_insights` with action
`dead_code`; descriptive prose must ask for clarification or candidates rather
than silently guessing a symbol.

Required input:
- `query` (string): The question or objective.

Optional routing context:
- `repo_id`, `context`, `path`, `depth`, `limit`, `format`, `max_tokens`,
  `compress_payload`, and `wait_for_ready_ms`.
- `inputs` (map): Explicit action data such as files, content, replacements,
  roots, excludes, or chunk identifiers. Mutation payloads are never inferred
  from prose alone.
- `feedback` (map): A prior `route_id`, verdict, and optional opaque selected
  alternative ID.
- `confirm` and `preview_digest`: Used only for a later mutation-confirmation
  request.

```json
{
  "tool": "ask_synapse",
  "input": {
    "query": "Find where request timeouts are dispatched",
    "repo_id": "my-repo"
  }
}
```

Always inspect `completion_state`:
- `complete`: Use the returned result; no further call is mandatory.
- `tool_call_required`: Execute the first safe `next_tool_calls` entry.
- `clarification_required`: Request or submit the stated bounded choice.
- `confirmation_required`: Review the preview and use the digest-bound
  follow-up only with explicit confirmation.
- `entitlement_refusal`: Report the existing tier/authentication refusal.
- `no_safe_route`: **Do NOT fall back to shell or grep.** This is a
  confidence failure, not a system failure. The response includes
  `next_tool_calls` and `did_you_mean.active_repo_ids`. Act on them:
  (1) check `did_you_mean.active_repo_ids` — if the correct repo is listed,
  fix the `repo_id` and retry `ask_synapse` immediately;
  (2) `synapse_manage_repos` (list) — confirm repo is registered and active;
  (3) `synapse_indexer_control` (status) — confirm embeddings are ready;
  (4) retry `synapse_search_codebase` (symbol or regex) with a narrower query.
  Shell fallback is never permitted at this stage.

For any non-complete state, do not present the response as a finished answer.
`next_tool_calls` is executable guidance for the MCP client, not automatic
execution by Synapse. Preserve its route binding, explicit inputs, entitlement
checks, preview digest, and confirmation requirements. Granular fallbacks are
labelled compatibility/diagnostic paths and are not a way around safety gates.

---

## Granular Compatibility Reference

Use the following tools directly only for intentional known actions,
diagnostics, or a compatibility fallback returned by `ask_synapse`.

---

## 1. `synapse_manage_repos`

Manages repository registrations, lifecycle state, exclude paths, and listing.

Repository lifecycle values:
- `active`: the repository can be watched, booted, and re-indexed.
- `archived`: the repository's existing graph data remains searchable, but Synapse stops its indexer and excludes it from automatic boot, idle, and manual re-index scheduling until it is restored.

Use `archive` for stale or merged worktrees. Synapse also auto-archives clean Git worktrees whose branch work is already merged before scheduling indexing work, and scoped list/status responses explain this with `stale_worktree` guidance fields. Use `restore` to reactivate indexing. Use `unregister` only when you want destructive graph removal. Use `keep` when a worktree's branch is merged but uncommitted changes are intentional — this dismisses the dirty-merged advisory for the current session.

### Action: `list`

Returns all registered repositories with their root paths and indexing state.

```json
{ "tool": "synapse_manage_repos", "input": { "action": "list" } }
```

Unscoped `list` returns enriched rows per repo. Each row includes:
- `repo_id`, `root`, `lifecycle`, `chunk_count`, `status`
- `current_phase` — active indexing phase name or `"pending"`
- `percent_complete` — embedding coverage percent (0–100.0)
- `indexed_files` — number of files indexed so far
- `embeddings_partial` — `true` if embedding pass is incomplete
- `indexer_alive` — `true` if the GenServer for this repo is running
- `suggested_actions` — array of `{label, tool, args}` objects ready to fire
- `dirty_merged_worktree` — `true` if branch is merged but working tree is dirty (advisory only)
- `dirty_merged_guidance` — human-readable 3-choice guidance string
- `dirty_merged_file_count` — number of dirty files reported by `git status --porcelain`
- `dirty_merged_branch` — branch name

**Always read `suggested_actions` first.** Each object has `{label, tool, args}` — pass `args` directly to the tool without reformatting.

Pass a `repo_id` to get full `repo_status` detail for one repository. `suggested_actions` is also included on scoped responses for consistency.

**Dirty-merged advisory:** when `dirty_merged_worktree: true`, the `suggested_actions` contains exactly 3 choices:
1. `archive` — stop indexing, keep graph searchable
2. `unregister` — delete graph data permanently
3. `keep` — changes are intentional, dismiss advisory for this session

Call one immediately: `synapse_manage_repos` with `action` + `repo_id`.

### Action: `register`

Registers a new repository for indexing. Git worktrees are auto-detected.

```json
{
  "tool": "synapse_manage_repos",
  "input": {
    "action": "register",
    "repo_id": "my-repo",
    "root": "/Users/dev/my-repo",
    "exclude": ["deps", "_build", "node_modules", ".git"]
  }
}
```

**Note:** Most IDEs auto-register workspaces on connection. Manual registration
is only needed for external/secondary folders.

### Action: `archive`

Archives a registered repository without deleting its graph data. This is the preferred stale-worktree cleanup action.

```json
{
  "tool": "synapse_manage_repos",
  "input": { "action": "archive", "repo_id": "my-stale-worktree" }
}
```

Response fields include `status: "archived"`, `repo_id`, `lifecycle: "archived"`, and a note confirming that existing graph data remains searchable.

### Action: `restore`

Restores an archived repository to active lifecycle and restarts indexing.

```json
{
  "tool": "synapse_manage_repos",
  "input": { "action": "restore", "repo_id": "my-stale-worktree" }
}
```

Response fields include `status: "restored"`, `repo_id`, `lifecycle: "active"`, and a note confirming that indexing has been restarted.

### Action: `keep`

Dismisses a dirty-merged worktree advisory for the current session. Use when you have verified that the uncommitted changes in a merged worktree are intentional and you do not want to archive or remove it yet.

```json
{
  "tool": "synapse_manage_repos",
  "input": { "action": "keep", "repo_id": "my-wip-worktree" }
}
```

Response fields include `status: "kept"`, `repo_id`, `lifecycle: "active"`, and a note. The advisory reappears after a Synapse restart — commit or stash the changes to suppress it permanently.

### Action: `unregister`

Permanently removes a repository and deletes its graph data.

```json
{
  "tool": "synapse_manage_repos",
  "input": { "action": "unregister", "repo_id": "my-repo" }
}
```

### Action: `update_excludes`

Updates indexing exclusion paths. Pass `merge: true` to append instead of replace.

```json
{
  "tool": "synapse_manage_repos",
  "input": {
    "action": "update_excludes",
    "repo_id": "my-repo",
    "exclude": ["vendor", "tmp"],
    "merge": true
  }
}
```

---

## 2. `synapse_indexer_control`

Controls the indexing pipeline and server health.

### Action: `health`

Cheap health probe — confirms transport is up.

```json
{ "tool": "synapse_indexer_control", "input": { "action": "health" } }
```

### Action: `status`

Returns per-repository indexing state, chunk counts, embedding readiness, unresolved edge
counts, and top summary candidates. Use this to decide whether a repository is ready for
search, identify gaps in the graph, and find high-value summarisation targets.

**Scoped (recommended at scale):** pass `repo_id` — performs a direct SQLite lookup for that
one repository. Safe to call at 50+ repositories without timeout risk.

**Unscoped:** omit `repo_id` — aggregates all registered repositories. Use only when you need
a global overview; results are cached for 60 s when all indexers are idle.

```json
{ "tool": "synapse_indexer_control", "input": { "action": "status", "repo_id": "my-repo" } }
```

**Key response fields (per entry in `repos[]`):**

| Field | What it means |
|---|---|
| `status` | Indexer lifecycle: `idle`, `indexing`, `error` |
| `current_phase` | Active phase: `quick_pass`, `deep_dive_1`, `deep_dive_2`, `complete` |
| `chunk_count` | Total indexed chunks — use this to gauge index completeness |
| `indexed_files` | Number of source files processed |
| `embeddings_partial` | `true` while embedding is still in progress — semantic search may miss chunks |
| `repo_unresolved_edges` | Edges whose target chunk does not yet exist in this repo's index. Shrinks to zero once deep_dive passes finish. Non-zero after a full index often means a cross-repo dependency is missing its target repository. |
| `needs_summary` | Top 20 chunks (ranked by `hit_count`) that have been queried at least once but have no cached summary. Pass these `chunk_id`s to `synapse_knowledge_cache` (action: `save_summary`) to improve future retrieval quality for those symbols. |
| `watcher_alive` | Whether the filesystem watcher is running — if `false`, file saves will not auto-reindex |
| `readiness_guide` | Which tool actions are reliable at the current indexing phase |

**Top-level response fields:**

| Field | What it means |
|---|---|
| `unresolved_edges` | Global total across all repos — useful for cross-repo graph health checks |
| `db_fragmented` | SQLite freelist ratio > 20% — run `VACUUM` if `true` |

**Cache TTL behaviour:**

- All indexers idle → cached for **60 seconds** (prevents timeout at large repo counts)
- Active indexing (non-embedding phase) → cached for **10 seconds**
- Embeddings in progress → cached for **5 seconds**

A freshly triggered re-index may not appear in status immediately — wait up to 10 s or
call `trigger` first then poll `status`.

Optional: `include_profile: true` adds language/kind chunk distribution breakdown (slower,
useful for understanding what the indexer has seen across a repository).

---

### Action: `trigger`

Triggers a re-index. Modes: `quick_pass`, `deep_dive_1`, `deep_dive_2`, `full`, `x_repo`.

```json
{
  "tool": "synapse_indexer_control",
  "input": {
    "action": "trigger",
    "repo_id": "my-repo",
    "mode": "full",
    "force": true
  }
}
```

- `x_repo` mode: resolves cross-repo edges. Omit `repo_id` — runs across all repos.
- `path`: target a single file/directory instead of full repo.

---

## 3. `synapse_search_codebase`

Three search modes over the indexed codebase.

**Note:** The chunk payloads returned by `semantic` and `symbol` searches now embed an `outbound_edges` array containing the `chunk_id`s of all called dependencies. Pass these to `synapse_inspect_files` (action: `read_chunk`) to instantly read callees without a separate search.

### Action: `semantic`

Cosine similarity search over embeddings. Best for conceptual queries.

```json
{
  "tool": "synapse_search_codebase",
  "input": {
    "action": "semantic",
    "query": "retry logic with exponential backoff",
    "repo_id": "my-repo",
    "limit": 10,
    "min_score": 0.6
  }
}
```

**Requires embeddings** — check `embeddings_partial` in `repo_status`. If `true`,
results may be incomplete; fall back to symbol/regex.

### Action: `symbol`

Fast exact/fuzzy symbol index lookup.

```json
{
  "tool": "synapse_search_codebase",
  "input": {
    "action": "symbol",
    "symbol": "do_dispatch",
    "repo_id": "my-repo",
    "fuzzy": true
  }
}
```

**Works immediately after `quick_pass`** — no embeddings needed.

Filters: `kind` (function, module, type), `language`, `path`.

### Action: `regex`

Regular expression search over indexed source.

```json
{
  "tool": "synapse_search_codebase",
  "input": {
    "action": "regex",
    "query": "defmodule.*Dispatcher",
    "repo_id": "my-repo",
    "case_insensitive": true,
    "match_per_line": true
  }
}
```

**Tip:** Compression is on by default — regex payloads can be large but are automatically minified.

---

## 4. `synapse_explore_graph`

Navigate the call graph around a specific chunk. All four actions accept `chunk_id`,
`symbol` + `repo_id`, or `file_path` + `repo_id` — no preceding lookup required.

> **Token-saving tip:** Both `callers` and `callees` support `depth` 1–3. Use
> `depth: 2` or `depth: 3` to get multi-hop results in a single call instead of
> chaining multiple depth-1 requests.

### Action: `callers`

Find all chunks that call a given chunk, with transitive depth.

```json
{
  "tool": "synapse_explore_graph",
  "input": {
    "action": "callers",
    "chunk_id": "my-repo:lib/dispatcher.ex:120",
    "depth": 2,
    "exclude_tests": true
  }
}
```

### Action: `callees`

Find all functions/modules/types that a chunk calls or depends on, with transitive depth.

```json
{
  "tool": "synapse_explore_graph",
  "input": {
    "action": "callees",
    "chunk_id": "my-repo:lib/dispatcher.ex:120",
    "depth": 2
  }
}
```

Each result includes a `depth` field (1 = direct dependency, 2 = dependency-of-dependency).

### Action: `context`

Returns a chunk's details with its local callers, callees, and related code.
Accepts `chunk_id`, `symbol`, or `file_path` + `line`.

```json
{
  "tool": "synapse_explore_graph",
  "input": {
    "action": "context",
    "symbol": "do_dispatch",
    "repo_id": "my-repo"
  }
}
```

### Action: `cycles`

Detect circular dependencies reachable from a given chunk. Returns a definitive
`has_cycles` boolean with exact cycle paths — no manual traversal needed.

```json
{
  "tool": "synapse_explore_graph",
  "input": {
    "action": "cycles",
    "symbol": "MyModule.fn/1",
    "repo_id": "my-repo",
    "max_depth": 5,
    "direction": "callees"
  }
}
```

Returns `has_cycles` (boolean), `cycles` (array of `{path, chunk_ids, length, edge_types}`),
and `count`. Use before proposing architectural changes.

---

## 5. `synapse_get_context`

Advanced direct context retrieval for known workflows and compatibility use.

### Action: `find`

Runs semantic search, exact lookup, fuzzy matching, and call-graph traversal in parallel.
Returns ranked results with `structured_results`, `result_buckets`, and `index_health`.

```json
{
  "tool": "synapse_get_context",
  "input": {
    "action": "find",
    "query": "how tool dispatch handles timeouts",
    "repo_id": "my-repo"
  }
}
```

Filters: `kind`, `language`, `path`, `limit`, `exclude_tests`.

### Action: `edit`

Gathers everything you need before editing code: callers, callees, must-read files,
likely tests, behaviour boundaries, and risk assessment.

```json
{
  "tool": "synapse_get_context",
  "input": {
    "action": "edit",
    "symbol": "create_share_link/2",
    "repo_id": "my-repo",
    "intent": "add rate limiting"
  }
}
```

Can target by `chunk_id`, `symbol`, or `file_path` + `line`.

### Action: `explain`

Natural-language explanation of a chunk with tags, parameters, and callers.

```json
{
  "tool": "synapse_get_context",
  "input": {
    "action": "explain",
    "chunk_id": "my-repo:lib/dispatcher.ex:120"
  }
}
```

### Action: `onboard`

Layered reading guide for learning a subsystem — from entry points to internals.

```json
{
  "tool": "synapse_get_context",
  "input": {
    "action": "onboard",
    "query": "behaviour trace subsystem",
    "repo_id": "my-repo"
  }
}
```

---

## 6. `synapse_inspect_files`

Read source files, chunks, or count lines.

### Action: `read_files`

Read one or more files from disk. Supports directories (returns indexed children),
line ranges, and outline format.

```json
{
  "tool": "synapse_inspect_files",
  "input": {
    "action": "read_files",
    "repo_id": "my-repo",
    "files": [
      { "path": "lib/dispatcher.ex", "ranges": ["90-120", "200-230"] }
    ],
    "format": "outline"
  }
}
```

- Pass a directory path to list its contents: `"files": "lib/"`
- `format: "outline"` strips function bodies — great for scanning APIs.
- `max_read_bytes` / `max_read_bytes_per_file` cap total read size.

### Action: `read_chunk`

Read a chunk's raw source from the in-memory store (no disk I/O).

```json
{
  "tool": "synapse_inspect_files",
  "input": {
    "action": "read_chunk",
    "chunk_id": "my-repo:lib/dispatcher.ex:120"
  }
}
```

### Action: `count_lines`

Count lines across files matching a path filter.

```json
{
  "tool": "synapse_inspect_files",
  "input": {
    "action": "count_lines",
    "repo_id": "my-repo",
    "path": "lib/"
  }
}
```

---

## 7. `synapse_modify_files`

Edit files with safety guarantees.

### Action: `write_safely`

Atomic write with Trunk lint validation and rollback on failure.

```json
{
  "tool": "synapse_modify_files",
  "input": {
    "action": "write_safely",
    "repo_id": "my-repo",
    "files": [
      {
        "path": "lib/dispatcher.ex",
        "content": "...new content...",
        "mode": "overwrite"
      }
    ],
    "pre_check": true,
    "dry_run": false
  }
}
```

- `mode`: `"overwrite"` | `"append"` | `"patch"`
- `patch` mode uses `patches: [{ "range": "45-50", "content": "..." }]`
- `lint: false` skips validation; `lint: "report_only"` reports without rollback
- `dry_run: true` runs semantic diff simulation without writing to disk
- `pre_check: true` computes blast radius before writing

### Action: `find_and_replace`

Global regex find-and-replace across matching indexed files.

```json
{
  "tool": "synapse_modify_files",
  "input": {
    "action": "find_and_replace",
    "repo_id": "my-repo",
    "query": "old_function_name",
    "replacement": "new_function_name",
    "path": "lib/",
    "limit": 50
  }
}
```

Supports backreferences (`\\1`, `\\2`), `case_insensitive`, and `kind`/`language` filters.

### Action: `delete_chunk`

Delete a specific chunk and its learning signals from the index.

```json
{
  "tool": "synapse_modify_files",
  "input": {
    "action": "delete_chunk",
    "chunk_id": "my-repo:lib/old_module.ex:1"
  }
}
```

---

## 8. `synapse_change_review`

Review and assess changes.

### Action: `analyse_diff`

Quick orientation of a change set: modified symbols, must-read files, tests to run.

```json
{
  "tool": "synapse_change_review",
  "input": {
    "action": "analyse_diff",
    "diff": "--- a/lib/dispatcher.ex\n+++ b/lib/dispatcher.ex\n...",
    "repo_id": "my-repo"
  }
}
```

### Action: `review_diff`

Detailed safety review with per-node risk scores, blind spots, and contract warnings.

```json
{
  "tool": "synapse_change_review",
  "input": {
    "action": "review_diff",
    "diff": "...",
    "repo_id": "my-repo",
    "risk_level": "high"
  }
}
```

### Action: `impact`

Full transitive downstream blast radius.

```json
{
  "tool": "synapse_change_review",
  "input": {
    "action": "impact",
    "chunk_ids": ["my-repo:lib/dispatcher.ex:120"],
    "depth": 3,
    "exclude_tests": true
  }
}
```

Also accepts: `commit_range` (e.g. `"HEAD~1..HEAD"`), `file_paths`, or
bare `repo_id` (falls back to `git diff HEAD` for uncommitted changes).

---

## 9. `synapse_codebase_insights`

Analyse codebase structure, APIs, contracts, dependencies, and function-level deletion safety.

### Action: `detect`

Language and framework breakdown by file extension and manifest analysis.

### Action: `public_api`

Public modules/functions sorted by external caller count.

### Action: `dead_code`

Read-only function-level deletion-safety check for one exact symbol or
`chunk_id`. Prefer routing through
`ask_synapse` for user phrasing such as "can I delete X?", "is X still
used?", or "should I keep X?" because the façade preserves
`completion_state`, missing-input guidance, and `agent_instruction`. Direct
compatibility calls require `chunk_id` when known, or `repo_id` plus an
arity-qualified `symbol` such as `Parser.parse/2`.

```json
{
  "tool": "ask_synapse",
  "input": {
    "query": "Can I delete this chunk?",
    "repo_id": "my-repo",
    "inputs": { "chunk_id": "my-repo:lib/parser.ex:120" }
  }
}
```

```json
{
  "tool": "ask_synapse",
  "input": {
    "query": "Is Parser.parse/2 still used?",
    "repo_id": "my-repo",
    "inputs": { "symbol": "Parser.parse/2" }
  }
}
```

Response fields to inspect before advising a user:
- `preferred_identifier` and `valid_input_patterns` — copy-pasteable guidance for the next correct call.
- `scope` — currently `function`, so do not present the answer as clause-level proof.
- `clause_level_analysis` — currently `not_supported`; Elixir multi-clause fallback reachability is not yet proven.
- `safe_to_delete` — only `true` when Synapse has enough evidence for a safe source-deletion recommendation.
- `deletion_risk` — concise risk label for user-facing wording.
- `confidence` and `caveats` — explain uncertainty, especially unknown visibility or framework entrypoints.
- `supporting_evidence.production_callers` and `supporting_evidence.test_callers` — prevents manual path-classification mistakes.
- `symbol_guidance` — explains whether a bare symbol was resolved to an arity-qualified variant or remains ambiguous.
- `agent_instruction` — tells the LLM whether to answer, ask for a symbol, or gather more evidence.

Production callers mean keep it. Test-only callers and unknown visibility are
caution signals, not automatic deletion. Do not use `synapse_modify_files`
(action `delete_chunk`) as source deletion guidance; it removes index data, not
proof that source should be deleted.

### Action: `contracts`

HTTP response boundaries, JSON serialisation, Ecto schemas, event emissions.

### Action: `dependencies`

Dependency graph from package manifests (mix.exs, package.json, pyproject.toml).

### Action: `overview`

Consolidated single-turn view: language detect + coverage + key entry points.

### Action: `refactor_opportunities`

Ranks chunks by coupling and size for refactoring candidates.

All actions accept: `repo_id`, `path`, `language`, `limit`.

---

## 10. `synapse_test_quality`

Test mapping, coverage analysis, and linting setup.

### Action: `coverage`

Reports production files with no/weak/strong test coverage.

### Action: `find_tests`

Discovers tests for a symbol/chunk/query — features, step definitions, unit tests, fixtures.

### Action: `recommend_test_targets`

Prioritised list of what to test next, with behaviour summaries. Excludes nested
submodules by default — pass `path` to target a specific sub-repo.

### Action: `setup_trunk`

Configures Trunk linting for a repository.

---

## 11. `synapse_debug_trace`

Debugging and execution flow tracing.

### Action: `trace_behaviour`

Maps execution flow from a symbol: branching, state access, side effects, linked tests.
Returns ranked paths with confidence scores and uncertainty flags.

```json
{
  "tool": "synapse_debug_trace",
  "input": {
    "action": "trace_behaviour",
    "query": "CacheService.resolve/2",
    "repo_id": "my-repo",
    "max_depth": 6,
    "max_paths": 3,
    "runtime_verification": true
  }
}
```

### Action: `resolve_stack`

Parses crash stack traces, maps frames to chunks, identifies root cause, suggests tests.

```json
{
  "tool": "synapse_debug_trace",
  "input": {
    "action": "resolve_stack",
    "stack_trace": "** (FunctionClauseError) no function clause matching...",
    "repo_id": "my-repo"
  }
}
```

Also accepts structured `frames` array to bypass raw text parsing.

---

## 12. `synapse_knowledge_cache`

Persistent knowledge management.

### Action: `learn`

Records that a search result was useful. The association is immediately queryable as provisional evidence; promotion requires repeated explicit evidence and is not guaranteed by one `learn` call.

```json
{
  "tool": "synapse_knowledge_cache",
  "input": {
    "action": "learn",
    "query": "how dispatch handles timeouts",
    "chunk_id": "my-repo:lib/dispatcher.ex:120",
    "weight": 1.0
  }
}
```

### Action: `save_summary`

Persists a human-readable summary on a chunk. Supports batch via `summaries` array.

```json
{
  "tool": "synapse_knowledge_cache",
  "input": {
    "action": "save_summary",
    "chunk_id": "my-repo:lib/dispatcher.ex:120",
    "summary": "Main router that dispatches incoming MCP tool calls to handler modules.",
    "summary_type": "user"
  }
}
```

`summary_type`: `"user"` (default) marks as human-written. `"system"` marks as
automated placeholder — will not exclude the chunk from documentation suggestions.

### Action: `query`

Retrieves cached summaries by natural language, filenames, symbols, chunk IDs, and exact learned associations. Returned `match_details` explain the source of each match (`summary`, `file_path`, `symbol`, `chunk_id`, or `learned_association`), whether it is promoted, and how many explicit signals support it. Verify provisional learned associations before editing.

```json
{
  "tool": "synapse_knowledge_cache",
  "input": {
    "action": "query",
    "query": "api_play_galaxy_lifecycle_feature_test.exs line 44"
  }
}
```

### Action: `suggest`

Lists high-value chunks needing summaries based on access frequency and traffic weight.

```json
{
  "tool": "synapse_knowledge_cache",
  "input": {
    "action": "suggest",
    "repo_id": "my-repo",
    "limit": 10,
    "min_hit_count": 3
  }
}
```

---

## 13. `synapse_capability_manifest`

Returns the structured manifest of all live tool capabilities — schemas, mutation
characteristics, relationships, and groupings. No action parameter needed.

```json
{
  "tool": "synapse_capability_manifest",
  "input": { "include_examples": true }
}
```

---

## Global Parameters (available on all tools)

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `compress_payload` | boolean | `true` | Minify JSON response (short keys, prune empties). ON by default. Pass `false` to opt out. |
| `repo_id` | string | — | Scope to a specific repository |

## Legacy Tool Name Mapping

If you encounter legacy tool names in documentation or prompts, use this mapping:

| Legacy Name | Current Tool | Action |
|---|---|---|
| `synapse_fast_context` | `synapse_get_context` | `"find"` |
| `synapse_edit_context` | `synapse_get_context` | `"edit"` |
| `synapse_explain_chunk` | `synapse_get_context` | `"explain"` |
| `synapse_onboarding_guide` | `synapse_get_context` | `"onboard"` |
| `synapse_lookup_symbol` | `synapse_search_codebase` | `"symbol"` |
| `synapse_semantic_search` | `synapse_search_codebase` | `"semantic"` |
| `synapse_grep_source` | `synapse_search_codebase` | `"regex"` |
| `synapse_find_callers` | `synapse_explore_graph` | `"callers"` |
| `synapse_find_callees` | `synapse_explore_graph` | `"callees"` |
| `synapse_chunk_context` | `synapse_explore_graph` | `"context"` |
| `synapse_read_files` | `synapse_inspect_files` | `"read_files"` |
| `synapse_read_chunk` | `synapse_inspect_files` | `"read_chunk"` |
| `synapse_write_files_safely` | `synapse_modify_files` | `"write_safely"` |
| `synapse_find_and_replace` | `synapse_modify_files` | `"find_and_replace"` |
| `synapse_analyse_diff` | `synapse_change_review` | `"analyse_diff"` |
| `synapse_review_diff` | `synapse_change_review` | `"review_diff"` |
| `synapse_change_impact` | `synapse_change_review` | `"impact"` |
| `synapse_trace_behaviour` | `synapse_debug_trace` | `"trace_behaviour"` |
| `synapse_resolve_stack_trace` | `synapse_debug_trace` | `"resolve_stack"` |
| `synapse_save_summary` | `synapse_knowledge_cache` | `"save_summary"` |
| `synapse_record_useful_result` | `synapse_knowledge_cache` | `"learn"` |
