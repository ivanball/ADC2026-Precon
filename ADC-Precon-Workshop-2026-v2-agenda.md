# ADC 2026 Precon: revised agenda (v3.1, approved 2026-09-16; v3 approved 2026-09-08)

Working title: Build an AI-Ready .NET App with an AI Pair: Clean Architecture, MCP, and Agentic Workflows
Tagline: one day, the whole SDLC with an AI pair. Every block is labeled by lifecycle phase.
Friday October 16, 2026, Improving (Alpharetta). Setup clinic 8:15, sessions 9:00-5:00.
Hard rule unchanged: no MMCA name, package, or branding anywhere attendee-facing. Field-report and
applied blocks refer to "my open-source .NET framework and the two production apps built on it".
Supersedes v2 and v2.1 (2026-09-08, same day). v3.1 (2026-09-16) keeps every time slot and swaps
content inside blocks to cover the hottest 2026 topics; see "v3.1 changes" below the table.

| Time | Phase | Block | Min | Status |
|------|-------|-------|-----|--------|
| 8:15 | Setup | Setup clinic (SDK, Docker, Git, IDE, GitHub account, Aspire CLI + templates, Node.js, optional Claude Code; Aspire smoke step) | 45 | existing + Aspire/Node/GitHub checks |
| 9:00 | Map | S1: The SDLC with an AI pair. The day's map is the lifecycle; the agent is a very fast new hire that onboards off the same rules humans do. One "not today" slide: building agents INTO software (Microsoft Agent Framework 1.0, A2A) is out of scope, pointer to where to go | 15 | shrunk from 45 |
| 9:15 | Plan | Lab 1: Spec-driven development (SDD, named out loud; one slide on GitHub Spec Kit / Kiro). Requirements + design captured in a spec, plan mode, approve, implement, verify. CLAUDE.md first, plus a cross-agent AGENTS.md next to it | 50 | existing, -5 |
| 10:05 | Break | | 15 | |
| 10:20 | Design + build | Lab 2: Domain layer, Result pattern, aggregates, test-first with the agent. 3-min ".NET 11 is coming" sidebar: C# union types vs our Result<T> (shown, not built; labs stay on .NET 10 LTS) | 50 | existing, -10 |
| 11:10 | Build + test | Lab 3: CQRS by hand, decorator pipeline, slices via the /slice Agent Skill (SKILL.md, an open standard: Copilot reads it from .claude/skills; Codex needs it under .agents/skills). Second slice is test-first at the API level: the agent writes an integration test (WebApplicationFactory against the SQL container) before the code. 5-min outbox mention | 55 | existing +10 (integration test NEW) |
| 12:05 | Lunch | | 45 | |
| 12:50 | Verify | Lab 4: Fitness tests and guardrails (rules that bind humans AND the agent; hooks, deny rules, sandbox mode and permission modes, least-privilege short-lived tokens for the agent in CI) | 40 | existing, -5, moved earlier |
| 1:30 | Review + integrate + release | Lab 5 NEW: Ship it. Push the helpdesk to a PUBLIC GitHub repo (branch protection is not available on free private repos); the agent authors the CI workflow (build, unit, integration, fitness tests, lock files + audit mode = supply-chain beat); branch protection with required checks; PR with a deliberate layer violation -> red -> fix -> green -> squash merge. Agent code review as an advisory check (instructor demo + anyone with a key; not in the branch-protection required set). Release: tag -> agent-authored release workflow builds and publishes a container image to the GitHub container registry | 45 | NEW (replaces old 5a) |
| 2:15 | Deploy + operate | Lab 6 NEW: Run it. The agent adds an Aspire AppHost (SQL as a resource, host as a project resource, liveness vs readiness gates; startup gates on liveness, NEVER readiness). Read the dashboard: traces across a create-ticket call, logs, health. Close the loop: connect the agent to the Aspire MCP server (`aspire agent init`, `aspire agent mcp`; Aspire CLI 13.6+), have it find a planted fault from live traces/logs, fix it, and re-verify against telemetry. Deploy: instructor runs the same graph to Azure Container Apps with `aspire deploy` (about 16 min, so started before the lab and shown finishing, never on workshop wifi; per-attendee Azure not feasible; optional `aspire deploy` validation steps in the handout for attendees with their own subscription; first thing to shrink to one sentence if rehearsal runs long). FinOps field segment moved to S9 | 30 | NEW |
| 2:45 | Break | | 15 | |
| 3:00 | Extend | Lab 7: Expose the module as an MCP server hosted IN the app over streamable HTTP (official ModelContextProtocol SDK; MCP as one more adapter at the API layer; CreateTicket/CloseTicket/GetTicket as tools reusing the handlers; stdio explained, not built; connect Claude Code, VS Code, or MCP Inspector; slides on the 2026-07-28 spec: stateless core (no initialize, no Mcp-Session-Id), and auth as it stands (OAuth 2.1 resource server since 2025-06-18, incremental scopes since 2025-11-25, issuer validation and CIMD in 2026-07-28); prompt-injection demo via a poisoned ticket title, bounded by the minimal tool surface, domain invariants and one validated write path) | 55 | was Lab 6, -5 |
| 3:55 | Govern | Lab 8: Evals for architecture, the agent as judge. 5-rule mini rubric, scorer with path:line citations, adversarial verifier (CONFIRMED / DRIFTED / FLAG), human adjudication and a hand total. Instructor demo on `lab8-demo` (one planted weakness); attendees score their own repo. Attendees without an agent follow the instructor run and do the rubric-writing part. (Two-app drift analysis cut to a one-line mention in S9) | 25 | was 5b, -5 |
| 4:20 | Maintain + improve | S9: Field report, "How I actually run a production SDLC with Claude Code": custom slash commands and skills as codified workflows (+5-min mini-lab: write one skill), parallel and background agents in git worktrees (4-min demo: two slices built in parallel, then merged), documentation that cannot drift (ADR audits, scorecards, drift analysis between two apps, inventory-driven onboarding, facts drift gate), context engineering (memory files, agent-maintained wiki, generated onboarding), security + performance waves, trimmed (what it caught, what it missed), the FinOps pass as one "what the agent got wrong" slide, token and context discipline (paths not bodies, scripts for deterministic work, structured output as the report, model tiering, batched turns, chunked fan-out with resume). Starter kit walkthrough lives here | 35 | was S7, -15 (release/review moved to Lab 5) |
| 4:55 | Wrap | 3-minute extraction clip (recorded), snapshot branches, goodbye | 5 | |

## v3.1 changes (2026-09-16, approved)

No time slot moved. Swaps inside blocks, from a 2026 hot-topics review:

- Added: Agent Skills (Lab 3 /slice as SKILL.md; S9 mini-lab writes a skill), Aspire MCP server closed-loop fault fix (Lab 6), parallel/background agents in worktrees (S9 demo), AGENTS.md beside CLAUDE.md (Lab 1), sandboxing + least privilege (Lab 4).
- Modified: Lab 7 hosts MCP in-app over streamable HTTP with 2026-07-28 spec slides (stdio fallback); Lab 2 gains a .NET 11 union-types sidebar; Lab 1 names SDD and the tools.
- Moved or trimmed: FinOps segment Lab 6 -> S9 slide; two-app drift analysis Lab 8 -> S9 mention; S9 security/performance segment trimmed to fit the worktree demo.
- Deliberately NOT added: Microsoft Agent Framework / A2A / multi-agent orchestration (building agents into software, Workshop B territory; one S1 slide only), building on .NET 11 previews.
- Resolved: ModelContextProtocol 2.2.0 (2.0.0 aligned with 2026-07-28, falls back to 2025-11-25), pinned on lab7-end.

## Phase coverage

| Phase | Hands-on | Where |
|-------|----------|-------|
| Plan and requirements | yes | Lab 1 |
| Architecture and design | yes | Labs 1, 2, 4 |
| Implement | yes | Labs 1-3, 7 |
| Unit test | yes | Lab 2 |
| Integration test | yes | Lab 3 |
| Architecture test and evals | yes | Labs 4, 8 |
| Code review | yes | Lab 5 |
| CI and quality gates | yes | Lab 5 |
| Security | yes | Lab 4 hooks + sandboxing, Lab 5 supply chain, Lab 7 injection + MCP auth |
| Release and versioning | yes | Lab 5 |
| Deploy | demo | Lab 6 |
| Operate and observe | yes | Lab 6 (incl. agent reading live telemetry via Aspire MCP) |
| Maintain, docs, governance | yes | Lab 8, S9 |
| Feedback and improvement | field | S9 (FinOps slide, waves) |
| End-to-end UI test | no | stated omission: the helpdesk has no UI |

## Dropped or shrunk (cumulative, do not re-propose)

- Microsoft.Extensions.AI ticket-triage lab (v2 Lab 5): DROPPED.
- Supply-chain security lab (v2.1 Lab 5a): DROPPED as a standalone; survives as the lock-files + audit-mode beat inside Lab 5.
- Outbox session (old S4): DROPPED from the day; survives as the `session4-end` snapshot branch + a 5-min mention in Lab 3.
- S1 lecture: 45 -> 15 min.
- Extraction finale (old S6): -> 3-minute recorded clip in the wrap. Notifications module stays in the repo as the MCP target.
- Failure gallery (old S7): folded into S9 candor material.
- Second-module discovery lecture: cut.
- Alternates NOT scheduled: "AI code review as a required CI check" as its own lab (absorbed into Lab 5), Playwright + WCAG gates (no UI).

## Starter kit additions

- Skills (SKILL.md) instead of command templates: /slice, spec-first change, CI diagnosis.
- AGENTS.md template beside the CLAUDE.md template; sandbox / permission-mode settings example.
- Agent-authored CI + release workflow templates (Lab 5).
- Aspire AppHost seed with the liveness/readiness gate wiring (Lab 6).
- Mini rubric + scrubbed scorer and verifier subagent definitions (Lab 8).
- One-page token-discipline checklist.
- MCP host reference project, in-app HTTP transport (Lab 7).
- Aspire MCP setup note (Lab 6).

## Prerequisites (listing + attendee email + check-setup scripts)

- Laptop you can install software on: .NET 10 SDK, Docker Desktop, Git, IDE (VS / Rider / VS Code).
- GitHub account; the workshop repo will be PUBLIC (branch protection on free plans).
- Aspire CLI + templates (Lab 6). Node.js 22.19 or newer, 24 LTS recommended, for MCP Inspector (Lab 7).
- Claude subscription or API key: NICE TO HAVE, not required. Manual path for every lab; MCP lab works with MCP Inspector or VS Code; Lab 8 follow-along path.
- Intermediate .NET assumed (DI, EF Core basics, xUnit).

## Build work

- Lab 3: add one API-level integration test (WebApplicationFactory + SQL container) to `lab3-end`; run sheet + handout update.
- Lab 5: run sheet + handout; agent-authored CI + release workflows on the reference branch; instructor public demo repo; ~8 slides.
- Lab 1: AGENTS.md step + SDD slide. Lab 2: .NET 11 unions sidebar slide. Lab 3: /slice rewritten as a skill. Lab 4: sandbox/permission-mode beat.
- Lab 6: run sheet; AppHost step on the reference branch; planted fault + Aspire MCP config on lab6-end; optional `aspire deploy` validation steps (handout + run sheet); ~8 slides.
- Lab 7: run sheet + handout + reference branch (in-app HTTP MCP server; the stdio fallback host was dropped, stdio is one paragraph) + slides incl. 2026-07-28 spec/auth (Session 3 kit size).
- Lab 8: run sheet + mini rubric + scrubbed scorer/verifier agents; ~6 slides.
- S9: run sheet + ~12 slides (incl. FinOps slide, worktree parallel-agents demo, write-a-skill mini-lab); scrub pass for framework names in every snippet and screenshot.
- Branch chain rebuilt after `lab3-end`: lab4-end (fitness) -> lab5-end (CI + release) -> lab6-end (Aspire) -> lab7-end (MCP) -> main. Safe: repo never pushed.
- Setup clinic gains an Aspire smoke step; check-setup.ps1/.sh gain GitHub, Aspire CLI, Node checks.
- Update: Sessionize listing, atldevcon.com blurb, speaking.html, attendee email, comms/listing-v2.md ("by 5 PM" list gains CI, release, observability lines; agenda block replaced).

## Risks

- Lab 5 depends on room wifi + GitHub Actions queue time (~3 min red-to-green on a public repo); reference repo is the fallback.
- Lab 6 needs Docker + Aspire cooperating on every laptop; Aspire smoke step in the clinic. Aspire headless hang is a background-shell issue only, not a room issue.
- Deploy is instructor-demo only, on the instructor's subscription, in its own new resource group (the deploy prompt suggests existing groups; never accept one). A deploy takes about 16 min and teardown about 19, so it starts before the lab; no recording.
- Lab 6 is dense after v3.1 (AppHost, dashboard, health gates, Aspire MCP loop, deploy demo in 30 min): if rehearsal runs long, shrink the deploy to one sentence first.
- Aspire MCP commands are `aspire agent init` / `aspire agent mcp` since 13.2; check-setup requires 13.6+ (the AppHost pins Aspire 13.6.0).
