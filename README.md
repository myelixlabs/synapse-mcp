# Synapse-MCP

> A persistent code knowledge graph for AI agents. Query your codebase as a live graph — not as text files — so every AI session starts with context already built.

---

## Why This Exists

AI coding agents have a hidden structural problem: **every conversation starts from scratch**.

Ask an agent to trace a bug, review a change, or understand a subsystem, and it does something like this:

1. Runs grep searches to find candidate files
2. Reads those files in full, burning large portions of the context window
3. Mentally reconstructs the call chain from raw text
4. Guesses at what it might have missed and moves on

On a small codebase this is tolerable. On anything real it breaks down fast. The agent runs out of context window before it has the full picture. It can't know what calls what without reading both ends. It can't tell you what a function does without reading its body first. And when the conversation ends, everything it learned is thrown away.

This is the fundamental mismatch: **LLMs are stateless, codebases are not**.

---

## What Synapse Does

Synapse-MCP is a persistent code knowledge graph that runs alongside your IDE. Rather than searching source text on demand, it continuously indexes your codebase into a structured graph of chunks, edges, embeddings, and summaries. When an AI agent needs to understand your code, it queries a pre-built model of it — the codebase is already understood before the question is asked.

The difference is not just speed. It is qualitative. A grep tool tells you where a word appears. Synapse answers *what does this subsystem do, what calls it, what tests cover it, and is it safe to change* — in under a second, without reading a single file.

### Concrete before/after

**Without Synapse** — agent asks "what calls `invalidate_player_cache`?":
- 3–5 grep turns across the repo
- 2–4 full file reads to confirm context
- Reconstructed call chain from text, probably incomplete
- 8–12 tool calls, ~2,000–6,000 tokens of context consumed

**With Synapse** — same question:
```
synapse_callers(symbol: "invalidate_player_cache")
→ 3 direct callers with file:line, depth, and resolved symbols
→ 1 tool call, ~200 tokens
```

That ratio compounds across an entire session. Synapse does not make the agent slightly faster — it frees the context window for reasoning instead of reconstruction.

---

## The Compounding Advantage

The deeper differentiator is **persistence and accumulation**. Every summary written, every query that hits the cache, every call edge resolved — that is permanent signal that survives across restarts and across sessions.

- Call `synapse_summarise` on a function once. Every future query against that chunk gets your explanation for free, forever.
- Repeat queries return in under 10ms from a learning cache. The more a codebase is used with Synapse, the faster and more accurate it becomes.
- After a few sessions of active use, Synapse has a working model of your codebase that reflects how it is actually used — not just what the source text says.

A fresh agent session on a Synapse-indexed codebase is not starting from zero. It is inheriting everything every previous session contributed.

---

## How Agents Use Synapse — Real Workflows

Synapse is not a single search tool. It is an integrated workflow layer that replaces the grep → read → grep → read loop that dominates agent sessions today. Below are three real workflows showing the exact tool calls an agent makes with Synapse versus without it.

### Workflow 1: Feature development — "add a rate limit to the invite endpoint"

**Without Synapse** (typical agent session):
1. `grep -r "invite"` → 47 results across controllers, tests, templates
2. Read `play_controller.ex` (400 lines) to find the invite function
3. `grep -r "create_share_link"` → find callers
4. Read `api/play.ex` (600 lines) to understand the data layer
5. `grep -r "invite" test/` → find existing test coverage
6. Read 2–3 test files to understand the existing contract
7. Guess at what other modules might be affected

**Result:** 7+ tool calls, 3–4 full file reads, ~4,000 tokens of raw file content, incomplete picture.

**With Synapse** (same task):
```
1. synapse_fast_context(query: "invite endpoint rate limiting")
   → top 7 chunks with callers/callees attached, ~400ms

2. synapse_edit_context(symbol: "create_share_link/2", intent: "add rate limit")
   → must-read files, callers, callees, likely tests, behaviour boundaries, risk assessment

3. synapse_tests_for(symbol: "create_share_link/2")
   → galaxy_invite_steps.exs, 41_galaxy_share_link_invites.feature, ranked by confidence
```

**Result:** 3 tool calls, 0 file reads, ~600 tokens, complete picture including test contracts and safety boundaries.

### Workflow 2: Bug investigation — "singleflight cache is returning stale data"

**Without Synapse:**
1. `grep -r "singleflight"` → find the module
2. Read the full singleflight module (200+ lines)
3. `grep -r "get_or_compute"` → find callers
4. Read each caller file to trace the data flow
5. `grep -r "ets.insert"` → find where the cache writes happen
6. Read those files, try to reconstruct the write/read/invalidation lifecycle
7. Still missing: what events does this emit? What tests cover this exact path?

**With Synapse:**
```
1. synapse_behaviour_trace(query: "get_or_compute_singleflight", max_paths: 3)
   → 3 ranked execution paths from entrypoint to target
   → per-hop behaviour signals: ets_write, ets_lookup, telemetry_execute
   → uncertainty gaps flagged where edges are inferred
   → linked tests ranked by relevance

2. synapse_impact(chunk_ids: ["<singleflight_chunk_id>"])
   → blast radius: 12 transitive callers
   → blind spots: 3 callers with no test coverage
   → contract signals: ets_write + telemetry_execute flagged
```

**Result:** 2 tool calls, complete lifecycle trace with state read/write signals, no file reads needed.

### Workflow 3: PR review — "review this diff for safety"

**Without Synapse:**
1. Read the diff (provided)
2. For each changed file, `grep` to find what calls the changed functions
3. Read those caller files to assess blast radius
4. Manually search for related test files
5. Read test files to check if the change is covered
6. Try to assess whether state writes or events are affected (by reading source)
7. Write review comments based on incomplete analysis

**With Synapse:**
```
1. synapse_review(diff: "<unified diff>", repo_id: "my_app")
   → ranked risks with risk_score and risk_level per affected node
   → blind spots: uncovered callers sorted by risk
   → total_tests_to_run: deduplicated, confidence-ranked test list
   → contract_warnings: flags if changed code writes state or emits events
   → recommended_action per risk ("add test coverage before merging")
```

**Result:** 1 tool call. The agent gets a complete review pack — blast radius, test gaps, contract warnings, and specific recommendations — without reading a single file beyond the diff itself.

### The cost difference

| Metric | Without Synapse | With Synapse |
|---|---|---|
| Tool calls per task | 8–15 | 1–3 |
| File reads per task | 3–6 full files | 0 (graph-served) |
| Context tokens consumed | 3,000–8,000 | 200–800 |
| Information completeness | Partial, best-effort | Structural, with gap reporting |
| Test coverage awareness | Manual grep, often missed | Automatic, confidence-ranked |
| Persists across sessions | ❌ | ✅ |

### Measured example: understanding the Synapse-MCP codebase itself

We tested this live — asking an agent to understand the full Synapse-MCP tool surface (29 tool modules, their capabilities, and how they connect).

**Manual approach** — standard file browsing:

| Step | Operation |
|---|---|
| 1 | `list_dir` tools directory → 29 file names |
| 2 | `list_dir` core modules directory → 19 file names |
| 3–9 | `view_file` × 7 (fast_context.ex, impact.ex, review.ex, onboard.ex, edit_context.ex, behaviour_trace.ex, tests_for.ex) |
| 10–11 | `view_file` README.md × 2 (split across line ranges) |

**Result:** 11 tool calls. 7 file reads consuming ~3,100 lines of source. No caller/callee graph. No linked tests. No related-code discovery.

**Synapse approach** — graph queries only:

| Step | Operation | What it returned |
|---|---|---|
| 1 | `synapse_fast_context` | Full dispatcher with all 27 registered tool modules, FastContext moduledoc, spec.md architecture pattern — all with callers/callees attached |
| 2 | `synapse_onboard` | Layered reading order for the behaviour trace subsystem, key callees per hop, linked BDD tests, behavioural signals |
| 3 | `synapse_explore_graph` (action `"context"`) ×3 (parallel) | Graph neighbourhood for impact, review, and onboard — callees, related chunks, spec.md cross-references |

**Result:** 4 tool calls (3 parallelised). 0 file reads. Every result included caller/callee edges, related chunks, and linked tests that the manual approach never discovered.

| Metric | Manual | Synapse |
|---|---|---|
| Tool calls | 11 | 4 |
| File reads | 7 | 0 |
| Lines of raw source in context | ~3,100 | 0 |
| Caller/callee graph included | ❌ | ✅ |
| Linked tests included | ❌ | ✅ |
| Related chunks surfaced | ❌ | ✅ |

---

## Tool Surface

Tools are grouped by the workflow stage they support. Each tool accepts an `action` parameter to choose the specific operation, returning structured data — not raw text — so agents spend tokens on reasoning, not parsing.

### 1. Understanding the Codebase
- **`synapse_search_codebase`** — Search using semantic similarity, symbol lookups, or regex grep.
  - Actions: `"semantic" | "symbol" | "regex"`
  - **`regex` — always pass `repo_id`:** without it, the search scans all indexed repos, caps at 20 results, and returns a `synapse_warning` telling you to re-run with `repo_id`.
  - **`regex` + `match_per_line: true`:** returns `[{repo_id, file, line_number, line_content}]` — ideal for locating specific function definitions.
- **`synapse_explore_graph`** — Explore callers, callees, and context around a chunk.
  - Actions: `"callers" | "callees" | "context"`
  - **All three actions** accept `chunk_id` **or** `repo_id` + `symbol` **or** `repo_id` + `file_path` (+ optional `line`) — no prior lookup needed.
  - One-call caller trace: `{action: "callers", repo_id: "MY_REPO", symbol: "MyModule.fn/1"}`
  - One-call callee trace: `{action: "callees", repo_id: "MY_REPO", symbol: "MyModule.fn/1"}`
- **`synapse_get_context`** — Primary context gathering tool for open-ended queries, editing prep, or onboarding.
  - Actions: `"find" | "edit" | "explain" | "onboard"`
- **`synapse_inspect_files`** — Inspect file structures, read file ranges, or count lines in codebases.
  - Actions: `"read_files" | "read_chunk" | "count_lines"`
- **`synapse_codebase_insights`** — Detect languages, identify public APIs, scan interface contracts, build dependency graphs, surface refactoring opportunities, or retrieve consolidated repository overviews.
  - Actions: `"detect" | "public_api" | "contracts" | "dependencies" | "overview" | "refactor_opportunities"`

### 2. Making Changes Safely
- **`synapse_modify_files`** — Edit source files atomically (overwrite/append/patch), run find-and-replace, or delete chunks. Integrates Trunk lint validation.
  - Actions: `"write_safely" | "find_and_replace" | "delete_chunk"`
- **`synapse_change_review`** — Analyse diffs, review change risks, and evaluate downstream blast-radius impact.
  - Actions: `"analyse_diff" | "review_diff" | "impact"`
- **`synapse_test_quality`** — Identify test coverage gaps, find feature/unit tests for a symbol, recommend test targets (both unit/integration and BDD features) with behaviour summaries, and configure Trunk.
  - Actions: `"coverage" | "find_tests" | "setup_trunk" | "recommend_test_targets"`
  - *Note on Nested Repositories (recommend_test_targets)*: By default, recommendations exclude nested repositories and git submodules (detected via `.git` or project markers). You can explicitly opt in to target a sub-repository by passing its directory path in the `path` parameter.
- **`synapse_debug_trace`** — Trace ranked behavioral execution paths or map crash stack traces to code chunks.
  - Actions: `"trace_behaviour" | "resolve_stack"`

### 3. Knowledge & Repo Management
- **`synapse_knowledge_cache`** — Manage learning query hits, save chunk summaries, and suggest docs needs.
  - Actions: `"learn" | "save_summary" | "suggest"`
- **`synapse_manage_repos`** — Register new repositories, manage lifecycle state, update exclude paths, unregister, or list all registered workspaces.
  - Actions: `"list" | "register" | "archive" | "restore" | "unregister" | "update_excludes"`
  - **Lifecycle management:** `list` responses include `lifecycle: "active" | "archived"`. Use `archive` for stale or merged worktrees so Synapse stops watching/re-indexing them while keeping existing graph data searchable; use `restore` when active indexing is needed again. Use `unregister` only for destructive graph removal.
- **`synapse_indexer_control`** — Monitor indexing phase progress, health status, and trigger manual indexing.
  - Actions: `"status" | "trigger" | "health"`
- **`synapse_capability_manifest`** — Returns the structured manifest of live Synapse MCP tool capabilities.

---

## Key Design Principles

- **Staged indexing** — a fast `quick_pass` makes the graph queryable within seconds; deeper semantic passes run in the background without blocking queries.
- **Persistent across restarts** — the knowledge graph is written to SQLite and warmed back into ETS on startup; no cold-start delay after a server restart.
- **Shared across IDEs** — in SSE mode, all connected IDEs share one index: one ingestion cost, universal benefit.
- **Concurrent ingestion** — the indexing pipeline uses a worker pool scaled to CPU cores, saturating available hardware for maximum throughput on large monorepos.
- **Smart exclusions** — build artefacts, dependency trees, caches, and framework outputs are excluded by default for Elixir, Python, JavaScript, and Node.js projects.

---

## Current Model

- Workspaces opened in your IDE are automatically registered and indexed during the MCP connection handshake. Manual registration via `synapse_add_repo` is only required for external/secondary folders.
- Indexing is staged so useful graph data appears before the full semantic pass completes.
- Query tools report repo readiness so an agent can decide whether to wait, narrow scope, or continue with partial context.
- **Cleaner graph answers (less symbol noise):** Elixir special-form noise is normalised and filtered (`when`, `->`, `<-`, `.`, `^`, `{}`, etc.), so `synapse_search_codebase` (symbol), `synapse_explore_graph` (context/callers/callees), and `synapse_get_context` (find) return cleaner structural results.
- **FastContext richer outputs:** `synapse_fast_context` returns `structured_results`, `result_buckets` (primary implementation, callers/entry points, tests, related UI/observers), `index_health`, and stronger cache metadata (`cache_hit`, optional `cached_at`, `learn_hint`).
- **FastContext implementation expansion:** thin dispatcher chunks are expanded by callee hops automatically, helping queries land on concrete implementation rather than only wrapper modules.
- **Pre-edit planning:** `synapse_edit_context` builds an edit-readiness pack (call graph, likely tests, must-read files, behaviour boundaries, and risk-oriented guidance).
- **Test discovery:** `synapse_tests_for` finds likely features, step definitions, tests, support files, and fixtures for a target symbol/chunk/query.
- **Behaviour tracing:** `synapse_behaviour_trace` traces behavioural contracts from a target symbol/chunk, with runtime verification, entrypoint inference, and static signal extraction.
- **Impact analysis:** `synapse_impact` evaluates downstream blast radius, identifying affected systems and deduplicating test plans.
- **Code review:** `synapse_review` computes blast-radius risks, identifies blind spots, and surfaces contract warnings for diffs, files, or chunks.
- **Onboarding:** `synapse_onboard` generates an ordered reading plan for a subsystem, grouped by architectural layers with estimated read times.
- **Repo exclude management:** `synapse_update_repo_excludes` updates indexing exclusions with merge-or-replace behaviour.
- **Repo lifecycle management:** `synapse_manage_repos` exposes manual `archive` and `restore` actions, and Synapse automatically archives clean Git worktrees whose branch work has already been merged into the parent checkout. Archived repositories keep their existing graph data searchable but are not restarted, watched, or re-indexed until restored.
- **Status and diagnostics:** `synapse_status` reports watcher/indexer health, unresolved edge counts, query quality warnings, optional profile/vectorisation coverage, and high-traffic chunks needing summaries.
- **Indexer and runtime hardening:** watcher reuse/re-subscribe behaviour is more robust; stale files and orphan noisy chunks are pruned; stale-chunk lazy reindexing is triggered from fast-context access paths.

---

## Behaviour Trace Examples

### Automatic runtime verification (fully automatic)
Set `runtime_verification` to `true` and Synapse will automatically derive observed symbols/events/tests from linked behavioural test artefacts.

```json
{
  "name": "synapse_behaviour_trace",
  "arguments": {
    "repo_id": "alpha",
    "query": "CacheService.resolve/2",
    "max_depth": 6,
    "max_paths": 3,
    "runtime_verification": true
  }
}
```

Response fields to inspect:
- `paths[*].runtime_verification.observation_source` (`automatic_test_trace`, `manual_input`, `manual_and_automatic`, or `none`)
- `paths[*].hops[*].verification.status` (`observed` or `inferred`)
- `runtime_verification.auto_observed_symbol_count`
- `runtime_verification.auto_observed_event_count`

### Optional manual runtime overrides
Manual observation inputs are optional. If provided, they are merged with automatic evidence.

```json
{
  "name": "synapse_behaviour_trace",
  "arguments": {
    "chunk_id": "abc123",
    "runtime_verification": true,
    "observed_symbols": ["CacheService.resolve/2"],
    "observed_events": ["telemetry_execute"],
    "observed_tests": ["apps/core/test/features/cache_service_trace.feature"]
  }
}
```

### Confidence and uncertainty reading
- `confidence` reflects structural continuity, behaviour signals, entrypoint relevance, test linkage, and uncertainty penalties.
- `uncertainty` explicitly flags inferred or weakly-supported path segments.
- Treat low-confidence paths as hypotheses until runtime verification or stronger tests confirm them.

## Semantic Diff Simulation (Shadow Graph)

When an AI agent modifies code, finding out that a change breaks the build usually requires writing the file to disk, running the compiler, and waiting for the test suite. This slows down agent iteration loops significantly.

Synapse solves this with **Semantic Diff Simulation**. By passing `dry_run: true` to `synapse_write_files_safely`, Synapse builds an ephemeral "Shadow Graph" of the proposed AST and compares it against the persisted index in milliseconds.

- **Strict Rejection**: Compilation errors (e.g. arity mismatches, deleted symbols that break existing callers) are caught instantly via graph math and strictly rejected before any file is written.
- **Contract Validation**: Non-fatal structural changes, like removing an emitted event or a state write, return as `contract_warnings`. This allows higher-level orchestrators to evaluate the risk of the change mathematically.
- **Blast Radius Calculation**: Every simulation automatically traces callers to return a numeric `blast_radius`, allowing agents to gauge how broadly a change will impact the rest of the system.

This provides LLMs with a sub-10ms "mathematical proof" of diff safety without executing a single line of code.

## Git Worktree Support & Virtual Worktree Overlay (VWO)

When running parallel sub-agents or tasks, keeping files isolated via separate Git worktrees prevents file conflicts. However, indexing a new directory clone from scratch is slow, heavy, and wasteful.

Synapse-MCP solves this with **Git Worktree Support** and the **Virtual Worktree Overlay (VWO)** system. When registering a repository root via `synapse_manage_repos` (action `"register"`), Synapse automatically detects if the root is a Git worktree.

### Core Behaviour:
1. **Delta Indexing:** Instead of a full workspace scan, Synapse runs `git status --porcelain` and `git diff` against the parent repository's current indexed commit. Only modified, added, or deleted files inside the worktree are indexed/updated, achieving near-instant indexing speed (< 50ms).
2. **Virtual Worktree Overlay (VWO):** When querying a worktree's `repo_id` (via `synapse_get_context` or `synapse_search_codebase`):
   - Chunks from modified or added files inside the worktree overlay take absolute precedence and shadow the parent repository's chunks.
   - Chunks from deleted files inside the worktree overlay are completely suppressed (hidden).
   - Unchanged files fall back seamlessly to the parent repository's indexed chunks.

This allows agents to spawn multiple parallel sub-agents in isolated worktrees while sharing the parent repository's warm cache and pre-built index, with zero overhead.

### Stale worktree lifecycle management

Merged or abandoned worktrees should be archived rather than left active. Archiving is intentionally non-destructive:
- `lifecycle: "active"` means the repository can be watched, booted, and re-indexed.
- `lifecycle: "archived"` means Synapse stops the repository indexer, excludes it from automatic boot/idle/manual re-index scheduling, and keeps its existing graph data searchable for historical lookup.
- `archive` is the right action for stale CORTEX agent worktrees that should not be revived on restart.
- `restore` reactivates a repository and restarts indexing when the worktree is needed again.
- `unregister` remains the destructive removal path and deletes the repository's graph data.
Synapse also performs conservative automatic stale-worktree archiving before boot,
idle, query-start, and manual re-index scheduling. A worktree is auto-archived
only when it is a Git worktree, has a clean working tree, and its HEAD is already
an ancestor of the parent checkout HEAD. Dirty, untracked, unmerged, or
Git-error states remain active.

When Synapse auto-archives a worktree, scoped `list`/status responses include
additive `stale_worktree` fields explaining that the worktree appears stale
because the branch work was merged, plus guidance to restore only when active
indexing is needed again.

Typical manual stale-worktree cleanup flow:

```json
{ "tool": "synapse_manage_repos", "input": { "action": "list" } }
```

Find worktree `repo_id` values whose branches have been merged or whose directories are no longer in active use, then archive each one:

```json
{
  "tool": "synapse_manage_repos",
  "input": { "action": "archive", "repo_id": "CORTEX-agent-example" }
}
```

If a worktree needs to become live again:

```json
{
  "tool": "synapse_manage_repos",
  "input": { "action": "restore", "repo_id": "CORTEX-agent-example" }
}
```

Automatic archive is deliberately conservative. Use manual `archive` for abandoned
worktrees that are not cleanly merge-detectable, and use `restore` when a
previously archived worktree needs active indexing again.

## Code Outliner and JSON SmartCrusher

To conserve context tokens, Synapse-MCP provides two integrated compression features:

### 1. AST-Based Code Outliner
When inspecting code chunks or files via `synapse_inspect_files` (actions `"read_chunk"` and `"read_files"`), you can pass `format: "outline"` in the arguments.
Instead of the full implementation, the outliner strips function and macro bodies down to `...` (or standard comment placeholders like `/* ... */` depending on the language strategy), keeping only function heads, docstrings, and type specs.

Outliner configuration is file-based and loaded from `apps/synapse_core/priv/compressors/`. Currently supported:
- **Elixir** (`elixir.json`): Uses `Sourceror` AST mapping to safely replace `do` blocks.
- **Python** (`python.json`): Uses line indentation tracking to replace function bodies with `pass  # ...`.
- **JavaScript & TypeScript** (`javascript.json`, `typescript.json`): Uses bracket matching to replace function block contents with `/* ... */`.

*Example response content:*
```elixir
def add(a, b) do
  ...
end
```

### 2. JSON SmartCrusher (ON by default)
Compression is **enabled by default** on all tool responses. To opt out (e.g. for debugging), pass `compress_payload: false` in the arguments. The SmartCrusher minifies the returned JSON response:
- **Key mapping:** Converts long verbose keys to shortened codes (e.g., `file_path` $\rightarrow$ `fp`, `chunk_id` $\rightarrow$ `cid`, `raw_source` $\rightarrow$ `src`, `language` $\rightarrow$ `lang`, `symbol` $\rightarrow$ `sym`).
- **Language shortening:** Converts verbose language names to extension-style short names (e.g., `elixir` $\rightarrow$ `ex`, `python` $\rightarrow$ `py`).
- **Pruning:** Automatically strips empty lists (`[]`), empty maps (`{}`), and null/nil fields.
- **Path relativisation:** Resolves absolute workspace paths to relative paths using the registered repository roots.
- **Token savings:** 30-60% fewer response tokens with zero information loss.

This minification runs directly inside the tool `Dispatcher`, meaning both external JSON-RPC clients and embedded native Elixir callers (like Cortex's `SynapseMcpAdapter`) automatically receive optimised, token-dense payloads.

---

## CLI Orchestration (`synapse-cli`)

The `@myelixlabs/synapse-mcp` npm package is the recommended starting point for all users.
It is a zero-dependency Node.js CLI that handles the complete lifecycle: binary download,
device sign-in, service management, OS autostart, IDE configuration, and the local dashboard.

### Quick start

```sh
npx @myelixlabs/synapse-mcp
```

On first run this launches the full interactive wizard:

1. **Downloads the launcher binary** from `downloads.synapse-mcp.dev` for your platform (macOS/Linux/Windows)
2. **Signs you in** via a browser-based device code flow — no API keys needed
3. **Starts the Synapse service** on `http://127.0.0.1:8585/mcp`
4. **Registers OS autostart** (launchd on macOS, systemd user unit on Linux, Task Scheduler on Windows)
5. **Detects and configures your IDEs** (Cursor, Antigravity, Claude, VS Code, Warp, Windsurf)
6. **Opens the management dashboard** at `http://localhost:8686`

On subsequent runs the same command shows a status summary:

```
  Synapse MCP
  Status     ●  running   (PID 34821)
  Endpoint   http://127.0.0.1:8585/mcp
  Indexer    ready
  Repos      5
  Autostart  ✔  launchd (dev.synapse-mcp)
```

### Installation via npm

```sh
npm install -g @myelixlabs/synapse-mcp
```

The `postinstall` script automatically runs `synapse-mcp install --quiet` to pre-download
the launcher binary. Manual install is not required.

### Command reference

| Command | Description |
|---------|-------------|
| `npx @myelixlabs/synapse-mcp` | Smart dispatch: wizard (first run) or status |
| `synapse-mcp install` | Full wizard (always) |
| `synapse-mcp start` | Start the service |
| `synapse-mcp stop` | Stop the service |
| `synapse-mcp restart` | Restart the service |
| `synapse-mcp status` | Rich status output (PID, endpoint, indexer, repos) |
| `synapse-mcp enable` | Register OS autostart |
| `synapse-mcp disable` | Unregister OS autostart |
| `synapse-mcp auth` | Sign in / show account status |
| `synapse-mcp logout` | Remove local credentials |
| `synapse-mcp repos list` | List registered repositories |
| `synapse-mcp repos add --path /…` | Register a repository |
| `synapse-mcp repos archive <id>` | Archive a repository |
| `synapse-mcp repos restore <id>` | Restore an archived repository |
| `synapse-mcp repos remove <id>` | Unregister (destructive, confirms first) |
| `synapse-mcp repos reindex <id>` | Trigger a fresh index pass |
| `synapse-mcp ui` | Start the dashboard server + open browser |
| `synapse-mcp upgrade` | Re-download the launcher binary |
| `synapse-mcp --version` | Print shim version |

### Ports

| Service | Default port | Override |
|---------|-------------|---------|
| Synapse MCP (Elixir SSE/HTTP) | **8585** | `SYNAPSE_PORT` env var |
| Management dashboard (Node.js) | **8686** | `SYNAPSE_DASHBOARD_PORT` env var |

The Synapse service exposes both transport modes on the same port:
- `/mcp` — Streamable HTTP (recommended, default)
- `/sse` — Server-Sent Events (legacy SSE clients)

Configure your IDE with `{ "synapse": { "serverUrl": "http://127.0.0.1:8585/mcp" } }`.

### Authentication

Sign-in uses the OAuth 2.0 device code flow — no passwords or API keys stored locally.

1. CLI prints a URL (`https://synapse-mcp.dev/device`) and a short code (`WXYZ-4821`)
2. You open the URL in a browser and enter the code
3. CLI polls every 3 seconds and saves credentials on success:
   - `~/.config/synapse-mcp/token.jwt` — 7-day Ed25519 JWT (auto-renewed daily)
   - `~/.config/synapse-mcp/credentials.json` — `{ "license_key": "sk_live_..." }` (mode `0600`)

Free tier requires a sign-up with an email. Upgrade to Pro at `https://synapse-mcp.dev/dashboard`.

### OS Autostart

The CLI writes and activates a **user-level** (not system-level) service unit:

| Platform | Mechanism | File |
|----------|-----------|------|
| macOS | launchd | `~/Library/LaunchAgents/dev.synapse-mcp.plist` |
| Linux | systemd user unit | `~/.config/systemd/user/synapse-mcp.service` |
| Windows | Task Scheduler | Task name `SynapseMCP` |

All units restart the service on crash (`KeepAlive`/`Restart=always`) and launch at login
without requiring root or admin privileges.

### Management Dashboard

The dashboard is a local web UI served by the Node.js CLI at `http://localhost:8686`.

Tabs:
- **Overview** — service status, metrics (repos, chunks, cache hit rate, ETS memory), quick-connect snippet
- **Repos** — register/archive/restore/remove repos, per-repo index progress
- **Indexer** — per-repo phase progress (quick_pass, deep_dive_1, deep_dive_2) and health stats
- **Account** — licence info, tier, upgrade CTA → `synapse-mcp.dev/dashboard`
- **Logs** — live SSE log stream from the Synapse service stdout, with filter

The dashboard SPA is shipped pre-built inside the npm package at `lib/ui-dist/`
(vanilla HTML/CSS/JS — no build step required).

### IDE Auto-Detection

The CLI detects and configures MCP servers for the following IDEs automatically:

| IDE | Config file |
|-----|-------------|
| Cursor | `~/.cursor/mcp.json` |
| Antigravity | `~/.antigravity/mcp.json` |
| Claude Code | `~/.claude.json`, `~/.claude/mcp.json`, `./.mcp.json` |
| VS Code | `~/.config/Code/User/mcp.json` (Linux) / `AppData/Code/User/mcp.json` (Windows) |
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |
| Warp | `~/.warp/mcp.json` |
| Codex | `~/.codex/config.toml` (TOML format) |

All JSON-based IDEs receive:
```json
{ "mcpServers": { "synapse": { "serverUrl": "http://127.0.0.1:8585/sse" } } }
```

### Running Synapse — Dev Mode vs Production Mode

Synapse has two launch modes with different purposes but **unified management**.
Regardless of how the server was started, `synapse-mcp status`, `stop`, and `start`
all work the same way.

| | Dev Mode | Production Mode |
|---|---|---|
| **When to use** | Developing Synapse itself | End-users, CI, production |
| **Start command** | `./bin/synapse_mcp --http --replace` | `synapse-mcp start` |
| **Binary** | Source code via Mix (`elixir -S mix run`) | Burrito-packed binary (`~/.synapse-mcp/synapse-mcp`) |
| **Lifecycle** | Foreground, live logs, `q` to quit | Daemon, PID file, detached |
| **Pre-flight** | `mix deps.get` → `mix compile --force` → `mix ecto.migrate` | None (self-contained) |
| **Default port** | `8585` (via `SYNAPSE_PORT`) | `8585` |
| **PID file** | None (detected via port probe) | `~/.synapse-mcp/synapse.pid` |

#### Unified management

The CLI uses **port-based discovery** as a fallback when no PID file exists. This means
all management commands work identically regardless of how the server was started:

```sh
# These work whether the server was started in dev or production mode:
synapse-mcp status    # → detects running server via PID file or port probe
synapse-mcp stop      # → finds PID via file or lsof, sends SIGTERM → SIGKILL
synapse-mcp start     # → checks port first, won't double-spawn
```

Status output adapts to reflect the launch mode:

```
# Dev-mode server (no PID file, detected via port probe):
  Synapse MCP
  Status     ●  running   (external process)
  Endpoint   http://127.0.0.1:8585/mcp

# Production server (managed via PID file):
  Synapse MCP
  Status     ●  running   (PID 34821)
  Endpoint   http://127.0.0.1:8585/mcp
```

#### Dev mode — developing Synapse

Use this when working on the Synapse-MCP codebase itself:

```sh
cd /path/to/SYNAPSE-MCP

# Start the dev server (compiles, migrates, runs in foreground)
./bin/synapse_mcp --http --replace
# → starts on http://127.0.0.1:8585/mcp
# → --replace kills any existing server on the same port first
# → press q + Enter to stop, or Ctrl-C to interrupt
```

The `--replace` flag is important: it finds and kills any existing Synapse process on the
port before starting a fresh one, preventing stale-code issues during development.

#### Production mode — the Burrito binary

The binary is installed at `~/.synapse-mcp/synapse-mcp` after running `synapse-mcp install`
or `npx @myelixlabs/synapse-mcp`. The CLI manages it as a background daemon:

```sh
# Start the binary-managed service
synapse-mcp start
# → spawns ~/.synapse-mcp/synapse-mcp --http --port 8585
# → polls http://127.0.0.1:8585/mcp until ready
# → writes ~/.synapse-mcp/synapse.pid

# Test every command:
synapse-mcp status
synapse-mcp repos list
synapse-mcp repos add --path /path/to/project
synapse-mcp ui          # opens http://localhost:8686
synapse-mcp auth        # device code flow sign-in
synapse-mcp enable      # register OS autostart
synapse-mcp upgrade     # re-download launcher binary

# Stop when done:
synapse-mcp stop
```

---

#### Auth — skip device flow for local testing

The auth device flow hits `https://api.synapse-mcp.dev`. To bypass it and test the CLI
without network auth, create a stub credentials file:

```sh
mkdir -p ~/.config/synapse-mcp

# Minimal credentials stub (bypasses the sign-in step in the wizard)
echo '{"license_key":"sk_dev_local","tier":"pro"}' > ~/.config/synapse-mcp/credentials.json
chmod 600 ~/.config/synapse-mcp/credentials.json

# Fake JWT so the wizard skips the sign-in step entirely
echo 'dev.stub.token' > ~/.config/synapse-mcp/token.jwt
```

---

#### Dashboard UI only (no Elixir server needed)

The dashboard degrades gracefully — service cards show "Unreachable" and metrics show `—`
if the Elixir service is not running. You can inspect and develop the UI without a live server:

```sh
synapse-mcp ui
# → http://localhost:8686 opens immediately
# → serves lib/ui-dist/ (vanilla HTML/CSS/JS, no build step)
```

---

#### BDD tests — no binary, no network, full coverage

```sh
cd /path/to/SYNAPSE-MCP/synapse-cli
npm install

# Standard suite — 95 scenarios, fully stubbed, runs anywhere
npm run test:bdd

# Real macOS launchd integration test (macOS only, calls real launchctl)
npm run test:integration

# View the HTML test report
open test-reports/cucumber-report.html
```

---

#### System diagram: what talks to what

```
Browser (:8686)  →  Express server.js  →  MCP client (:8585)  →  Elixir /api/*
                                        ↘  service.js  (spawn / stop / port probe / pid file)
                                        ↘  service-os.js  (launchd / systemd / schtasks)
                                        ↘  auth.js  (~/.config/synapse-mcp/)
```

The single env var that wires everything together is **`SYNAPSE_PORT`**.
Leave it unset for the default (`8585`), or set it to override.


### Environment variable reference

| Variable | Default | Purpose |
|----------|---------|---------|
| `SYNAPSE_PORT` | `8585` | Synapse service port |
| `SYNAPSE_DASHBOARD_PORT` | `8686` | Dashboard server port |
| `SYNAPSE_MCP_INSTALL_DIR` | `~/.synapse-mcp` | Launcher binary location |
| `XDG_CONFIG_HOME` | `~/.config` | Config/credentials root |
| `SYNAPSE_DATA_DIR` | `~/.synapse-mcp/data` | SQLite database directory |
| `SYNAPSE_DB_PATH` | — | Full path to SQLite file (overrides `SYNAPSE_DATA_DIR`) |

---

## Prerequisites

### Trunk CLI — polyglot lint validation for write-safe operations (optional)


[Trunk](https://trunk.io) is a polyglot linter orchestrator. It wraps existing tools like
`shellcheck`, `prettier`, `markdownlint`, `yamllint`, and more behind a single binary and
configuration file (`.trunk/trunk.yaml`). You define which linters to enable once; Trunk
installs and runs them consistently across every machine and CI environment.

#### What Trunk does in Synapse

`synapse_write_files_safely` and `synapse_sed` use Trunk as a validation gate. Every write
passes through this sequence:

1. **Write** the new content to disk (or apply the sed replacement).
2. **Validate** the modified file(s) by calling `trunk check` against the paths.
3. If Trunk exits clean → **commit** the write and trigger immediate re-indexing.
4. If Trunk reports violations → **rollback**: the file is restored to its original content
   from an in-memory backup. Nothing broken is left on disk.

The agent receives a structured **Diagnostic Map** on failure:

```json
{
  "status": "error",
  "type": "lint_violation",
  "message": "Your edit introduced lint errors. The file has not been saved.",
  "action": "Please correct the logic and retry the write.",
  "details": [
    {
      "file": "bin/my_script",
      "line": "6",
      "column": "6",
      "linter": "shellcheck",
      "message": "SC2086: Double quote to prevent globbing and word splitting"
    }
  ]
}
```

The LLM reads the diagnostic, corrects the content, and retries — completing the loop
without any human intervention or broken state on disk.

#### Why this matters

Without lint validation, an agent can silently commit a shell script that breaks CI, a
YAML file with invalid indentation, or a Markdown document with formatting violations.
With the write-safe layer, those classes of error never land on disk. The rollback is
atomic — it happens in-process before the write is finalised — so there is no partial
state to clean up.

Lint results for repeated content are cached by content hash in ETS, so re-running Trunk
on the same file after a no-op change costs nothing.

#### What linters are enabled

Defined in `.trunk/trunk.yaml`:

| Linter | Coverage |
|---|---|
| `shellcheck` | Shell script correctness |
| `shfmt` | Shell script formatting |
| `prettier` | JS, TS, CSS, HTML, JSON, Markdown |
| `markdownlint` | Markdown structure and style |
| `yamllint` | YAML formatting and structure |
| `checkov` | Infrastructure-as-code security scanning |
| `trufflehog` | Secret / credential leak detection |
| `grype` | Dependency vulnerability scanning |
| `osv-scanner` | Open source vulnerability database |
| `git-diff-check` | Whitespace and conflict markers |

#### Graceful degradation

If `trunk` is not in PATH, Synapse degrades safely:
- Writes proceed unconditionally.
- Responses include `"lint_applied": false`.
- A warning is logged at boot: `trunk not found in PATH. Write-safe linting is disabled. Run bin/install to enable.`

No functionality is lost except the lint gate.

#### Installing Trunk

Run the included install script (idempotent — safe to run repeatedly):

```sh
bash bin/install
```

The script:
1. Checks whether `trunk` is already installed and skips download if so.
2. Installs the Trunk CLI via the official installer.
3. Runs `trunk install` to download the linters defined in `.trunk/trunk.yaml`.

Or install manually:

```sh
curl https://get.trunk.io -fsSL | bash
trunk install
```

Verify:

```sh
trunk --version   # e.g. 1.25.0
```

---

## Free vs Pro Tiers

Synapse-MCP ships in two tiers. The split is enforced at **compile time**, not just at runtime, so the Free binary physically cannot contain Pro bytecodes.

### How the compilation model works

The umbrella has three apps:

| App | Contains | Included in Free binary | Included in Pro binary |
|---|---|---|---|
| `synapse_core` | Graph engine, ETS store, indexer, SQLite | ✅ always | ✅ always |
| `synapse_mcp` | MCP transport, dispatcher, Free tools, Pro stubs | ✅ always | ✅ always |
| `synapse_pro` | Pro tool implementations (ChangeReview, TestQuality, ExploreGraph, CodebaseInsights, KnowledgeCache, DebugTrace) | ❌ excluded | ✅ included |

The Burrito release target in `mix.exs` controls this:

```elixir
releases: [
  synapse_mcp: [
    applications: [
      synapse_mcp: :permanent,
      synapse_core: :permanent
      # synapse_pro is deliberately absent — Free release only
    ],
    ...
  ]
]
```

When `synapse_pro` is absent from the release, every Pro tool name registered in the dispatcher falls through to `SynapseMcp.Tools.ProStubs`, which returns a structured upgrade prompt instead of a result. The Pro bytecode is never assembled into the binary and cannot be reverse-engineered from it.

### Pro tools — how stubs work

When a Free-tier user calls a Pro tool (e.g. `synapse_change_review`), the dispatcher detects that `SynapsePro.*` modules are not loaded and routes to `ProStubs.call/2`. The response is:

```json
{
  "error": "pro_feature",
  "tool": "synapse_change_review",
  "message": "This tool requires Synapse Pro. Upgrade at ...",
  "upgrade_url": "..."
}
```

This happens entirely inside the Free binary — no network call is made.

### Dev environment

In development all three umbrella apps compile together. `synapse_pro` is always available. The dispatcher operates in **Pro mode by default**.

```sh
# Start with full Pro features (default in dev)
bin/synapse_mcp --http

# Force the Free tier locally — Pro tools return upgrade stubs
bin/synapse_mcp --http --free
```

The `--free` flag sets `SYNAPSE_TIER=free` which the dispatcher checks at tool-list build time to exclude Pro tool definitions from the `tools/list` response, even though the Pro modules are compiled and present.

### Test environment

Tests run with all three apps compiled (`MIX_ENV=test` compiles the full umbrella). Pro tools are available by default. To test Free-tier behaviour, set `SYNAPSE_TIER=free` in the test process:

```elixir
# In a BDD step or ExUnit test
System.put_env("SYNAPSE_TIER", "free")
# ...test stub responses...
System.delete_env("SYNAPSE_TIER")
```

The BDD suite `pro_tier_gating.feature` covers this explicitly — it verifies that Pro tool names return upgrade errors in Free mode and full results in Pro mode.

Run the full test suite including tier-gating tests:

```sh
mix test --warnings-as-errors
# or with coverage:
mix test --cover --warnings-as-errors
```

### Production — Free binary

The Free production binary is assembled by Burrito from the `synapse_mcp` release target, which excludes `synapse_pro`. The resulting binary is a self-contained executable for macOS (Intel + ARM), Linux, and Windows.

```sh
# Build the Free binary for all platforms
MIX_ENV=prod mix release synapse_mcp

# Or via Burrito cross-compilation
MIX_ENV=prod mix burrito.build
```

The binary is fully standalone — it embeds the Erlang runtime and has no external dependencies except SQLite (linked at build time). Users run it directly:

```sh
# Start as persistent HTTP server (production recommended)
./synapse_mcp_macos_arm --http

# Start as stdio process (IDE-managed)
./synapse_mcp_macos_arm
```

### Production — Pro binary

The Pro build includes `synapse_pro` in the release applications list. This is handled by the signed bytecode patch distributed to Pro subscribers — the patch is applied to the Free binary and activates the Pro modules without replacing the binary itself.

> [!NOTE]
> Pro activation does not require recompilation. The patch delivers pre-compiled `synapse_pro` BEAM files that are loaded alongside the existing Free binary at startup.

### Environment variable reference

| Variable | Values | Effect |
|---|---|---|
| `SYNAPSE_TIER` | `free` \| `pro` (default) | Forces tier at runtime. In dev, overrides the compiled presence of `synapse_pro`. |
| `SYNAPSE_TRANSPORT` | `streamable-http` \| `sse` \| `stdio` | Selects MCP transport. Set automatically by `--http` / `--sse` flags. |
| `SYNAPSE_PORT` | integer (default `8989`) | HTTP/SSE server port. |

---

## Developer Installation Guide

To develop and run Synapse-MCP, you need the following system dependencies installed:
- **Erlang**: 27.2.4
- **Elixir**: 1.18.2 (OTP 27)
- **SQLite3** (on macOS, you can run `brew install sqlite`)
- A C/C++ compiler (for compiling SQLite NIFs)

We recommend using [asdf](https://asdf-vm.com/) for version management. Once asdf is installed, run:
```sh
asdf plugin add erlang
asdf plugin add elixir
asdf install
```

## Running the Server Locally

### One-time setup
Run this once before starting the server for the first time (installs dependencies and creates the SQLite database):

```sh
cd /path/to/SYNAPSE-MCP
mix deps.get && mix compile && mix ecto.migrate
```

But you can just run the convenience script; `bin/synapse_mcp` handles `mix deps.get`, `mix compile` and `mix ecto.migrate` automatically on every start. 
---

### Mode A — Persistent Streamable HTTP server (recommended remote transport)

Run one server process that all IDEs share. MCP clients connect to the Streamable HTTP endpoint at `http://127.0.0.1:8989/mcp`.
*WARNING* if you make changes to the server and you want to test in your IDE, its best to turn it on and off again after the server restarted and started warming up.

```sh
bin/synapse_mcp --http
```

The equivalent explicit transport form is:

```sh
bin/synapse_mcp --transport streamable-http
```

To freshen the index on restart, you can pass the `--reindex` flag which clears the database and forces a full re-parse of your repositories:

```sh
bin/synapse_mcp --http --reindex
```

The server starts on `http://127.0.0.1:8989`. Keep this terminal open.
The `--http` flag sets `SYNAPSE_TRANSPORT=streamable-http` which picks up the HTTP config from `dev.exs`.

**Why this is better:**
- One process, one index — all IDEs share the same knowledge graph.
- No cold-start delay per IDE connection.
- Restarts are under your control.
- Uses the current MCP Streamable HTTP transport instead of the older endpoint-event SSE flow.

#### Connecting IDEs in Streamable HTTP mode

Use `http://127.0.0.1:8989/mcp` as the remote MCP URL. Client configuration keys vary by IDE, but the transport should be HTTP or Streamable HTTP rather than SSE.

Example MCP client configuration:

```json
{
  "mcpServers": {
    "synapse": {
      "type": "http",
      "url": "http://127.0.0.1:8989/mcp"
    }
  }
}
```

If your client exposes a dedicated Streamable HTTP transport name, prefer it:

```json
{
  "mcpServers": {
    "synapse": {
      "type": "streamable-http",
      "url": "http://127.0.0.1:8989/mcp"
    }
  }
}
```

#### Legacy SSE compatibility

Legacy SSE remains available for clients that have not moved to Streamable HTTP yet. Start the same persistent server with:

```sh
bin/synapse_mcp --sse
```

Legacy clients should continue using `http://127.0.0.1:8989/sse`. This path preserves the older MCP HTTP+SSE endpoint-event model:

```text
GET /sse
event: endpoint
data: http://localhost:8989/message?sessionId=...

POST /message?sessionId=...
```

Example legacy SSE configuration:

```json
{
  "mcpServers": {
    "synapse": {
      "type": "sse",
      "url": "http://127.0.0.1:8989/sse"
    }
  }
}
```

Keep using this only for compatibility. New remote client configuration should target `/mcp`.

---

### Mode B — Per-process stdio (IDE-managed)

Each IDE spawns its own server process over stdin/stdout. This is slightly less efficient (separate index per client) but requires no persistent terminal.
This mode is preserved for local/native process integrations, including products that start Synapse as a child process instead of connecting over remote HTTP.

```sh
bin/synapse_mcp
```

**Claude Desktop** (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "synapse": {
      "command": "/absolute/path/to/SYNAPSE-MCP/bin/synapse_mcp",
      "cwd": "/absolute/path/to/SYNAPSE-MCP"
    }
  }
}
```

**Cursor** (`.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "synapse": {
      "command": "/absolute/path/to/SYNAPSE-MCP/bin/synapse_mcp",
      "cwd": "/absolute/path/to/SYNAPSE-MCP"
    }
  }
}
```

**Windsurf** — MCP settings → add server → type **stdio**:
```
command: /absolute/path/to/SYNAPSE-MCP/bin/synapse_mcp
```

**Warp** (`mcp.json` in project root, copy from `mcp.json.example`):
```json
{
  "synapse": {
    "command": "/absolute/path/to/SYNAPSE-MCP/bin/synapse_mcp",
    "cwd": "/absolute/path/to/SYNAPSE-MCP",
    "env": {
      "ASDF_ERLANG_VERSION": "27.2.4",
      "ASDF_ELIXIR_VERSION": "1.18.2-otp-27"
    }
  }
}
```

> `mcp.json` is gitignored. Copy `mcp.json.example` to `mcp.json` and fill in your absolute path.
> Never configure the MCP client to run `mix compile` or `mix ecto.migrate` on connection.

---

### Verifying connectivity

In any terminal while the server is running (`--http`, `--sse`, or stdio):

```sh
# Inspector (works with stdin/stdout process)
npx @modelcontextprotocol/inspector /absolute/path/to/SYNAPSE-MCP/bin/synapse_mcp

# Quick Streamable HTTP smoke test (when running --http)
curl -sS http://127.0.0.1:8989/mcp \
  -H 'content-type: application/json' \
  -H 'accept: application/json, text/event-stream' \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-03-26",
      "capabilities": {},
      "clientInfo": {"name": "curl", "version": "0.1"}
    }
  }'
```

Expected response:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "protocolVersion": "2025-03-26",
    "capabilities": {
      "tools": {
        "listChanged": false
      }
    },
    "serverInfo": {
      "name": "synapse-mcp",
      "version": "0.1.0"
    }
  }
}
```

For legacy SSE compatibility checks:

```sh
curl -N http://127.0.0.1:8989/sse
```

Manual tool sequence once connected (any IDE):
1. `synapse_indexer_control` with action `"health"` — confirm server is up
2. `synapse_manage_repos` with action `"register"` (using `repo_id` and `root`)
3. `synapse_indexer_control` with action `"status"` — watch indexing progress
4. `synapse_search_codebase` with action `"semantic"` — query the graph


## Runtime repo workflow
The default development config does not register a permanent repo. A typical client workflow is:

1. Call `tools/list` if the agent has not seen the tool catalogue yet.
2. Call `synapse_indexer_control` with action `"health"` to confirm transport health.
3. Workspaces are automatically registered via the MCP handshake (or manually via `synapse_manage_repos` with action `"register"`).
4. **Call `synapse_get_context` with action `"find"` first** to gather a highly dense, multi-dimensional view of the codebase around your task.
5. Call `synapse_explore_graph` with action `"context"` when you already know a specific file, line, symbol, or chunk.
6. Call `synapse_inspect_files` with action `"read_chunk"` before modifying specific implementation details.
7. **Use `synapse_inspect_files` with action `"read_files"` to explore directory structures.** Passing a directory path (e.g., `lib/`) returns its indexed children. **Do not use shell commands like `ls` or `find` to traverse the codebase.**
8. During heavy indexing pressure, use `synapse_search_codebase` with action `"symbol"` / `"regex"` or `synapse_explore_graph` with action `"context"` with `repo_id` and `path` for freshest just-edited files, then return to `synapse_search_codebase` with action `"semantic"` or `synapse_get_context` with action `"find"` for broader semantic synthesis.

## Agentic Deep Search (synapse_get_context)
`synapse_get_context` with action `"find"` is the flagship tool for AI agents. Rather than forcing the agent to burn multiple turns calling `search` → `read` → `callers` → `read`, it does the heavy lifting in parallel:

- Executes massive concurrent **semantic, exact, and fuzzy lookups**.
- Instantly traverses the in-memory knowledge graph to pull **direct callers, callees, and related chunks**.
- Expands thin dispatcher wrappers to reach concrete implementation chunks automatically.
- Ranks results using a **Golden Score** heuristic (semantic relevance + graph centrality + usage signals).
- Returns a single, highly dense, **LLM-friendly Markdown payload** designed to maximize context while minimizing token usage.
- Also returns machine-friendly fields: `structured_results`, `result_buckets`, and `index_health`.

## Staged indexing
Each repo moves through named phases:

- `quick_pass`: file discovery, chunk extraction, tags, symbols, and cheap graph edges
- `deep_dive_1`: the first semantic enrichment pass
- `deep_dive_2`: the later semantic enrichment pass
- `full`: run the complete staged sequence
- `x_repo`: cross-repo link pass — resolves unresolved edges **between** repos

`synapse_index` accepts repo-wide `mode` values:

- `quick_pass`
- `deep_dive_1`
- `deep_dive_2`
- `full`
- `x_repo` *(omit `repo_id` — runs across all registered repos)*

The `x_repo` pass scans every unresolved edge in the graph (`to_chunk_id: null`) and matches `to_symbol` against the global symbol index across all repos. Where an unambiguous match exists, the edge is resolved in-place — callee traversal in `fast_context` then works across repo boundaries automatically. Run it after all repos have completed their `quick_pass`.

Status-aware responses expose:

- `status`
- `current_phase`
- per-phase `completed_files`, `total_files`, and `pending_files`
- `quick_pass_ready`
- `embeddings_partial`
- `discovered_file_count`
- `is_provisional`

When a search or lookup is not explicitly scoped to a repo, Synapse infers repo readiness from the returned chunks and includes either `repo_status` or `repo_statuses`.

## Indexing workflow and trigger map

Understanding *when* and *why* the Indexer runs saves you from confusing repeated quick-pass completions in the logs. Every re-scan flows through `{:prepare_reindex, mode}`. Here is every path that fires one:

### 1. Boot (server start)
On `init/1` the Indexer reads `boot_index_mode` from application config (default `:full` in `dev.exs`, `:quick_pass` or `:full` depending on environment). It schedules `{:prepare_reindex, mode}` within 1 ms via `handle_continue(:full_index)`.

```
init/1
  └── handle_continue(:full_index)
        └── {:prepare_reindex, boot_index_mode}   ← first quick_pass
```

The `boot_index_mode` value determines what happens:
- `:quick_pass` — only structure/symbols/edges are built; **no embeddings**. Fast, queryable within seconds.
- `:full` — runs `quick_pass`, `deep_dive_1`, and `deep_dive_2` all in sequence.

### 2. Boot follow-up (automatic deeper pass after quick_pass)

If `boot_index_mode: :quick_pass` and `boot_followup_mode: :full` (the **dev.exs default**), once the quick_pass drains to `:done`, the Indexer schedules a second full-pass automatically:

```
quick_pass complete
  └── maybe_schedule_boot_followup_reindex/1
        └── {:prepare_reindex, :full}              ← deep follow-up
```

This is why you often see a quick_pass immediately followed by another full scan in dev — it is intentional. The pattern gives instant structural readiness then catches up on embeddings in the background.

Config keys:
```elixir
# config/dev.exs
config :synapse_core,
  boot_index_mode: :quick_pass,
  boot_followup_mode: :full
```

### 3. Idle follow-up (periodic coverage catch-up)

The Indexer fires an `:idle_maintenance_tick` on a configurable interval. When it does, it checks four conditions:
1. The Indexer is idle with no active tasks.
2. Embedding coverage is below `idle_followup_coverage_threshold_percent` (default 95%).
3. At least `idle_followup_cooldown_ms` (default 5 minutes) has elapsed since the last idle follow-up.
4. Embedding coverage has progressed since the last check (stagnation guard).

If all are met:
```
:idle_maintenance_tick
  └── maybe_schedule_idle_followup_reindex/1
        └── {:prepare_reindex, idle_followup_mode}  ← idle catchup
```

By default (`idle_followup_mode: :deep_dive_1`), this runs an embedding pass on already-discovered files without re-triggering a wasteful `quick_pass` structural scan. This is the primary mechanism keeping embeddings topped up in the background on a long-running server — you do not need to trigger it manually.

### 4. Explicit reindex call (`synapse_index` MCP tool / `Indexer.reindex/2`)

An agent or operator calls `synapse_index(repo_id: "...", mode: "full")`:

```
Indexer.reindex(repo_id, mode)
  └── handle_cast({:reindex, mode})
        ├── if tasks in flight  → queued_reindex_mode (fires when pool drains)
        └── if idle             → {:prepare_reindex, mode}
```

### 5. File watcher event (real-time update)

When a file is saved, the `FileSystem` watcher emits `{:file_event, watcher, {path, events}}`. The Indexer debounces these events:

```
:file_event
  └── buffer_file_event/2  (100 ms debounce window)
        └── :flush_file_events
              └── enqueue_manual_work(path, force: true, embed?: true)
                    └── :run_phase_step  (high-priority manual queue)
```

A file-watcher trigger **does not** kick off a new full quick_pass — it only re-indexes the individual changed file through the manual queue. The manual queue always drains before normal phase work resumes.

### 6. `synapse_index` with `path` (targeted reindex)

`Indexer.index_path(repo_id, path)` casts `{:index_path, path, force}` directly into the manual queue — same hot path as file events, same no-full-scan guarantee.

---

### Summary table

| Trigger | Full traversal? | Embeds? | Config key |
|---|---|---|---|
| Boot (`full` mode) | ✅ | ✅ | `boot_index_mode: :full` |
| Boot (`quick_pass` mode) | ✅ | ❌ | `boot_index_mode: :quick_pass` |
| Boot follow-up | ✅ | ✅ | `boot_followup_mode: :full` |
| Idle follow-up | ❌ | ✅ | `idle_followup_mode: :deep_dive_1` |
| `synapse_index` (full) | ✅ | ✅ | — |
| `synapse_index` (quick_pass) | ✅ | ❌ | — |
| File watcher event | ❌ | ✅ | — (per-file only) |
| `synapse_index` with `path` | ❌ | ✅ | — (per-file only) |

> **Why do I see repeated quick_passes?**
> In dev, `boot_index_mode: :quick_pass` + `boot_followup_mode: :full` means every server restart fires:
> 1. A quick_pass (structure only)
> 2. A full deep-dive follow-up (which internally re-scans all files for embeddings)
>
> This is by design — it gives you queryable structure in seconds while embeddings catch up. If you want a single-shot full pass on boot, set `boot_index_mode: :full` and `boot_followup_mode: nil`.

---

## Runtime hardening and safety
- During SQLite warm-up, non-essential tools are gated until ETS is ready; responses include `_synapse` readiness metadata.
- File watcher startup now handles already-started watcher processes and re-subscribes automatically where possible.
- Indexing now prunes stale file rows and orphan noisy chunks to keep graph quality stable over long-lived runs.
- Test/support files are indexed in a lightweight mode and excluded from semantic embeddings by default to reduce noise and cost.
- `synapse_fast_context` performs lazy stale-file checks and can trigger asynchronous reindexing when it detects outdated chunks.
- The indexer pipeline supports dynamic runtime configuration reloads via `GenServer.cast`, allowing external orchestrators to instantly throttle concurrency limits or CPU targets without dropping active queues or restarting the process.

## Persistence and warm start
- SQLite is write-behind only for the hot read path.
- On boot, persisted chunks, edges, and stats are warmed into ETS before normal serving resumes.
- Repo indexing state is persisted so repo readiness survives restarts.



## Test and verification commands

### Elixir/Umbrella Tests
Run from the umbrella root:

```sh path=null start=null
mix test --warnings-as-errors
mix test --cover --warnings-as-errors
mix credo list
```

### CLI/Installer Tests
To run and verify the Node.js CLI auto-configuration and installer suite:

1. Install dependencies:
   ```sh
   cd synapse-cli && npm install
   ```
2. Run Cucumber BDD scenarios:
   ```sh
   npm test
   ```
3. Test the interactive installation wizard locally in development:
   ```sh
   node bin/synapse-mcp.js install
   ```


---

## Continuous Integration (GitLab CI) & Snyk Security Scanning

Snyk security scans are configured as part of the GitLab CI pipeline (`snyk` job in `.gitlab-ci.yml`).

### GitLab CI Setup Requirements

To run Snyk scans, the following custom variables must be configured in GitLab (**Settings > CI/CD > Variables**):
* **`SNYK_TOKEN`**: Your Snyk API token.
* **`SNYK_ORG`**: Your Snyk Organisation ID or slug.

> [!WARNING]
> By default, GitLab variables are marked as **Protected**. If these variables are protected, they will only be injected into pipelines running on protected branches (like `master`). To allow Snyk scans to run on feature branches and merge requests, you must **unprotect** the variables in GitLab settings (uncheck the "Protect variable" option).

### GitLab CI Configuration Notes

1. **Mix Binary Shell Wrapper**: Snyk's internal CLI wrapper completely strips custom shell environment variables (including `HEX_HOME`, `MIX_HOME`, and `MIX_ENV`) when spawning the Elixir parser subprocess (`mix read.mix`). Since this environment stripping is performed by the Snyk Go binary, we dynamically install a shell wrapper script around the `mix` binary in the container's `before_script` phase. This wrapper re-exports the required variables (`HEX_HOME="/root/.hex"`, `MIX_HOME="/root/.mix"`, `MIX_ENV="dev"`) before delegating execution to the real renamed `mix_real` binary, ensuring Snyk successfully resolves private Hex organisation dependencies.
2. **Debug Logging**: The scan is executed with `DEBUG=*snyk*` and the `--debug` flag to capture parser subprocess stack traces in the job logs.
3. **Elixir 1.19+ JSON Module Collision Bypass**: Elixir 1.19.x introduced a built-in `JSON` standard library module and `JSON.Encoder` protocol. Because Snyk's internal Elixir plugin (`snyk-hex-plugin`) bundles its own legacy `JSON` parser module using 1-arity `encode/1` protocol signatures, the BEAM loader defaults to dispatching to the native standard library's 2-arity `encode/2` implementation when executing `mix read.mix`, causing an `UndefinedFunctionError`. To bypass this, the custom `mix` wrapper script intercepts `read.mix` calls, runs a safe regex find-and-replace using `sed` on the extracted temporary Elixir plugin code, and renames all unpatched references from `JSON` to `Snyk.JSON` (using a temporary `__SNYK_JSON__` placeholder to prevent double prefixing).


