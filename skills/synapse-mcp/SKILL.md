---
name: synapse-mcp
description: >
  Use this skill whenever navigating, exploring, reading, editing, debugging, or reviewing code in any repository managed by Synapse MCP, instead of using grep, find, ls, view_file, or shell commands. Use when asked to locate functions or symbols, trace callers and callees, inspect dependencies, verify test coverage, perform atomic lint-validated code edits, or assess the blast radius and safety of proposed code changes.
compatibility: >
  Requires a running Synapse MCP server (SSE or stdio transport). Compatible with any Agent Skills compliant runtime: Cursor, Claude Code, Windsurf, Antigravity, Gemini CLI, etc.
metadata:
  author: myelix labs
---

# Synapse MCP

Use Synapse MCP tools to understand, navigate, edit, and test any codebase through a persistent code-knowledge graph.

---

## ⚠️ Mandatory Pre-Tool Protocol

**You MUST call `ask_synapse` before using `grep`, `view_file`, `list_dir`, `find`, `rg`, or any shell command for codebase discovery. No exceptions.**

```
synapse first → on no_safe_route: follow next_tool_calls ladder → shell is NEVER permitted
```

### Immediate Action Table

| If you are about to… | Do this instead |
|---|---|
| `grep -r` / `rg` / `find` a function or pattern | `ask_synapse` with the query |
| `view_file` / `cat` a file to understand it | `synapse_inspect_files` (`read_files`, `format: "outline"`) |
| `list_dir` / `ls` to explore structure | `synapse_inspect_files` (`read_files`, `path: "dir/"`) |
| Read imports to guess who calls a function | `synapse_explore_graph` (`callers`) |
| Ask "can I delete X?" / "is X still used?" | `ask_synapse` with `inputs.chunk_id`, or `repo_id` + arity-qualified `inputs.symbol` → `synapse_codebase_insights` (`dead_code`) |
| Write or edit a file directly | `synapse_modify_files` (`write_safely`) |
| Ask "what is this codebase?" | `synapse_codebase_insights` (`overview`) |
| Got `no_safe_route` → reach for grep | **STOP.** Check `did_you_mean.active_repo_ids`, then follow `next_tool_calls` in order |

---

## 0. Session Bootstrap

**Step 1:** Initialise the task with `ask_synapse`. If the repository identifier is unknown, list registered repositories first:

```json
{ "tool": "ask_synapse", "input": { "query": "Task description", "repo_id": "EXACT_REPO_ID" } }
```

```json
{ "tool": "synapse_manage_repos", "input": { "action": "list" } }
```

> **Note:** Copy the `repo_id` string from `list` output **verbatim** (e.g. `"synapse-mcp"`). Every row in `list` provides a `suggested_actions` array containing ready-to-execute `{tool, args}` objects.

**Step 2:** Check indexing readiness when required:

```json
{ "tool": "synapse_indexer_control", "input": { "action": "status", "repo_id": "EXACT_REPO_ID" } }
```

### `repo_status` Readiness Flags

| Field | Meaning | Required Action |
|---|---|---|
| `quick_pass_ready: true` | Symbols, structure, and graph edges ready | Symbol search, regex search, and graph exploration are fully operational. |
| `quick_pass_ready: false` | Initial file discovery in progress | Pass `wait_for_ready_ms: 10000` to wait automatically, or re-check status. |
| `embeddings_partial: true` | Embeddings still computing | **Do not use `semantic` search or `find`.** Use `symbol` or `regex` search. |
| `embeddings_partial: false` | All embeddings generated | Full search and retrieval surface available. |
| `is_provisional: true` | Indexing pass active | Scope queries tightly using the `path` filter. |

---

## 1. Tool Routing

Use `ask_synapse` for all high-level tasks. Use granular tools for known targets or diagnostic fallbacks.

### Code Understanding
```
What do you know about the target?
│
├─ Nothing / Open question
│  ├─ Embeddings ready?   → synapse_get_context (find)
│  └─ Embeddings partial? → synapse_search_codebase (regex)
│
├─ Symbol / Function / Module name
│  ├─ Neighbourhood & context → synapse_search_codebase (symbol) → synapse_explore_graph (context)
│  └─ Deletion safety         → ask_synapse with chunk_id / symbol → synapse_codebase_insights (dead_code)
│
├─ File path & line number
│  └─ synapse_explore_graph (context, file_path + line)
│
├─ Concept / Pattern ("retry logic", "auth")
│  ├─ Embeddings ready?   → synapse_search_codebase (semantic)
│  └─ Embeddings partial? → synapse_search_codebase (regex / symbol)
│
└─ Whole codebase onboarding
   └─ synapse_codebase_insights (overview) → synapse_get_context (onboard)
```

### Code Modification
```
1. synapse_get_context (edit, intent: "...") → callers, tests, risk
2. synapse_inspect_files (read_chunk, chunk_id: "...")
3. synapse_modify_files (write_safely, dry_run: true) → review preview
4. synapse_modify_files (write_safely, dry_run: false) → atomic lint & commit
5. synapse_change_review (impact) → blast radius verification
```

### Debugging & Test Mapping
```
├─ Stack trace available? → synapse_debug_trace (resolve_stack, stack_trace: "...")
├─ Dynamic behaviour?     → synapse_debug_trace (trace_behaviour, query/symbol: "...")
├─ Review code diff?      → synapse_change_review (review_diff, diff: "...")
└─ Test mapping/coverage  → synapse_test_quality (find_tests | coverage | recommend_test_targets)
```

---

## 2. Safe Modes During Indexing

When `is_provisional: true` or `embeddings_partial: true`, use only structural tools that do not require vector embeddings:

| Works immediately (`quick_pass`) | Requires embeddings |
|---|---|
| `synapse_search_codebase` (`symbol`, `regex`) | `synapse_search_codebase` (`semantic`) |
| `synapse_explore_graph` (`callers`, `callees`, `context`, `cycles`) | `synapse_get_context` (`find`) |
| `synapse_inspect_files` (all actions) | |
| `synapse_codebase_insights` (`detect`, `dead_code`, `dependencies`, `overview`, `public_api`, `contracts`) | |
| `synapse_test_quality` (`coverage`, `find_tests`, `recommend_test_targets`) | |
| `synapse_debug_trace` (`trace_behaviour`, `resolve_stack`) | |
| `synapse_change_review` (`analyse_diff`, `review_diff`, `impact`) | |
| `synapse_modify_files` (`write_safely`, `find_and_replace`) | |

---

## 3. Compression & Token Conservation

1. **SmartCrusher (Default: ON):** Minifies JSON keys (`file_path`→`fp`, `chunk_id`→`cid`, `symbol`→`sym`, `start_line`→`sl`) and prunes empty fields recursively.
2. **AST Outliner:** Pass `format: "outline"` to `synapse_inspect_files` (`read_files` or `read_chunk`) to strip method bodies and view signatures only.
3. **In-Memory Reads:** Prefer `synapse_inspect_files` (`read_chunk`) over disk reads when a `chunk_id` is available.
4. **⚠️ CRITICAL LINTING OVERRIDE:** Pass `compress_payload: false` whenever inspecting files for linter, line-length, or whitespace violations. SmartCrusher strips trailing whitespace by default, rendering trailing-whitespace violations invisible.

---

## 4. Diagnostic Ladder for Empty Results

When a Synapse call returns zero results, **do not fall back to shell.** Walk this ladder:

```
Zero results returned
│
├─ 1. Check `_synapse.suggested_retry` in payload → execute immediately
├─ 2. Confirm `repo_id` with `synapse_manage_repos` (list)
├─ 3. Check `repo_status`:
│     ├─ quick_pass_ready: false → wait for initial pass
│     └─ embeddings_partial: true → switch from semantic/find to symbol/regex
├─ 4. Query syntax: natural language was passed into symbol search → switch to regex/find
├─ 5. Check excludes: run synapse_manage_repos (update_excludes) if file was ignored
└─ 6. All checks exhausted → only now fallback to synapse_inspect_files (read_files)
```

---

## 5. Anti-Patterns — Suppress These Defaults

| ❌ Default Instinct | ✅ Synapse Equivalent | Why |
|---|---|---|
| `grep -r "name"` | `synapse_search_codebase` (`symbol` / `regex`) | Returns structured chunk IDs, line numbers, and semantic tags |
| `view_file` whole file | `synapse_search_codebase` → `read_chunk` | Reads exact chunk from memory; eliminates context bloat |
| `list_dir` / `ls` | `synapse_inspect_files` (`read_files`, `path: "dir/"`) | Returns indexed children with metadata and byte counts |
| Scan imports for callers | `synapse_explore_graph` (`callers`, `depth: 2`) | Exact, transitive, depth-controlled graph traversal |
| Manual dead-code checks | `ask_synapse` → `synapse_codebase_insights` (`dead_code`) | Evaluates production vs test callers with deletion safety guidance |
| Grep tests | `synapse_test_quality` (`find_tests`) | Confidence-ranked, maps features + step definitions |
| Edit with raw tools | `synapse_modify_files` (`write_safely`) | Atomic commit + automatic Trunk lint validation and rollback |
| Edit without checking impact | `synapse_get_context` (`edit`) first | Returns callers, tests, risk assessment, and contract warnings |
| Multiple grep+read cycles | Single `synapse_get_context` (`find`) | Parallel semantic + exact + fuzzy + graph retrieval |

---

## 6. Knowledge Accumulation

1. **Implicit learning:** Synapse automatically correlates zero-result searches with subsequent chunk reads in the same session.
2. **Explicit learning:** Call `synapse_knowledge_cache` (`learn`) with `query` and `chunk_id` after a useful finding.
3. **Chunk annotation:** Call `synapse_knowledge_cache` (`save_summary`) with a markdown summary after understanding a complex chunk.
4. **Pre-fallback check:** Call `synapse_knowledge_cache` (`query`) before falling back to check existing summaries and learned associations.
5. **Hygiene:** Call `synapse_knowledge_cache` (`suggest`) to surface undocumented high-traffic chunks.

---

## 7. Tool Reference

All 14 tools and 33 actions verified against the live Synapse MCP server manifest:

| Tool | Actions | When & How to Use |
|---|---|---|
| `ask_synapse` | *(none)* | **Default conversational entry point.** Natural-language routing across all capabilities with safety, readiness, and mutation gates. Pass `query` and `repo_id`. |
| `synapse_manage_repos` | `list`<br>`register`<br>`archive`<br>`restore`<br>`keep`<br>`unregister`<br>`update_excludes` | **Repository & worktree management.**<br>• `list`: list registered repositories and execute `suggested_actions`<br>• `register`: register repository root (auto-detects Git worktrees)<br>• `archive` / `restore`: pause/resume indexing while keeping graph searchable<br>• `keep`: dismiss dirty-merged worktree advisory for current session<br>• `unregister`: permanently purge repository from registry and store<br>• `update_excludes`: update indexed path exclusions |
| `synapse_indexer_control` | `health`<br>`status`<br>`trigger` | **Indexing pipeline control.**<br>• `health`: quick server and transport health check<br>• `status`: per-repository phase progress, chunk counts, and embedding status<br>• `trigger`: trigger re-index for repository, directory, or file |
| `synapse_search_codebase` | `semantic`<br>`symbol`<br>`regex` | **Code search modes.**<br>• `semantic`: natural-language embedding similarity (`embeddings_partial: false`)<br>• `symbol`: exact/fuzzy symbol index lookup for functions, modules, classes<br>• `regex`: PCRE line-matching grep (`match_per_line: true` returns lines and line numbers) |
| `synapse_explore_graph` | `callers`<br>`callees`<br>`context`<br>`cycles` | **Structural dependency navigation.** Accepts `chunk_id`, or `repo_id` + `symbol` / `file_path`.<br>• `callers`: upstream references with transitive depth (1–3)<br>• `callees`: downstream dependencies with transitive depth (1–3)<br>• `context`: neighbourhood graph (callers, callees, related chunks)<br>• `cycles`: circular dependency detection reachable from target |
| `synapse_get_context` | `find`<br>`edit`<br>`explain`<br>`onboard` | **Multi-dimensional context retrieval.**<br>• `find`: hybrid search returning markdown golden paths or structured metadata<br>• `edit`: pre-edit safety pack (callers, callees, related tests, risk level)<br>• `explain`: layered functional explanation of a chunk<br>• `onboard`: reading order and learning path for a subsystem |
| `synapse_inspect_files` | `read_files`<br>`read_chunk`<br>`count_lines` | **Source inspection.**<br>• `read_files`: file/directory disk read with line numbers; supports `ranges` and `format: "outline"`<br>• `read_chunk`: instant raw source read from in-memory store by `chunk_id`<br>• `count_lines`: workspace line count with optional path filter |
| `synapse_modify_files` | `write_safely`<br>`find_and_replace`<br>`delete_chunk` | **Atomic file modifications.**<br>• `write_safely`: atomic writes with Trunk lint validation, dry-run simulation, and rollback<br>• `find_and_replace`: global regex replacement across indexed files<br>• `delete_chunk`: deletes a specific chunk from the index |
| `synapse_change_review` | `analyse_diff`<br>`review_diff`<br>`impact` | **Diff and change review.**<br>• `analyse_diff`: rapid orientation of a change set (modified symbols, tests to run)<br>• `review_diff`: detailed safety and risk review highlighting blind spots and broken contracts<br>• `impact`: calculates blast radius and downstream callers |
| `synapse_codebase_insights` | `detect`<br>`public_api`<br>`dead_code`<br>`contracts`<br>`dependencies`<br>`overview`<br>`refactor_opportunities` | **Architectural analysis & deletion safety.**<br>• `detect`: language and framework percentage breakdown<br>• `public_api`: public modules, functions, and external caller counts<br>• `dead_code`: function-level deletion safety check by `chunk_id` or arity-qualified `symbol` (e.g. `Module.fun/1`)<br>• `contracts`: boundary scanning (HTTP, JSON, CLI schemas)<br>• `dependencies`: inter-module dependency graph<br>• `overview`: repository-wide architecture and health summary<br>• `refactor_opportunities`: code quality improvement targets |
| `synapse_test_quality` | `coverage`<br>`find_tests`<br>`setup_trunk`<br>`recommend_test_targets` | **Testing and code quality.**<br>• `coverage`: static association bands between production code and tests<br>• `find_tests`: maps symbols or queries to test files, features, and step definitions<br>• `setup_trunk`: configures Trunk linter for repository<br>• `recommend_test_targets`: ranks uncovered modules and recommends test priorities |
| `synapse_debug_trace` | `trace_behaviour`<br>`resolve_stack` | **Debugging and execution flow.**<br>• `trace_behaviour`: traces branches, side effects, and state access without running code<br>• `resolve_stack`: maps crash stack traces to indexed code chunks and relevant tests |
| `synapse_knowledge_cache` | `learn`<br>`save_summary`<br>`suggest`<br>`query` | **Persistent knowledge store.**<br>• `learn`: reinforces query-to-chunk relevance signals<br>• `save_summary`: permanently annotates chunks with plain-English summaries<br>• `suggest`: surfaces high-traffic chunks needing documentation<br>• `query`: retrieves cached summaries and learned associations before fallback searches |
| `synapse_capability_manifest` | *(none)* | **Self-documenting tool introspection.** Returns active tool definitions, schemas, capability groups, mutation targets, and tool relationships. |

---

## 8. Non-Synapse Fallback Policy

Shell and native file tools (`grep`, `rg`, `view_file`, `list_dir`, `find`) are **strictly prohibited** unless all of the following conditions are met:

1. `ask_synapse` explicitly returned `no_safe_route`.
2. The diagnostic ladder (Section 4) has been exhausted without results.
3. The task is non-codebase execution: `mix test`, `git commit`, `npm run`, or binary asset handling.

---

## ⚠️ Recency Anchor

**Synapse first. Shell search (`grep`, `rg`, `find`, `ls`, raw reads) is strictly prohibited unless `ask_synapse` explicitly reports zero safe routes and the diagnostic ladder is exhausted.**
