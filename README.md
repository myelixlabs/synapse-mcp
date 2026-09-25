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

**A persistent code-knowledge graph for AI agents. Runs locally. Writes safely.**

[![Free](https://img.shields.io/badge/Free-forever-22c55e?style=flat-square)](https://synapse-mcp.dev)
[![Pro](https://img.shields.io/badge/Pro-%2419%2Fmo-2ef2ff?style=flat-square)](https://synapse-mcp.dev/pro)
[![MCP Compatible](https://img.shields.io/badge/MCP-compatible-a45cff?style=flat-square)](https://modelcontextprotocol.io)
[![Languages](https://img.shields.io/badge/Languages-50%2B-white?style=flat-square)](https://synapse-mcp.dev/languages)
[![100% Local](https://img.shields.io/badge/100%25%20Local-No%20cloud-ff6b6b?style=flat-square)](#local-first-always)
[![Preview](https://img.shields.io/badge/Currently%20in%20Preview-Feedback%20welcome-f59e0b?style=flat-square)](https://github.com/myelixlabs/synapse-mcp/issues)
[![Zero Data Egress](https://img.shields.io/badge/Zero%20Data%20Egress-Privacy%20first-f5c542?style=flat-square)](#local-first-always)

</div>

---

> 🏗️ **Currently in Preview.** Synapse MCP is actively evolving. We want your feedback — [open an issue](https://github.com/myelixlabs/synapse-mcp/issues/new/choose) to tell us what breaks, what's missing, or what would make you switch from grep for good.

---

Synapse MCP is a **free, 100% local MCP server** that turns your codebase into a persistent, in-memory AST knowledge graph. Claude, Cursor, Copilot, and every MCP-compatible agent gets exact caller trees, semantic search, safe atomic writes, and diff-aware change review — without a single byte of your code leaving the machine.

```sh
# Linux / macOS
curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh

# Windows PowerShell
irm https://downloads.synapse-mcp.dev/install.ps1 | iex
```

---

## What Synapse actually does

Most code-graph tools stop at discovery: index the codebase, answer questions about it, done. Synapse goes further.

It runs as a **persistent BEAM daemon** — not a CLI you invoke, but a long-lived process that keeps your graph in memory across sessions. It watches files for changes automatically (inotify / FSEvents / kqueue) and re-indexes only the changed files, not the whole workspace. When you pull new commits it detects the new Git HEAD and re-indexes only the diff.

On top of that it adds what no competitor offers: **safe write capability**. Before any proposed edit touches disk, Synapse simulates it in memory, validates it against the compiler and linter, maps the blast radius, and only commits atomically on passing every gate. If anything fails it rolls back. Your files are never left broken.

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

### What your agent gets

| Tool group | What it does |
|---|---|
| `ask_synapse` | Natural-language entry point — routes to the right tool automatically |
| `synapse_get_context` | Pre-built structural slices: callers, callees, contracts, summaries |
| `synapse_search_codebase` | Semantic (BM25F + embeddings), symbol, and regex — structured chunk IDs, not file dumps |
| `synapse_explore_graph` | Transitive caller / callee traversal, cycle detection, context |
| `synapse_modify_files` | Simulate → validate → write atomically → rollback on lint failure |
| `synapse_change_review` | Diff analysis, blast-radius ranking, broken-contract detection |
| `synapse_debug_trace` | Stack trace → AST root cause → reproducing test suggestions |
| `synapse_test_quality` | Coverage bands, test mapping, ranked gap targets |
| `synapse_codebase_insights` | Dead-code deletion safety, public API surface, dependency graph, refactor opportunities |
| `synapse_knowledge_cache` | Persistent summaries and retrieval reinforcement across sessions |
| `synapse_manage_repos` | Multi-repo registry — register, archive, restore; Git worktree support |

---

## Benchmark — Autonomous Security Audit · 500k LOC · Same Frontier Model

| Metric | Synapse vs. shell tools |
|---|---|
| Tokens & Cost | **−60%** |
| Speed | **2.2× faster** |
| Tool calls | **−47%** |
| Accuracy | **100% — identical** |
| Data sent to cloud | **0 bytes** |

Fewer tool calls + no network latency = dramatically faster agent loops. The agent spends tokens on the actual task, not on exploration.

---

## Why not just use X?

We get asked this a lot. Here is the honest answer, with source-verified facts.

### "Why not Graphify?"

Graphify is a Python CLI that extracts your codebase into a `graph.json` file. It is **read-only, file-based, and stateless**. Every query re-reads the JSON. There is no MCP server, no semantic search, no write safety, no multi-repo support, and no persistent memory. It is a good offline export tool. It is not a graph engine.

### "Why not CodeGraph (colbymchenry)?"

CodeGraph is a serious read-only tool with one capability Synapse does not match: **HTTP route-chain tracing** — following a URL through routing layers into the handler and template for 17 frameworks (Django, Rails, Express, Spring, etc.). If that specific capability is your entire use case, CodeGraph is worth evaluating.

Everything else: CodeGraph has no semantic/vector search (FTS5 only), no write safety, no multi-repo support, no change review, no test mapping, no debug tracing, and no persistent memory. It exposes one MCP tool by default (`codegraph_explore`). It is per-project only.

### "Why not code-graph-mcp (sdsrss)?"

code-graph-mcp is the most technically sophisticated read-only alternative. It has a BLAKE3 Merkle-tree incremental indexer, hybrid BM25 + vector search via Reciprocal Rank Fusion, and 20 tree-sitter parsed languages. It is a well-engineered single binary.

It is still **read-only**. No write safety, no change review, no multi-repo, no worktrees, no debug tracing. Its 20 languages versus Synapse's 50+ means no Elixir, Erlang, Haskell, OCaml, Scala, Solidity, COBOL, Zig, Gherkin, HCL, Protobuf, GraphQL, or SQL DDL. Its dependency auditing runs on a daily cron; Synapse's runs on every push and blocks the pipeline on failure.

**The real difference** is that Synapse is the only one in this category that can actively prevent AI agents from breaking production. A tool that cannot write is a tool that cannot protect you from a write.

---

## 50+ Languages. One graph.

AST-aware chunking and call-graph edge extraction — no plugins, no configuration, no cloud.

`Elixir` `Python` `TypeScript` `JavaScript` `Go` `Rust` `OCaml` `Haskell` `F#` `Clojure` `Scala` `Java` `Kotlin` `Swift` `Objective-C` `C` `C++` `C#` `Ruby` `PHP` `Dart` `Zig` `Erlang` `Julia` `Groovy` `Solidity` `GraphQL` `HCL / Terraform` `Protobuf` `SQL DDL` `Gherkin` `Shell` `PowerShell` `Lua` `...and more`

---

## Local First. Always.

> 🔒 **Your code never leaves your machine.** No cloud indexing, no API calls with your source, no telemetry, no vendor lock-in.

The full AST graph — every function, every edge, every embedding — is built and stored locally in a persistent on-device store. Agents query it directly over MCP. Nothing goes out.

This matters for:
- **Enterprise & regulated environments** — source code stays inside your perimeter
- **Open source contributors** — your unreleased work stays unreleased
- **Anyone who values speed and accuracy** — local in-memory graph queries at sub-millisecond latency. No network round-trip, ever. No remote index that's out of date.

---

## Engineering

Synapse is built to a production standard.

- **Security audit on every push** — `mix deps.audit` runs in CI with `allow_failure: false`. A dependency vulnerability blocks the pipeline immediately, not within 24 hours.
- **Multi-platform smoke tests** — every release candidate is built for Linux x86\_64/aarch64, Darwin x86\_64/aarch64, and Windows x86\_64, then exercised via real-process SSE smoke tests before it reaches R2.
- **BDD end-to-end** — full Cucumber suite runs through the actual packaged binary boundary (Burrito + Rust launcher), not a mock.
- **Signed release manifest** — the launcher verifies binary integrity against a cryptographically signed manifest before executing. A tampered binary does not start.
- **Launcher version gate** — promotion is blocked if the launcher version hasn't been incremented correctly. A mis-versioned release cannot ship.
- **Zero-latency file watching** — the indexer drains all pending file events from its mailbox in a single pass (no sleep, no fixed debounce) and detects new Git HEAD commits, re-indexing only the changed diff.

---

## Features at a Glance

| Feature | Description |
|---|---|
| 🔒 **100% Local & Private** | Graph built and stored on your machine. Zero cloud dependencies, zero data egress, zero network latency on queries |
| ⚡ **Sub-millisecond Graph Queries** | In-memory ETS store — reads are direct table lookups with no I/O |
| 🚀 **SmartCrusher Compression** | Responses auto-minified 30–60%: short keys, stripped nulls, relativised paths. Outline mode strips bodies — scan 20+ files at a fraction of the token cost |
| **Three Search Modes** | Semantic (BM25F + random-projection embeddings, in-process, zero external ML runtime), symbol lookup, and PCRE regex |
| **Transitive Caller Graph** | Every direct and transitive caller of any function. Configurable depth, confidence scores, edge labels, production vs. test caller splitting |
| **Safe Atomic Writes** | Simulate edits in memory, validate against the compiler and linter, write atomically, auto-rollback on failure. Files are never left broken |
| **Instant Crash Resolution** | Stack trace → root-cause analysis mapped to your AST → reproducing test suggestions |
| **Change Review & Impact** | Feed a diff or commit range. Get ranked blast radius, broken contracts, tests to run, and blind spots — before you push |
| **Persistent Agent Memory** | Summaries written in one session are available in the next. Retrieval reinforcement improves result ranking from real usage |
| **Test Intelligence** | Coverage bands, test mapping, and ranked test targets — derived from the graph without executing your test suite |
| **Codebase X-Ray** | Language detection, public API surface, dead-code deletion safety, inter-module dependency graph, contract scanning, refactor opportunities |
| **Multi-repo & Git Worktrees** | Register multiple repos. Run parallel sub-agents in Git worktrees — each gets delta indexing against the parent index, no full re-index per worktree |

---

## Pricing

### Free — The Golden Graph · $0 forever

| Feature | Details |
|---|---|
| **AST Indexing** | 10,000+ files across 50+ languages |
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
If a result is particularly important, you can tell Synapse directly: *"for queries about payment processing, always surface this chunk first."* That instruction is stored and applied on every subsequent query.

---

## Installation

See [synapse-mcp.dev/download](https://synapse-mcp.dev/download) for the full guide and GUI installer.

```sh
# Linux / macOS
curl -fsSL https://downloads.synapse-mcp.dev/install.sh | sh

# Windows PowerShell
irm https://downloads.synapse-mcp.dev/install.ps1 | iex
```

---

## Claude plugin

This repository is also a Claude plugin. It adds the `synapse-mcp` skill, which teaches Claude to use the Synapse tools before grep and raw file reads, and the `/synapse-mcp:synapse-setup` command, which checks that Synapse is installed, running, and connected to Claude Code.

The plugin itself contains only Markdown and JSON. It does not bundle or start an MCP server, run hooks, or send any data anywhere. The Synapse tools come from the Synapse MCP server you install separately with the commands above, which registers itself with Claude Code on `127.0.0.1:8585`. Local MCP servers work in Claude Code and in Cowork sessions on your own computer; claude.ai chat loads the skill but cannot reach a local server.

What the separately installed Synapse server does over the network:

- Indexing, search, and edits run entirely on your machine. Your source code is never uploaded.
- Signing in and checking your plan contacts `api.synapse-mcp.dev` with your account token.
- Installing and updating downloads the Synapse binaries from `downloads.synapse-mcp.dev`.

---

## Contributing — Help Agents Use Synapse Better

> **This is the highest-leverage contribution you can make.**

LLMs are trained on billions of lines of code where developers reach for `grep`, `find`, `cat`, and `ls` to explore a codebase. That muscle memory is baked into the model weights. When an agent is dropped into a new project, its first instinct is to grep — even when a smarter, cheaper tool is available.

Synapse ships a set of **agent skill files** (`.agents/skills/synapse-mcp/SKILL.md`, `AGENTS.md`) that agents load at session start. These files override the grep instinct by giving agents explicit routing rules, anti-patterns, and example tool calls. They are, in effect, **runtime training for the meta-layer** — teaching agents *how* to use the tools they have, not just what the tools do.

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
2. **Open a PR** — edit [`AGENTS.md`](AGENTS.md) or [`.agents/skills/synapse-mcp/SKILL.md`](.agents/skills/synapse-mcp/SKILL.md) directly. Skill file PRs are reviewed and merged fast — they don't require tests.
3. **Share a benchmark** — if you've run Synapse vs. shell tools on your own codebase and have numbers, we want to publish them.

The skill files live at the repo root and in `.agents/`. They are plain Markdown — no Elixir knowledge required. If you can describe what went wrong, you can write the fix.

---

## What's Next — Myelix Agents · Coming Q3 2026

Synapse gives your existing AI agents a precision map of your codebase. **Myelix Agents** is the next step: AI coding agents built from the ground up to *think* before they code.

Where current agents react — reading a file, writing a change, hoping for the best — Myelix Agents plan. They maintain an explicit task model, reason about risk before touching code, incorporate learnings from previous sessions (via Synapse's knowledge graph), and course-correct when something goes wrong. Accuracy over speed. Thought over grep.

Synapse Pro subscribers will get early access. [Join the waitlist →](https://synapse-mcp.dev)

---

## Support

**Need help?** [Open an issue](https://github.com/myelixlabs/synapse-mcp/issues) and we'll get back to you. Bug reports, feature requests, and integration questions are all welcome.

- 🐛 [Report a bug](https://github.com/myelixlabs/synapse-mcp/issues/new/choose)
- 💡 [Request a feature](https://github.com/myelixlabs/synapse-mcp/issues/new/choose)
- 💬 [Ask a question](https://github.com/myelixlabs/synapse-mcp/issues/new/choose)

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
