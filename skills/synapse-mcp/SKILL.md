---
name: synapse-mcp
description: >
  Use Synapse MCP tools to understand, navigate, edit, and test any codebase
  through a persistent code-knowledge graph. Uses ask_synapse as the default
  entry point, with granular compatibility workflows, token-saving strategies,
  and anti-patterns.
  Use when exploring code, planning edits, reviewing changes, debugging errors,
  or assessing test coverage — instead of grep, file reads, or shell commands.
compatibility: >
  Requires a running Synapse MCP server (SSE or stdio). Works with any
  MCP-capable agent: Cursor, Claude Code, Windsurf, Antigravity, Gemini CLI, etc.
metadata:
  author: myelix labs
  version: "3.7.0"
---

# Synapse MCP — Agent Skill

---

## ⚠️ MANDATORY — Read Before Any Tool Call

> **You MUST call `ask_synapse` before using `grep`, `view_file`, `list_dir`, `find`,
> `rg`, or any shell command for codebase discovery. No exceptions.**
>
> Failing to do this is the single most common and most costly mistake in this codebase.
> Every grep+read cycle wastes 3–5 tool calls and 2,000–5,000 context tokens compared
> to one Synapse call. After enough wasted turns the context window fills and you lose
> the ability to reason about the full task.

### Why agents keep forgetting this

LLMs treat every tool as equally available and default to their training-time
behaviour (grep, view_file). Skills are read once at session start and then
compete with everything else in the context window for attention. This means:

- The longer the conversation, the more likely you are to reach for a shell tool
- High-complexity tasks with many concurrent constraints increase drift probability
- "Just a quick grep" is the canonical first symptom of context-window exhaustion

### The obligation in one sentence

```
synapse first → on no_safe_route: follow next_tool_calls ladder → shell is NEVER permitted
```

### Immediate action table (no routing tree needed)

| If you are about to… | Do this instead |
|---|---|
| `grep -r` / `rg` / `find` a function or pattern | `ask_synapse` with the query |
| `view_file` / `cat` a file to understand it | `synapse_inspect_files` (read_files, format: "outline") |
| `list_dir` / `ls` to explore structure | `synapse_inspect_files` (read_files, path: "dir/") |
| Read imports to guess who calls a function | `synapse_explore_graph` (callers) |
| Ask "can I delete X?" / "is X still used?" | `ask_synapse` with `inputs.chunk_id`, or `repo_id` + arity-qualified `inputs.symbol` → `synapse_codebase_insights` (`dead_code`) |
| Write or edit a file directly | `synapse_modify_files` (write_safely) |
| Ask "what is this codebase?" | `synapse_codebase_insights` (overview) |
| Got `no_safe_route` → reach for grep | **STOP.** Check `did_you_mean.active_repo_ids`, then follow `next_tool_calls` in order |

---



---

## 0. Session Bootstrap — Do This Before Anything Else

**Step 1:** Ask Synapse to handle the objective.

```json
{ "tool": "ask_synapse", "input": { "query": "Describe the codebase task you need to complete", "repo_id": "EXACT_REPO_ID" } }
```

If the `repo_id` is unknown, ask Synapse to list repositories or use this
granular compatibility call:

```json
{ "tool": "synapse_manage_repos", "input": { "action": "list" } }
```

> **Tip — act on `suggested_actions` immediately.** Every `list` row (scoped and unscoped)
> carries a `suggested_actions` array of `{label, tool, args}` objects. Read it, pick the
> appropriate action, and call the tool with the provided `args` directly — no reformatting
> needed. For dirty-merged worktrees, always choose one of: `archive`, `unregister`, or `keep`.

Copy the `repo_id` string from the response **verbatim**. Do not guess it —
it may be a slug like `"numarqe/my-repo"`, not just `"my-repo"`. Use this
exact string in every subsequent call.

**Step 2:** Check indexing readiness when requested (optional — you can also read `repo_status`
from any search response).

```json
{ "tool": "synapse_indexer_control", "input": { "action": "status", "repo_id": "EXACT_REPO_ID" } }
```

### Reading `repo_status` (present in every search/context response)

| Field | What it means | What to do |
|---|---|---|
| `quick_pass_ready: true` | Structure, symbols, edges available | Symbol and regex search work. Graph traversal works. |
| `quick_pass_ready: false` | Still discovering files | Pass `wait_for_ready_ms: 10000` to automatically wait without polling, or wait manually. |
| `embeddings_partial: true` | Embeddings still building | **Do not use `semantic` search or `find`.** Use `symbol` or `regex` instead. |
| `embeddings_partial: false` | All embeddings built | Full tool surface available. |
| `is_provisional: true` | Indexing in progress | Results are partial — narrow scope with `path` parameter. |
| `current_phase` | Active indexing pass | `quick_pass` = structure only; `deep_dive_1/2` = embeddings building. |

---

## 1. Tool Routing — Which Tool for Which Task

Use `ask_synapse` for every ordinary branch below. The granular decision trees
are advanced direct-use and diagnostic references for a known action or a
declared `compatibility_fallback`.

### "I need to understand something"

```
What do you know about the target?
│
├─ Nothing — open-ended question
│  ├─ Embeddings ready?  → synapse_get_context (find)
│  └─ Embeddings partial? → synapse_search_codebase (regex) with descriptive pattern
│
├─ A function/module/class name
│  ├─ Understanding its neighbourhood → synapse_search_codebase (symbol)
│  │  └─ then synapse_explore_graph (context)
│  └─ Deletion safety ("can I delete / is this still used?")
│     └─ ask_synapse with inputs.chunk_id or repo_id + arity-qualified inputs.symbol → synapse_codebase_insights (dead_code)
│
├─ A file path or line number
│  └─ synapse_explore_graph (context, file_path + line)
│
├─ A concept or behaviour ("retry logic", "auth flow")
│  ├─ Embeddings ready?  → synapse_search_codebase (semantic)
│  └─ Embeddings partial? → synapse_search_codebase (regex) or (symbol) with related name
│
├─ A literal string or pattern
│  └─ synapse_search_codebase (regex)
│
└─ New to the codebase entirely
   └─ synapse_codebase_insights (overview)
      └─ then synapse_get_context (onboard) for a specific subsystem
```

### "I need to edit code"

```
1. synapse_get_context (edit, intent: "what you plan to change")
   → callers, callees, must-read files, likely tests, risk assessment
2. synapse_inspect_files (read_chunk) for the target chunk
3. synapse_modify_files (write_safely) — auto-lints, rolls back on failure
4. synapse_change_review (impact) — verify blast radius post-edit
```

### "I need to debug something"

```
Have a stack trace?
├─ Yes → synapse_debug_trace (resolve_stack)
└─ No  → synapse_debug_trace (trace_behaviour, query/symbol)
```

### "I need to review a change"

```
synapse_change_review (review_diff, diff: "...")
→ risk scores, blind spots, contract warnings, test gaps
```

### "I need to find or assess tests"

```
├─ Find tests for a symbol → synapse_test_quality (find_tests, symbol: "...")
├─ Coverage gaps           → synapse_test_quality (coverage)
└─ What to test next       → synapse_test_quality (recommend_test_targets)
```

> **Compression is ON by default.** All Synapse responses are automatically
> minified. Pass `compress_payload: false` to opt out for debugging.

---

## 2. During-Indexing Strategy

When `is_provisional: true` or `embeddings_partial: true`, restrict yourself
to the tools that work from the structural graph (no embeddings needed):

| Works immediately (quick_pass) | Requires embeddings |
|---|---|
| `synapse_search_codebase` (symbol) | `synapse_search_codebase` (semantic) |
| `synapse_search_codebase` (regex) | `synapse_get_context` (find) |
| `synapse_explore_graph` (callers, callees, context) | |
| `synapse_inspect_files` (all actions) | |
| `synapse_codebase_insights` (detect, dead_code, dependencies, overview) | |
| `synapse_test_quality` (coverage, find_tests) | |

**Do not call `semantic` or `find` while embeddings are building.** They will
return zero or poor results, wasting a turn. Use `symbol` + `context` instead —
they are just as effective for targeted queries and work immediately.

---

## 3. Compression & Token Conservation

Synapse has two built-in compression systems. **Use both on every call.**

### 3a. JSON SmartCrusher (ON by default)

**Compression is enabled by default on all Synapse responses.** The SmartCrusher
runs automatically and:

- **Shortens keys**: `file_path` → `fp`, `chunk_id` → `cid`, `raw_source` →
  `src`, `language` → `lang`, `symbol` → `sym`, `start_line` → `sl`
- **Shortens language names**: `elixir` → `ex`, `python` → `py`,
  `javascript` → `js`, `typescript` → `ts`
- **Prunes empties**: strips `[]`, `{}`, `null`, and `nil` fields recursively
- **Relativises paths**: converts `/Users/dev/my-repo/lib/foo.ex` → `lib/foo.ex`

**Typical saving: 30–60% fewer response tokens.** There is zero information
loss — every field is still present, just shorter. The mapping is consistent
across all tools, so once you read one compressed response you can read them all.

> ⚠️ **LINTING / WHITESPACE EXCEPTION — read this before inspecting files:**
> SmartCrusher **strips trailing whitespace** from file content before returning
> it to the agent. This means trailing-whitespace lint violations become
> **invisible** in compressed output — the whitespace is removed before you
> even see the file. Always pass `compress_payload: false` when reading files
> to investigate any linter violation (trailing whitespace, line length,
> indentation, etc.). This applies to **all languages** Synapse supports.

Example — without compression:
```json
{"file_path": "/dev/my-repo/src/main.py", "chunk_id": "abc123", "language": "python", "symbol": "dispatch", "start_line": 45, "summary": null, "tags": []}
```
Default compressed response:
```json
{"fp": "src/main.py", "cid": "abc123", "lang": "py", "sym": "dispatch", "sl": 45}
```

### 3b. AST Outliner (`format: "outline"`)

When reading files to understand structure (not to edit), pass
`format: "outline"` to `synapse_inspect_files` (read_files or read_chunk).
This uses language-aware AST/structure compression to strip function and method
bodies, keeping only:
- Function/method signatures
- Docstrings and module-level documentation
- Type annotations and declarations

**Typical saving: 60–80% fewer tokens per file.**

Full format returns the complete body; outline format returns only the
signature with `...` in place of the body — this works across all 50+
languages Synapse supports.

Supported languages include: Python, JavaScript, TypeScript, Elixir, Ruby,
Go, Rust, Java, C#, C/C++, Swift, Kotlin, and many more.

```json
{ "action": "read_files", "files": [{"path": "lib/"}], "format": "outline" }
```

### 3c. Other Token-Saving Rules

1. **Use `read_chunk` over `read_files`** when you have a `chunk_id`.
   `read_chunk` reads from the in-memory store — instant, no disk I/O.

2. **Use line ranges** when you only need a section of a file:
   ```json
   { "files": [{"path": "lib/my_module.ex", "ranges": ["45-80"]}] }
   ```

3. **Use `synapse_inspect_files` (read_files)** instead of `list_dir` or `ls`.
   Pass a directory path — it returns indexed children with metadata.

4. **Combine with AST outliner**: `format: "outline"` stacks on top of the
   default compression for maximum density when scanning codebases.

5. **To disable compression** — pass `compress_payload: false`:
   - **Always required for linting workflows**: SmartCrusher strips trailing
     whitespace from file content. Without `compress_payload: false`, trailing-
     whitespace violations are invisible. Use it any time you are reading files
     to investigate or fix linter errors, regardless of language.
   - Also useful for general debugging when you need character-exact output.

- **Tip:** To traverse the code graph rapidly, take any `chunk_id` from `outbound_edges` and immediately pass it to `synapse_inspect_files` (action: `read_chunk`). This replaces blind symbol searches and allows instant "go-to-definition" navigation!

---

## 4. Empty Results — Diagnostic Ladder

When a Synapse call returns zero results, **do not immediately fall back to
shell.** Walk this ladder:

```
Zero results returned
│
├─ Step 0: Inspect _synapse.suggested_retry in the response payload
│  └─ If present, execute the recommended retry tool call immediately.
│
├─ Check: Is repo_id correct?
│  └─ Call synapse_manage_repos (list) — confirm the exact repo_id string
│
├─ Check: Is indexing complete?
│  └─ Read repo_status in the response
│     ├─ quick_pass_ready: false → Indexing hasn't finished basic pass. Wait.
│     ├─ embeddings_partial: true AND you used semantic/find
│     │  └─ Switch to symbol or regex — embeddings aren't ready yet
│     └─ Both ready → Indexing is complete, the query itself is the problem
│
├─ Check: Did you pass natural language into symbol search?
│  └─ Switch to synapse_get_context (action: "find") or search_codebase (action: "regex")
│
├─ Check: Is the file excluded from indexing?
│  └─ Call synapse_manage_repos (list) — check exclude patterns
│     └─ Update excludes if needed: synapse_manage_repos (update_excludes)
│
└─ All checks pass, still zero results
   └─ NOW fall back to shell grep or native file reads
      └─ But still prefer synapse_inspect_files (read_files) over view_file
```

---

## 5. Anti-Patterns — Suppress These Defaults

| ❌ Default instinct | ✅ Synapse equivalent | Why |
|---|---|---|
| `grep -r "func_name"` | `synapse_search_codebase` (symbol or regex) | Returns chunk_ids, line numbers, tags — not raw text |
| `view_file` / read an entire file | `synapse_search_codebase` (symbol) → `read_chunk` | Read only the chunk you need, not 500 lines |
| `list_dir` to explore structure | `synapse_inspect_files` (read_files, path: "dir/") | Returns indexed children with metadata |
| Read imports to guess callers | `synapse_explore_graph` (callers) | Graph-exact, transitive, with depth control |
| Answer "is X still used?" by manually scanning callers | `ask_synapse` → `synapse_codebase_insights` (`dead_code`) with `chunk_id` or `repo_id` + arity-qualified symbol | Splits production/test callers and returns function-level scope, unsupported clause-level status, deletion risk, confidence, and caveats |
| `grep -r "test" test/` for tests | `synapse_test_quality` (find_tests) | Confidence-ranked, includes features + step defs |
| Read README for architecture | `synapse_codebase_insights` (overview) | Built from indexed source, not potentially-stale docs |
| Write with native file tools | `synapse_modify_files` (write_safely) | Lint validation + atomic rollback on failure |
| Edit without checking impact | `synapse_get_context` (edit) first | Returns callers, tests, risk assessment |
| Multiple grep+read cycles | Single `synapse_get_context` (find) | Parallel semantic + exact + fuzzy + graph traversal |

---

## 6. Knowledge Accumulation — Make Synapse Smarter Over Time

Synapse's graph is persistent and accumulative. Invest in it:

1. **Automatic Query Learning (Implicit):** Synapse automatically correlates 0-result search attempts with subsequent chunk reads within the same session, learning query associations without manual effort.

2. **Explicit Learning (Pro Mode):** After a useful result, call `synapse_knowledge_cache` (learn) with the query and chunk_id to record explicit relevance. A single signal is queryable immediately as provisional evidence; promotion requires repeated evidence.

3. **After understanding a chunk:** call `synapse_knowledge_cache` (save_summary) with a plain-English description, including evidence and confidence when recording generated-to-source provenance. Future queries can retrieve it by summary text, filename, symbol, or chunk ID.

4. **Before fallback search:** call `synapse_knowledge_cache` (query) with the diagnostic text, filename, symbol, or chunk ID to check cached summaries and exact learned associations.

5. **Periodically:** call `synapse_knowledge_cache` (suggest) to find high-traffic chunks that lack summaries — documenting these improves all future sessions.

---

## 7. Default Façade and Granular Compatibility Tools at a Glance

| Tool | Actions | When to use |
|---|---|---|
| `ask_synapse` | *(none)* | Default natural-language entry point; inspect `completion_state` and safe `next_tool_calls` |
| `synapse_manage_repos` | list, register, archive, restore, keep, unregister, update_excludes | Session start, adding/removing repos, managing stale/dirty-merged worktree lifecycle |
| `synapse_indexer_control` | health, status, trigger | Health checks, re-indexing |
| `synapse_search_codebase` | semantic, symbol, regex | Finding code by meaning, name, or pattern |
| `synapse_explore_graph` | callers, callees, context | Navigating relationships around a chunk |
| `synapse_get_context` | find, edit, explain, onboard | Advanced direct context gathering and compatibility fallback |
| `synapse_inspect_files` | read_files, read_chunk, count_lines | Reading source, listing directories |
| `synapse_modify_files` | write_safely, find_and_replace, delete_chunk | Editing code with safety guarantees |
| `synapse_change_review` | analyse_diff, review_diff, impact | Reviewing changes and blast radius |
| `synapse_codebase_insights` | detect, public_api, dead_code, contracts, dependencies, overview, refactor_opportunities | Codebase-level analysis and function-level deletion safety by `chunk_id` or arity-qualified symbol |
| `synapse_test_quality` | coverage, find_tests, setup_trunk, recommend_test_targets | Test discovery and coverage |
| `synapse_debug_trace` | trace_behaviour, resolve_stack | Debugging and execution tracing |
| `synapse_knowledge_cache` | learn, save_summary, suggest | Persistent knowledge management |
| `synapse_capability_manifest` | *(none)* | Self-documenting tool surface |

---

| `synapse_knowledge_cache` | learn, save_summary, query, suggest | Persistent knowledge management with provisional learned associations and summary/identifier lookup |

Use shell or native file tools **only** when:

1. You have walked the diagnostic ladder (Section 4) and confirmed Synapse cannot help
2. The task is non-codebase: `git commit`, `mix test`, `npm run`, environment setup
3. You need to execute code (Synapse indexes — it does not run anything)
4. You need binary files that Synapse does not index (images, compiled assets)

Even for file reads in fallback mode, prefer `synapse_inspect_files` (read_files)
— it adds line numbers, byte counts, and chunk metadata automatically.

---

## ⚠️ REMINDER (Recency Anchor)

If you have reached this point in the skill without having called `ask_synapse`,
you are already off-track. The rule has not changed:

```
synapse first → shell only if synapse explicitly returns zero safe routes
```

Every `grep`, `view_file`, `list_dir`, or `find` that precedes an `ask_synapse`
call is a violation of this skill. Go back and call `ask_synapse` now.
