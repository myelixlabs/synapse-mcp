<div align="center">

<svg width="72" height="64" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="20" cy="20" r="3" fill="#2ef2ff"/><circle cx="12" cy="32" r="2.5" fill="#a45cff"/>
  <circle cx="24" cy="44" r="3" fill="#2ef2ff"/><circle cx="28" cy="30" r="2" fill="#2ef2ff"/>
  <circle cx="44" cy="20" r="3" fill="#2ef2ff"/><circle cx="52" cy="32" r="2.5" fill="#a45cff"/>
  <circle cx="40" cy="44" r="3" fill="#2ef2ff"/><circle cx="36" cy="30" r="2" fill="#2ef2ff"/>
  <path d="M20 20 L28 30 L12 32 Z" stroke="#2ef2ff" stroke-width="1.5" stroke-dasharray="2 2" opacity="0.6"/>
  <path d="M12 32 L24 44 L28 30 Z" stroke="#a45cff" stroke-width="1.5" opacity="0.5"/>
  <path d="M44 20 L36 30 L52 32 Z" stroke="#2ef2ff" stroke-width="1.5" stroke-dasharray="2 2" opacity="0.6"/>
  <path d="M52 32 L40 44 L36 30 Z" stroke="#a45cff" stroke-width="1.5" opacity="0.5"/>
  <path d="M28 30 L36 30" stroke="#fff" stroke-width="2" opacity="0.8"/>
</svg>

# Synapse MCP Server

**Your structural brain for your coding AI agents.**

[![Free](https://img.shields.io/badge/Free-forever-22c55e?style=flat-square)](https://synapse-mcp.dev)
[![Pro](https://img.shields.io/badge/Pro-%2419%2Fmo-2ef2ff?style=flat-square)](https://synapse-mcp.dev/pro)
[![MCP Compatible](https://img.shields.io/badge/MCP-compatible-a45cff?style=flat-square)](https://modelcontextprotocol.io)
[![Languages](https://img.shields.io/badge/Languages-50%2B-white?style=flat-square)](https://synapse-mcp.dev/languages)
[![100% Local](https://img.shields.io/badge/100%25%20Local-No%20cloud-ff6b6b?style=flat-square)](#local-first-always)
[![Zero Data Egress](https://img.shields.io/badge/Zero%20Data%20Egress-Privacy%20first-f5c542?style=flat-square)](#local-first-always)

</div>

---

Synapse MCP is a **free, 100% local MCP server** that converts your codebase into a persistent, on-device AST knowledge graph. Claude, Cursor, Copilot, and every MCP-compatible agent gets exact caller trees, semantic search, and zero-hallucination refactoring — at **60% lower token spend** than shell tools. **Your code never leaves your machine.**

```sh
# Linux / macOS
curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh

# Windows PowerShell
irm https://downloads.synapse-mcp.dev/install.ps1 | iex
```

---

## What is Synapse MCP?

If you've used AI coding assistants — Claude, Copilot, Cursor, Devin — you've probably noticed they spend a lot of time *finding* code before they can *change* it. They grep files, read imports, search for function names, open file after file. That exploration is expensive: it burns tokens, takes time, and the agent still sometimes gets it wrong.

**Synapse MCP is the fix for that.**

It is an **MCP server** — a background process that connects to your AI agent and gives it a new set of tools. Instead of a file system and a search box, Synapse gives your agent a **pre-built knowledge graph of your entire codebase**: every function, every class, every call relationship, every module boundary — indexed, structured, and ready to query in milliseconds.

### In plain terms

Think of the difference between a new employee on their first day versus a senior engineer who has worked in the codebase for years.

The new employee opens files, searches for things, asks questions, gets confused by unfamiliar names. Every task starts with exploration.

The senior engineer already knows where everything is. They go straight to the right file, understand the downstream effects of a change before touching it, and know which tests to run. They don't explore — they act.

**Synapse turns your AI agent into the senior engineer.** The knowledge graph is built once, updated automatically as your code changes, and queried instantly on every agent request — all without any code leaving your machine.

### Why should I use it?

| Without Synapse | With Synapse |
|---|---|
| Agent greps files, reads imports, opens 10 files to find one function | One tool call returns the exact chunk, its callers, and its tests |
| Every session starts from zero | Graph persists and improves across sessions |
| Agent writes a file, lint fails, file is broken | `write_safely` validates first, rolls back on failure |
| You paste a stack trace and hope | `resolve_stack` maps it directly to your AST and suggests a fix |
| Code review is manual | `review_diff` ranks blast radius and broken contracts before you push |
| Code sent to a cloud service to build an index | Everything runs locally — zero data egress |

You don't change how your agent works. You don't change your workflow. You install Synapse, register your repo, and your agent gets smarter immediately.

---

## Local First. Always.

> 🔒 **Your code never leaves your machine.** Synapse runs entirely on your hardware — no cloud indexing, no API calls with your source, no telemetry, no vendor lock-in.

Most code intelligence tools send your code to a cloud service to build their index. Synapse does not. The full AST graph — every function, every edge, every embedding — is built and stored locally in a persistent on-device store. When the graph is ready, your agents query it directly over MCP. Nothing goes out.

This matters for:
- **Enterprise & regulated environments** — source code stays inside your perimeter
- **Open source contributors** — your unreleased work stays unreleased
- **Anyone who values speed** — local graph queries have sub-millisecond latency. No network round-trip, ever.

---

## Why Synapse?

Standard agents grep text. Synapse serves **compressed structural slices** from a pre-built AST graph — callers, callees, coverage gaps, contracts, and summaries — in a single MCP call.

> *"Four tool calls. Zero file reads. Zero grepping. With Synapse the agent spends tokens on the actual task — not on exploration."*
> — from the Synapse benchmark report

### Benchmark — Autonomous Security Audit · 500k LOC Codebase · Same Frontier Model

| Metric | Synapse vs. shell tools |
|---|---|
| Tokens & Cost | **−60%** |
| Speed | **2.2× faster** |
| Tool calls | **−47%** |
| Accuracy | **100% — identical** |
| Data sent to cloud | **0 bytes** |

*Fewer tool calls + no network latency = dramatically faster agent loops.*

---

## Features at a Glance

| Feature | Description |
|---|---|
| 🔒 **100% Local & Private** | The graph is built and stored on your machine. Zero cloud dependencies, zero data egress, zero network latency on queries |
| ⚡ **Sub-millisecond Graph Queries** | Local in-memory store means responses are instant — no API round-trips eating into your agent's budget |
| 🚀 **SmartCrusher Compression** | Responses auto-minified 30–60%: short keys, stripped nulls, relativised paths. Outline mode strips bodies — scan 20+ files at a fraction of the token cost |
| **Three Search Modes** | Semantic (plain English), symbol lookup, and full PCRE regex — all returning structured chunk IDs, not raw file dumps |
| **Transitive Caller Graph** | Know every direct and transitive caller of any function before touching a line of code. Configurable depth, confidence scores, edge labels |
| **Safe Atomic Writes** | Simulate edits in memory, map the blast radius, write atomically, and auto-rollback on lint failure. Your file is never left broken |
| **Instant Crash Resolution** | Paste a stack trace, get root-cause analysis mapped to your AST graph — with reproducing test suggestions. No runtime needed |
| **Change Review & Impact** | Feed a diff or commit range. Get ranked blast radius, broken contracts, tests to run, and blind spots — before you push |
| **Persistent Agent Memory** | Summaries written in one session survive to the next. The more you use Synapse, the smarter your codebase model becomes |
| **Test Intelligence** | Coverage bands, test mapping, and ranked test targets — derived from the graph without executing your test suite |
| **Codebase X-Ray** | Language detection, public API surface, dead-code deletion safety, inter-module dependency graph, contract scanning, and refactor opportunities in one call |

---

## Language Support

50+ languages. One graph. Supports 100s of repos. AST-aware chunking and dependency edge extraction for every mainstream language — no plugins, no configuration, no cloud.

`Elixir` `Python` `TypeScript` `JavaScript` `Go` `Rust` `OCaml` `Haskell` `F#` `Clojure` `Scala` `Java` `Kotlin` `Swift` `C` `C++` `C#` `Ruby` `PHP` `Dart` `Zig` `Erlang` `Julia` `Groovy` `Solidity` `GraphQL` `HCL / Terraform` `Protobuf` `SQL` `Shell` `PowerShell` `Lua` `...and more`

---

## Installation

See [Quick Start](#quick-start) below, or visit [synapse-mcp.dev/download](https://synapse-mcp.dev/download) for the full guide and GUI installer.

---

## Pricing

### Free — The Golden Graph · $0 forever

| Feature | Details |
|---|---|
| **AST Indexing** | 10,000+ files across 50 languages in seconds |
| **Search** | Semantic, symbol & regex — structured results, not file dumps |
| **Caller Graph** | Transitive caller & callee traversal with confidence scores |
| **Codebase Insights** | API surface, deletion safety, dependency graph & refactor candidates |
| **Compression** | SmartCrusher trims payloads 30–60% before they hit your LLM |
| **Privacy** | 100% local — zero cloud dependencies, zero data egress |

### Pro — The Shadow Graph · $19 / month

> ⚡ Typical token savings exceed the subscription cost.

| Feature | Details |
|---|---|
| **Safe Writes** | Simulate, validate & auto-rollback on lint failure |
| **Change Review** | Blast radius, broken contracts & ranked risk |
| **Crash Resolution** | Stack trace → root cause → reproducing tests |
| **Test Intelligence** | Coverage bands & precise gap targeting |
| **Persistent Memory** | Summaries survive across sessions |
| **Knowledge Cache** | Queries improve result ranking over time |

---

## Synapse Learns From Every Session

Most AI tools have no memory. Every session starts from zero — the agent reads the same files, discovers the same functions, and asks the same questions all over again. That's expensive and slow.

Synapse is different. It maintains a **persistent, on-device knowledge graph** that accumulates across every session. But beyond just storing the graph, it has a built-in **learning and reinforcement layer** that gets smarter the more you use it.

### How the learning works — in plain English

Think of it like a highly organised colleague who takes notes.

**1. Summaries that stick around**
When an agent (or you) explains what a function does — `"This handles Stripe webhook validation and checks for duplicate events"` — Synapse writes that to the graph permanently. Next session, any agent that touches that function gets your explanation attached automatically. You wrote it once. Every agent benefits forever.

**2. Queries that teach themselves**
Every time a search returns a useful result and the agent uses it, Synapse silently records the association: *"when someone asks X, chunk Y was the right answer."* Over time, the most useful results for common queries bubble up to the top automatically — without anyone manually tuning anything. This is retrieval reinforcement: the graph improves its own ranking from real usage.

**3. Explicit promotion**
If a result is particularly important, you can tell Synapse directly: *"for queries about payment processing, always surface this chunk first."* That instruction is stored locally and honoured in every future session.

**4. Gap detection**
Synapse tracks which parts of your codebase get queried most but have no explanation attached. It can surface these gaps on demand — so you know exactly where a five-minute annotation would have the biggest impact on future agent sessions.

The result is a codebase model that compounds. The graph grows richer, the rankings get sharper, and agents spend less time re-exploring what's already been understood.

> 🔒 The learning layer is entirely local. No queries, no summaries, and no usage signals ever leave your machine.

> ✨ **The learning and memory system is a Pro feature.** It's where we invested the most original engineering work — building a feedback loop that makes every subsequent agent session measurably faster.

---

## MCP Tool Reference

Synapse exposes **13 precision tools** over the Model Context Protocol. All tools accept a `compress_payload` flag (default `true`) that enables SmartCrusher compression — 30–60% fewer response tokens at zero information loss.

Tools marked **`FREE`** are available on all plans. Tools marked **`PRO`** require a [Pro subscription](https://synapse-mcp.dev/pro) ($19/mo). Pro features are where the truly unique engineering lives — safe atomic writes with rollback, session-to-session learning, crash resolution, and change impact analysis.

---

### `ask_synapse` — `FREE`

**The default natural-language entry point.** Send any codebase question or task in plain English. Synapse routes it to the optimal underlying tool, returns safe `next_tool_calls` to follow, and reports a `completion_state` plus `agent_instruction` so you always know what to do next.

Use this first for virtually every task — code exploration, deletion-safety checks, editing, debugging, test analysis, and administration. For "can I delete X?", "is X still used?", or "should I keep X?", include `inputs.chunk_id` when known; otherwise include `repo_id` plus an arity-qualified exact symbol in `inputs.symbol`. If the user gives only descriptive prose, ask for the concrete symbol or show candidates instead of guessing.

```json
{ "query": "Where is the retry logic for the payment service?", "repo_id": "my-org/my-repo" }
```

---

### `synapse_search_codebase` — `FREE`

**Find code by meaning, name, or pattern.** Three search modes in one tool:

| Action | Description |
|---|---|
| `semantic` | Plain-English similarity search over chunk embeddings. *"Find all places that handle auth errors"* |
| `symbol` | Exact named-symbol lookup by function, class, module, or type name |
| `regex` | Full PCRE in-memory grep across the indexed graph. Returns chunk IDs, line numbers, and tags — not raw text |

```json
{ "action": "symbol", "query": "PaymentService", "repo_id": "my-org/my-repo" }
```

---

### `synapse_explore_graph` — `FREE`

**Navigate relationships around any chunk.** Given a chunk ID (from any search result), traverse the AST dependency graph in any direction.

| Action | Description |
|---|---|
| `callers` | Every direct and transitive caller of a function, with configurable depth and confidence scores |
| `callees` | All functions/modules called by a given chunk |
| `context` | Rich neighbourhood — callers, callees, sibling definitions, and related chunks |
| `cycles` | Detect circular dependency chains in the graph |

Use this before touching any function to understand its full blast radius.

```json
{ "action": "callers", "chunk_id": "abc123", "depth": 3 }
```

---

### `synapse_get_context` — `FREE`

**Advanced context gathering for editing, onboarding, and explanation.**

| Action | Description |
|---|---|
| `find` | Open-ended semantic research — parallel semantic + exact + fuzzy + graph traversal in one call |
| `edit` | Pre-edit safety pack: callers, callees, must-read files, likely tests, and risk assessment for a planned change |
| `explain` | Plain-English explanation of what a specific chunk does |
| `onboard` | Guided reading order for a subsystem — optimal for understanding unfamiliar code |

```json
{ "action": "edit", "intent": "Refactor the caching layer to use Redis", "repo_id": "my-org/my-repo" }
```

---

### `synapse_inspect_files` — `FREE`

**Read source files and chunks with structural awareness.**

| Action | Description |
|---|---|
| `read_files` | Read files with optional line ranges and `format: "outline"` (strips bodies, keeps signatures — 60–80% fewer tokens) |
| `read_chunk` | Read a single chunk by ID directly from the in-memory store — instant, no disk I/O |
| `count_lines` | Count total indexed lines across the workspace |

Pass `format: "outline"` to scan 20+ files at a fraction of the token cost. Use `format: "full"` only when you need complete implementations.

```json
{ "action": "read_files", "files": [{ "path": "lib/my_module.ex", "ranges": ["45-80"] }], "format": "outline" }
```

> ⚠️ **Linting workflows:** Pass `compress_payload: false` when reading files to investigate whitespace or formatting violations. SmartCrusher strips trailing whitespace before returning content, which can hide the very violations you are trying to fix.

---

### `synapse_modify_files` — `PRO`

**Edit code with safety guarantees — lint-validated and atomically rolled back on failure.**

This is one of the features we're most proud of. Vanilla file writes from an agent are dangerous — a failed linter means a broken file, a half-written function, or a commit that doesn't build. `write_safely` eliminates that entire class of failure by simulating the edit in memory, running your project's own linter against it, and only committing the bytes to disk if validation passes. If anything fails, the original file is untouched.

| Action | Tier | Description |
|---|---|---|
| `write_safely` | **PRO** | Simulate, lint-validate, write atomically. Auto-rollback on failure — your file is never left broken |
| `find_and_replace` | **PRO** | Global find-and-replace across the indexed graph with pattern matching |
| `delete_chunk` | **PRO** | Remove a chunk from the graph/index. It is not source deletion guidance; use `dead_code` evidence before making any source-removal decision |

Always pair with `synapse_get_context` (`edit`) first to understand callers and impact.

```json
{ "action": "write_safely", "path": "lib/my_module.ex", "content": "..." }
```

---

### `synapse_change_review` — `PRO`

**Review diffs and assess blast radius before pushing.**

Before you push, Synapse maps every chunk your diff touches, ranks the risk, identifies broken contracts, and tells you which tests to run. This replaces a manual code review pass that typically takes 20–40 minutes for a medium-sized change.

| Action | Description |
|---|---|
| `analyse_diff` | Structural analysis of a diff: which chunks changed, what they affect |
| `review_diff` | Full review: ranked risk scores, blind spots, broken contracts, recommended tests to run |
| `impact` | Post-edit blast radius check — verify what a committed change touches |

Feed a raw diff string or a commit range. Get actionable output before you push.

```json
{ "action": "review_diff", "diff": "..." }
```

---

### `synapse_codebase_insights` — `FREE`

**Codebase-level analysis in a single call.** Use the `dead_code` action, normally through `ask_synapse`, when an agent needs function-level evidence about whether one exact symbol or chunk is still used or safe to delete.

| Action | Description |
|---|---|
| `detect` | Language detection across the workspace |
| `public_api` | Extract the full public API surface of a module or the entire codebase |
| `dead_code` | Read-only function-level deletion-safety check: `chunk_id` or arity-qualified symbol input, production callers, test callers, confidence, caveats, and `safe_to_delete` |
| `contracts` | Scan for interface/behaviour/protocol contracts and their implementations |
| `dependencies` | Inter-module dependency graph — who imports whom |
| `overview` | Consolidated high-level overview of the codebase architecture |
| `refactor_opportunities` | Identify hotspots: duplicated logic, bloated modules, tight coupling |

```json
{ "action": "overview", "repo_id": "my-org/my-repo" }
```

Deletion-safety questions should normally enter through `ask_synapse` so routing, missing-input guidance, and `agent_instruction` are preserved:

```json
{
  "query": "Can I delete this chunk?",
  "repo_id": "my-org/my-repo",
  "inputs": { "chunk_id": "my-org/my-repo:lib/parser.ex:120" }
}
```

```json
{
  "query": "Is Parser.parse/2 still used?",
  "repo_id": "my-org/my-repo",
  "inputs": { "symbol": "Parser.parse/2" }
}
```

If no `chunk_id` is available, pass `repo_id` plus an arity-qualified symbol such as `Parser.parse/2`; descriptive prose should produce clarification or candidates, not a guessed deletion decision.

Interpret `dead_code` by reading `preferred_identifier`, `valid_input_patterns`, `scope`, `clause_level_analysis`, `safe_to_delete`, `deletion_risk`, `confidence`, `caveats`, and `supporting_evidence.production_callers` / `supporting_evidence.test_callers`. `dead_code` is function-level; clause-level reachability is currently reported as unsupported. Production callers mean keep it; test-only callers and unknown visibility should be presented as caution, not automatic deletion.

---

### `synapse_test_quality` — `PRO`

**Test discovery and coverage analysis — no test runner required.**

Derives test coverage and gaps directly from the AST graph — without running a single test. This is particularly powerful for large codebases where a full test suite takes minutes to execute. Synapse tells you what's covered, what isn't, and where to focus next, in seconds.

| Action | Description |
|---|---|
| `coverage` | Coverage band analysis — which functions are tested, which have gaps |
| `find_tests` | Locate tests related to a specific symbol or file, confidence-ranked |
| `recommend_test_targets` | Ranked list of functions most in need of testing based on the graph |
| `setup_trunk` | Configure Trunk for linting integration |

```json
{ "action": "find_tests", "symbol": "PaymentService.charge" }
```

---

### `synapse_debug_trace` — `PRO`

**Debugging and execution tracing directly from the AST graph.**

Paste a raw stack trace and get back a root-cause analysis that maps each frame directly to your indexed chunks — with a suggested reproducing test and the call chain that led there. No runtime, no debugger, no re-running the failure scenario.

| Action | Description |
|---|---|
| `resolve_stack` | Paste a stack trace; get root-cause analysis mapped to your graph with reproducing test suggestions. No runtime needed |
| `trace_behaviour` | Trace the execution path of a behaviour or callback through the graph |

```json
{ "action": "resolve_stack", "stack_trace": "..." }
```

---

### `synapse_knowledge_cache` — `PRO`

**The learning and reinforcement layer. Persistent knowledge that survives across sessions.**

This is Synapse's most unique capability. See [Synapse Learns From Every Session](#synapse-learns-from-every-session) for a plain-English explanation of how it works.

| Action | Description |
|---|---|
| `save_summary` | Attach a plain-English description to a chunk. Every future query hitting that chunk gets your explanation for free |
| `query` | Search the cache by intent — retrieve promoted results from previous sessions |
| `learn` | Explicitly promote a chunk for a query, immediately improving future result ranking |
| `suggest` | Find high-traffic chunks that lack summaries — investing here improves all future sessions |

```json
{ "action": "save_summary", "chunk_id": "abc123", "summary": "Handles Stripe webhook validation and idempotency checks." }
```

---

### `synapse_manage_repos` — `FREE`

**Register, list, and manage repositories in the Synapse graph.**

| Action | Description |
|---|---|
| `list` | List all registered repositories with indexing status |
| `register` | Register a new repository root. Automatically detects Git worktrees for delta-only indexing |
| `archive` | Pause indexing for a repo without removing its data |
| `restore` | Re-activate an archived repository |
| `keep` | Dismiss a dirty-merged worktree advisory and keep the overlay as-is |
| `unregister` | Remove a repository from the graph entirely |
| `update_excludes` | Update glob patterns to exclude paths from indexing |

```json
{ "action": "register", "path": "/path/to/my-repo" }
```

---

### `synapse_indexer_control` — `FREE`

**Health checks and indexer administration.**

| Action | Description |
|---|---|
| `status` | Current indexing phase, file counts, embedding readiness, and per-repo status |
| `health` | System health check — confirms the server is up and the graph store is accessible |
| `trigger` | Manually trigger a re-index for a specific repository |

```json
{ "action": "status", "repo_id": "my-org/my-repo" }
```

---

### `synapse_capability_manifest` — `FREE`

**Self-documenting tool surface.** Returns the full list of available tools, actions, and parameters for the running Synapse version. Useful for agents bootstrapping a new session or checking what features are available on the connected server.

```json
{}
```

---

## Git Worktree Support

Synapse supports **Git worktrees** transparently via the **Virtual Worktree Overlay (VWO)**:

- **Delta Indexing** — only modified/added/deleted files are re-indexed. Near-instant (< 50ms).
- **Overlay Priority** — worktree chunks shadow parent repo chunks automatically.
- **Parallel Agent Workflows** — spawn multiple sub-agents in separate worktrees without duplicating the main index.

---

## Works Everywhere

Synapse implements the open [Model Context Protocol](https://modelcontextprotocol.io). If your tool speaks MCP, it works with Synapse.

**IDEs & Editors:** Cursor · Windsurf · VS Code · Zed · JetBrains AI

**Agents:** Claude Code · GitHub Copilot · Devin · Aider · Cline · Continue.dev · Replit Agent · Amazon Q · OpenHands · SWE-agent · Plandex · Antigravity

**Tools:** Sourcegraph Cody · Qodo · Tabnine

---

## Quick Start

**Full install guide & GUI installer:** [synapse-mcp.dev/download](https://synapse-mcp.dev/download)

### Linux / macOS

```sh
curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh
```

> Downloads and runs the install script — [inspect it first](https://downloads.synapse-mcp.dev/install.sh)

### Windows

```powershell
powershell -c "irm https://downloads.synapse-mcp.dev/install.ps1 | iex"
```

> Run from PowerShell — [inspect the script first](https://downloads.synapse-mcp.dev/install.ps1)

The installer auto-detects your MCP client (Cursor, Claude Code, Windsurf, VS Code, etc.) and writes the correct config.

---

## Cursor Plugin

This repository doubles as a [Cursor](https://cursor.com) plugin. Installing it
connects Cursor to the Synapse server running on your machine and adds the agent
skill and routing rule that keep the agent on the knowledge graph instead of
grep.

[![Add Synapse MCP to Cursor](https://cursor.com/deeplink/mcp-install-dark.svg)](cursor://anysphere.cursor-deeplink/mcp/install?name=synapse&config=eyJ1cmwiOiJodHRwOi8vMTI3LjAuMC4xOjg1ODUvbWNwIn0=)

**The plugin ships no binaries and downloads nothing.** It is configuration — it
points Cursor at `http://127.0.0.1:8585/mcp`, which is where Synapse listens once
it is installed and running. Install Synapse first:

```sh
# macOS / Linux
curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh

# Windows
powershell -c "irm https://downloads.synapse-mcp.dev/install.ps1 | iex"
```

Then `synapse-mcp install` to sign in, start the service, and enable autostart.
Already have it? `synapse-mcp status` will tell you.

If you install the plugin before Synapse, nothing breaks — the rule and skill
load, and the `synapse` MCP server simply shows as disconnected until the
service is up. Run `/synapse-setup` in Cursor and the agent will walk you
through it.

**What you get**

| Component | Path | What it does |
|---|---|---|
| MCP server | `mcp.json` | Registers `synapse` against your local server |
| Skill | `skills/synapse-mcp/` | Full tool reference and workflows |
| Rule | `rules/synapse.mdc` | Routes discovery through Synapse, not grep |
| Command | `commands/synapse-setup.md` | `/synapse-setup` — install, start, verify |

The endpoint is identical on macOS, Linux, and Windows, so there is nothing
platform-specific in the configuration. Autostart is user-level on all three —
launchd, a systemd user unit, or Task Scheduler — and needs no root or admin
rights. See [OS Autostart](#os-autostart).

**WSL, remote SSH, and devcontainers**

If Cursor runs on one machine and your code lives on another — Windows Cursor
against a WSL checkout, a remote SSH host, a devcontainer — then Cursor's
`127.0.0.1` and the repository's `127.0.0.1` are two different machines. Install
and run Synapse on the side the repository is on, and make sure port 8585 there
is reachable from the side running Cursor.

**Developing against it locally**

Cursor's local plugin loader rejects symlinks whose target lies outside
`~/.cursor/plugins/local`, so copy the directory in rather than linking it:

```sh
rsync -a --delete --exclude .git ./ ~/.cursor/plugins/local/synapse-mcp/
```

Re-run that after each change, then restart Cursor or run
**Developer: Reload Window**, and check **Customize** for the rule, skill,
command, and MCP server.

If the plugin does not appear, the loader logs why. Look for
`loadUserLocalPlugin` in:

```sh
ls -t ~/Library/Application\ Support/Cursor/logs | head -1
# then: <that dir>/window*/exthost/anysphere.cursor-agent-exec/Cursor\ Plugins.*.log
```

---

## Privacy

**100% local.** Synapse runs entirely on your machine. No code leaves your environment, no cloud dependencies, no data egress. Your codebase stays yours.

---

## Contributing — Help Agents Use Synapse Better

> **This is the highest-leverage contribution you can make.**

LLMs are trained on billions of lines of code where developers reach for `grep`, `find`, `cat`, and `ls` to explore a codebase. That muscle memory is baked into the model weights. When an agent is dropped into a new project, its first instinct is to grep — even when a smarter, cheaper tool is available.

Synapse ships a set of **agent skill files** (`skills/synapse-mcp/SKILL.md`, `AGENTS.md`) that agents load at session start. These files override the grep instinct by giving agents explicit routing rules, anti-patterns, and example tool calls. They are, in effect, **runtime training for the meta-layer** — teaching agents *how* to use the tools they have, not just what the tools do.

**The problem:** We can only write what we observe. You may have seen failure modes, routing gaps, or phrasing that your specific agent ignores. We haven't. The skill files improve dramatically with real-world usage reports.

### What we'd love your help with

| Area | What to contribute |
|---|---|
| **Anti-patterns** | Agent behaviours you've seen that Synapse should suppress (e.g. "my agent still greps even after loading the skill") |
| **Routing rules** | Cases where an agent picked the wrong Synapse tool — what was the query, what should it have done? |
| **Phrasing that works** | If a specific instruction wording reliably stops your agent from falling back to grep, share it |
| **Agent-specific quirks** | Claude, GPT-4o, Gemini, and Copilot all have different tendencies. Agent-specific `AGENTS.md` sections help enormously |
| **New tool examples** | Concrete JSON examples for actions that aren't yet covered in the skill |
| **Missing workflows** | Scenarios (debugging, onboarding, large refactors) where the skill gives no guidance |

### How to contribute

1. **Open an issue** — describe the failure mode or gap you observed. Include the agent, the query, and what it did vs. what it should have done.
2. **Open a PR** — edit [`AGENTS.md`](AGENTS.md) or [`skills/synapse-mcp/SKILL.md`](skills/synapse-mcp/SKILL.md) directly. Skill file PRs are reviewed and merged fast — they don't require tests.
3. **Share a benchmark** — if you've run Synapse vs. shell tools on your own codebase and have numbers, we want to publish them.

The skill files live in `skills/`. They are plain Markdown — no Elixir knowledge required. If you can describe what went wrong, you can write the fix.

---

## What's Next — Myelix Agents · Coming Q3 2026

Synapse gives your existing AI agents a precision map of your codebase. **Myelix Agents** is the next step: AI coding agents built from the ground up to *think* before they code.

Where current agents react — reading a file, writing a change, hoping for the best — Myelix Agents plan. They maintain an explicit task model, reason about risk before touching code, incorporate learnings from previous sessions (via Synapse's knowledge graph), and course-correct when something goes wrong. Accuracy over speed. Thought over grep.

Synapse Pro subscribers will get early access. [Join the waitlist →](https://synapse-mcp.dev)

---

## License

Two different things live under one name, so it is worth being precise.

**This repository** — the documentation, the `skills/synapse-mcp` agent skill,
and the Cursor plugin — is [MIT licensed](LICENSE). Copy it, adapt it, ship it
in your own tooling. Pull requests on the skill files are welcome.

**The Synapse MCP server** is proprietary. Its source is not in this repository,
and the binaries from [synapse-mcp.dev](https://synapse-mcp.dev) are not covered
by the MIT License. Use is governed by the
[Terms of Service](https://synapse-mcp.dev/terms).

Synapse is **free to use** on the Golden Graph tier — free is a price, not a
license. See [Pricing](#pricing).

---

## Support

**Need help?** [Open an issue](../../issues) and we'll get back to you. Bug reports, feature requests, and integration questions are all welcome.

- 🐛 [Report a bug](../../issues/new?template=bug_report.md)
- 💡 [Request a feature](../../issues/new?template=feature_request.md)
- 💬 [Ask a question](../../issues/new?template=question.md)

---

## Links

- 🌐 [synapse-mcp.dev](https://synapse-mcp.dev) — Website & docs
- ⬇️ [Download & install guide](https://synapse-mcp.dev/download)
- 📖 [Blog — technical deep-dives & benchmarks](https://synapse-mcp.dev/blog/index.html)
- 🔒 [Privacy policy](https://synapse-mcp.dev/privacy)

---

<div align="center">
  <sub>Built by <a href="https://myelixlabs.com">Myelix Labs</a> · Made with ♥ in 100% Elixir for AI engineers everywhere</sub>
</div>
