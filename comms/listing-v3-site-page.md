# Workshop A site page, v3.1 (drafted 2026-09-16 from agenda v3.1)

Replaces the pre-v3 atldevcon.com page text section for section. Source of truth for times: ../ADC-Precon-Workshop-2026-v2-agenda.md.

## Workshop Thesis

Good architecture and agentic AI tooling multiply each other. Clear boundaries, explicit rules, executable fitness tests, and CI gates are exactly what make an AI coding agent effective, and the agent is what makes the ceremony of a well-built, well-shipped system cheap enough to actually do. This workshop teaches both at once by taking one system through the whole software lifecycle with an AI pair.

## What This Workshop Is About

Most teams use AI coding agents like a fancy autocomplete. The agents moved on: they read, plan, edit, run tests, write pipelines, and review code. What they need from you is structure: a written spec, a codebase with real boundaries, and tests, hooks, and gates that catch them when they are confidently wrong.

This hands-on day walks one application through every phase of the SDLC with Claude Code as your pair while you make the decisions. Starting from an empty solution, you practice spec-driven development, build a modular .NET 10 app with a rich domain model and a hand-rolled CQRS pipeline (no frameworks, you will see every line), test it at the unit and API level, and lock the architecture in with fitness tests that fail the build when anyone, human or AI, breaks a layer rule.

Then you take it past the IDE. You push it to GitHub behind a CI pipeline the agent wrote, watch a pull request go red on a deliberate violation and green after the fix, and cut a release that publishes a container image. You run it under Aspire and let the agent read live telemetry to find and fix a bug, expose your app to any AI client through an MCP endpoint hosted inside it (and watch your domain rules stop a prompt-injection attempt), and have one agent score the architecture while a second agent tries to disprove the score.

The day closes with a field report on running two production applications and an open-source framework this way for a year: what the agent caught, what it missed, and what it costs in tokens.

## What You'll Build

- A modular .NET 10 application, generated from a written spec
- Rich domain models with factory methods that return results instead of throwing
- A hand-rolled CQRS pipeline with validation and logging decorators (no frameworks)
- Unit tests written first and an API-level integration test against a real SQL container
- Architecture fitness tests plus the hooks and deny rules that guard the agent
- A GitHub repo with agent-authored CI, branch protection, dependency audit, and a tagged release that publishes a container image
- An Aspire AppHost with dashboard traces, logs, and health checks, wired so the agent can read them
- An MCP server hosted inside your app that lets Claude Code, VS Code, or any MCP client drive it
- An agent-produced architecture scorecard, checked by a second agent

## What You'll Learn

- Spec-driven development (SDD) and plan-first work with an AI agent
- Context engineering: CLAUDE.md, AGENTS.md, and portable Agent Skills (SKILL.md), an open format that Claude Code, Copilot, and Codex all support
- Domain-Driven Design building blocks and Clean Architecture on .NET 10
- Test-driven development with an AI pair, from unit tests to integration tests
- Guardrails that bind humans and agents alike: fitness tests, hooks, deny rules, sandboxing, least-privilege tokens, CI gates
- Shipping with an agent: CI, supply-chain checks, AI code review, releases
- Running and observing a .NET app with Aspire, including the liveness-versus-readiness rule, and closing the loop with the Aspire MCP server so the agent verifies its own fixes
- Model Context Protocol (MCP) as another front door to your application, the 2026 spec and its authorization model, and prompt-injection defense
- Evals for architecture: the agent as judge, and how to keep it honest
- How to run a production SDLC with Claude Code: skills, parallel agents in git worktrees, and token and context discipline

## Prerequisites (sent to attendees ahead of time)

- A laptop you can install software on
- .NET 10 SDK
- Docker Desktop (SQL Server runs as a container; nothing else to install)
- Git and an IDE of your choice (Visual Studio, Rider, VS Code)
- The GitHub CLI (signed in) and the EF Core tools
- Aspire CLI 13.6 or newer and its templates
- Node.js 22.19 or newer (for the free MCP Inspector)
- A GitHub account (the workshop repo you push will be public, so branch protection works on the free plan)
- Claude Code is nice to have, not required. With a Claude Pro, Max, Team or Enterprise plan or an Anthropic Console (API) account (the free plan does not include Claude Code) you will move faster, but every lab has a manual path, the MCP lab works with MCP Inspector or VS Code, and the scoring lab has a follow-along path.
- Intermediate .NET assumed (dependency injection, EF Core basics, xUnit)

A setup checker script is emailed to registrants before the workshop. Setup clinic available 8:15 to 9:00 AM for anyone who needs help.

## Full Day Agenda (Friday, October 16, 2026, 8:15 AM to 5:00 PM)

Each block is labeled with the lifecycle phase it covers.

**8:15-9:00 AM: Setup clinic**
SDK, Docker, Git, IDE, GitHub, Aspire, and Node checks, plus an Aspire smoke test.

**9:00-9:15 AM: Map: the SDLC with an AI pair**
The day's map is the lifecycle. The agent is a very fast new hire that onboards off the same rules your humans do, and architecture discipline is exactly what makes it effective. Plus what this day is not: building agents into your software.

**9:15-10:05 AM: Lab 1 (Plan): spec-driven walking skeleton**
Write the context files (CLAUDE.md, plus AGENTS.md for every other agent) first, capture requirements and design in a spec, use plan mode, review the plan, then let the agent scaffold the layered solution and verify it.

**10:05-10:20 AM: Break**

**10:20-11:10 AM: Lab 2 (Design and build): the domain layer, making illegal states unrepresentable**
Aggregates, factory methods returning Result<T>, value objects, domain events. Write tests first, let the agent make them pass, review the diff like a reviewer. Plus a quick look at what C# union types in .NET 11 mean for this code.

**11:10 AM-12:05 PM: Lab 3 (Build and test): CQRS by hand and the decorator pipeline**
Commands versus queries, hand-rolled validation and logging decorators, and vertical slices added from one portable Agent Skill. The second slice is test-first at the API level: the agent writes an integration test against a real SQL container before the code. Plus a short look at the outbox pattern.

**12:05-12:50 PM: Lunch**

**12:50-1:30 PM: Lab 4 (Verify): fitness tests, rules that bind humans AND the AI**
Architecture fitness tests as executable rules, then ask the agent to break one and watch the build fail. Add the hooks, deny rules, and sandboxing that make dangerous agent actions impossible, and give the agent only the permissions it needs.

**1:30-2:15 PM: Lab 5 (Review, integrate, release): ship it**
Push to GitHub. The agent writes the CI workflow: build, unit, integration, and fitness tests, plus lock files and dependency audit. Turn on branch protection with required checks, open a pull request with a deliberate layer violation, watch it go red, fix it, merge on green. See an AI code review posted on the pull request as an advisory check, then tag a release that publishes a container image.

**2:15-2:45 PM: Lab 6 (Deploy and operate): run it**
The agent adds an Aspire AppHost. Read the dashboard: traces across a create-ticket call, logs, and health, and learn why startup must wait on liveness, never readiness. Then connect the agent to the Aspire MCP server and watch it find a planted bug from live traces, fix it, and prove the fix. Finally, watch the same app deploy to Azure Container Apps from the pipeline.

**2:45-3:00 PM: Break**

**3:00-3:55 PM: Lab 7 (Extend): your app as an MCP server**
Host an MCP endpoint inside your app with the official .NET SDK, exposing the module's commands and queries as tools that reuse your handlers. Learn what the 2026 MCP spec changed and how remote MCP servers are secured. Connect Claude Code, VS Code, or MCP Inspector and drive the app in plain English. Then try a prompt-injection attack through a poisoned ticket and watch your domain rules stop it.

**3:55-4:20 PM: Lab 8 (Govern): evals for architecture, the agent as judge**
Write a five-rule mini rubric, have an agent score the codebase with file-and-line evidence, and have a second agent try to disprove every score.

**4:20-4:55 PM: Maintain and improve: a year of production SDLC with Claude Code**
A field report from two production apps and an open-source framework: custom commands and skills as codified workflows (with a five-minute mini-lab to write your own skill), parallel agents building in separate git worktrees, documentation that fails the build when it drifts, memory files and agent-maintained knowledge, security, performance, and cost passes run by the agent (what it caught, what it missed), real failure examples, and the rules that cut token spend without cutting quality. Starter kit walkthrough.

**4:55-5:00 PM: Wrap**
A three-minute clip of the finale the architecture makes possible: lifting a module out to run as its own service behind a gateway with no rewrite. Snapshot branches and goodbye.

## You'll Leave With

- A running, tested, released application you built yourself, in your own public GitHub repo
- A CI pipeline, release workflow, Aspire setup, and in-app MCP endpoint you can copy to your own projects
- An MIT starter kit for Monday: CLAUDE.md and AGENTS.md templates, hooks, deny rules, sandbox settings, fitness-test seed, CI and release workflow templates, an Aspire seed, Agent Skills, a mini rubric with scorer and verifier agents, an MCP host reference, and a one-page token-discipline checklist
- The habits to use an AI agent across your whole delivery process without losing engineering discipline
- A public reference repo with a snapshot branch per lab, so falling behind never means dropping out

## Home page card (v3.1)

Build an AI-Ready .NET App with an AI Pair
One Day, the Whole SDLC with an AI Pair

Instructor: Ivan Ball-llovera

Level: Intermediate .NET developers, tech leads, architects

Take one .NET 10 app from spec to production with an AI pair (Claude Code). Build it with DDD, hand-rolled CQRS, and architecture fitness tests; ship it through agent-written CI; run it under Aspire; and expose it to any AI client as an MCP server.

You'll learn: spec-driven development, Clean Architecture, agent guardrails and sandboxing, CI and release with an agent, Aspire observability, MCP, architecture evals
