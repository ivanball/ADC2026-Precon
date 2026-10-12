# ADC 2026 Precon Workshop: Architecture + AI-Accelerated SDLC (framework-neutral)

Status: SUPERSEDED by `ADC-Precon-Workshop-2026-v2-agenda.md` (agenda v3.1, approved 2026-09-16); kept as the original proposal (2026-08-09, synced 2026-08-18 with the artifact version). One-day precon
at Atlanta Developers Conference.
Supersedes the two 2026-08-05 drafts (`ADC-Precon-Workshop-MMCA.md`, `ADC-Precon-Workshop-ClaudeCode.md`)
as the combined, framework-neutral version: no MMCA packages, templates, or branding anywhere
attendee-facing. Everything is built from a blank `dotnet new` solution with plain .NET 10.

## Title

**Build a Modular Monolith with an AI Pair: DDD, Clean Architecture, and Claude Code on .NET 10**

Alternative: *Architecture First, AI Fast: A Hands-On Day of Modular Monoliths and Agentic Development*

## Thesis (the one-sentence pitch)

Good architecture and agentic AI tooling are multipliers of each other: clear boundaries,
explicit rules, and executable fitness tests are exactly what make an AI coding agent effective,
and the agent is what makes the ceremony of a well-layered system cheap enough to actually build.
The day teaches both at once by building one system with both.

## Attendee-facing abstract (for the conference submission)

Microservices promised independent teams and independent scaling, and delivered distributed
debugging, flaky integration environments, and a network hop inside every business transaction.
The industry answer is now clear: start with a well-modularized monolith and extract services
only when something real (team size, scaling, isolation) forces it. Meanwhile, AI coding
assistants went from autocomplete to agents that read, plan, edit, and run tests, and most
teams still use them like a fancy search box.

This hands-on workshop teaches both, together, because they reinforce each other. Starting
from an empty solution, you will build a modular monolith on .NET 10 with an AI pair
(Claude Code) doing the heavy lifting while you make the architectural decisions: rich domain
models whose factory methods return results instead of throwing, a hand-rolled CQRS pipeline
that gives you validation and logging for free (no frameworks, you will see every line),
reliable messaging via the outbox pattern, and architecture fitness tests that fail the build
when someone (human or AI) violates a layer rule. Along the way you learn the agentic
workflow that makes it fast: project context files, plan-first prompting, test-driven loops,
hooks that make dangerous operations impossible, and reviewing AI diffs like a reviewer
instead of rubber-stamping.

The finale keeps the morning's promise twice over: we take a module and run it as its own
service behind a YARP gateway with no rewrite, and we let the fitness tests catch the AI
breaking a rule, live.

You leave with a running solution you built yourself, a starter kit for your own repos
(context file template, example hooks, a custom command), and the habits to use an AI agent
on production code without losing engineering discipline.

**Audience:** intermediate .NET developers, tech leads, and architects. The AI content is
stack-agnostic; the labs are .NET.
**Format:** roughly half lecture, half guided labs on your own laptop.

## Prerequisites (send to attendees ahead of time)

- .NET 10 SDK
- Docker Desktop (SQL Server runs as a container; nothing to install)
- Claude Code installed (CLI or the VS Code / JetBrains extension) and signed in; a Claude
  subscription (Pro or Max) or an API key lets you follow the labs with the AI pair.
  Attendees who cannot or will not use Claude Code can still do every lab by hand; each lab
  handout includes the manual path. The architecture is the curriculum; the AI is the
  accelerator.
- Git and an IDE of choice (VS, Rider, VS Code)
- Setup clinic 8:15-9:00 for anyone who skipped the homework.

## Agenda (9:00-5:00)

### 9:00-9:45: Why modular monoliths won, and what AI changes (Session 1, lecture)

The microservices hangover; the monolith-first path; what "extractable" actually requires
(module boundaries, database-per-module from day one, contracts between modules, outbox).
Then the day's second thread: what an agentic coding tool actually is (an agent with tools in
a loop: read, search, edit, run, test), and why architecture discipline is precisely what
makes it effective: an agent is a very fast new hire, and it onboards off the same things
humans do (conventions, boundaries, executable rules). The day's map: one system, built with
both.

### 9:45-10:30: Zero to walking skeleton, AI-assisted (Lab 1)

Attendees create the blank solution and let the agent scaffold the layer skeleton from a
written spec: Domain, Application, Infrastructure, Presentation projects for a `Tickets`
module, wired with project references that enforce the dependency rule. First agentic lessons
land here: write the context file (CLAUDE.md) BEFORE the first prompt (build commands,
conventions, layer rules), use plan mode, and read the plan before approving it. Build green
by 10:30 with zero business logic: a walking skeleton.

### 10:30-10:45: Break

### 10:45-12:00: The domain layer: making illegal states unrepresentable (Session 2 + Lab 2)

DDD building blocks taught straight: aggregates, factory methods returning `Result<T>`
instead of throwing (hand-rolled Result type, about 40 lines, no library), value objects,
domain events raised inside the aggregate. Lab: implement the Ticket aggregate with real
business rules ("cannot close a ticket with open child tasks") test-first: attendees write
the failing unit test themselves, then let the agent make it pass, then review the diff.
Teaching beats: the domain project has zero package references; tests need no infrastructure;
the agent is dramatically better at this when the test comes first.

### 12:00-1:00: Lunch

### 1:00-2:15: CQRS by hand, and the decorator pipeline (Session 3 + Lab 3)

Commands vs queries; `ICommandHandler<T>` / `IQueryHandler<T>` as two interfaces you own; the
decorator pattern to layer validation and logging around every handler with no framework
magic (registration is a dozen lines of DI). Lab: add a complete vertical slice (endpoint,
command, handler, validator, EF persistence) with the agent doing the ceremony from one
well-written prompt, then a second slice where attendees write the prompt themselves. The
payoff moment: the second slice takes eight minutes, and every line of the pipeline is code
they read an hour earlier.

### 2:15-3:00: Events and the outbox: reliable messaging without distributed transactions (Session 4)

The two event paths (domain events dispatched in-process at save time, integration events
written to an outbox table in the same transaction), why dual writes fail, and the relay that
publishes with at-least-once semantics. Mostly demo rather than lab: kill the process
mid-operation and show the outbox replay on restart. This session separates the workshop from
every "intro to clean architecture" talk.

### 3:00-3:15: Break

### 3:15-4:00: Fitness tests: rules that bind humans AND the AI (Session 5 + Lab 4)

Architecture fitness tests as an executable ruleset (NetArchTest or ArchUnitNET): the domain
references nothing, handlers are internal, no module reaches into another module's internals.
Lab: attendees describe their layer rules in plain English and have the agent write the
fitness tests, then flip it: ask the agent to violate a rule and watch the build fail. The
day's thesis lands here: the same tests that stop a rushed human stop a confidently wrong
agent, which is what makes delegation safe. Bridge into guardrails on the tool side: the
permission model, and hooks that hard-deny dangerous commands or force a confirmation before
a deploy (shown as case studies, not a lab).

### 4:00-4:40: The payoff: second module and extraction (Session 6, demo)

Add a second module and show module discovery, module-to-module communication via contracts
only, and database-per-module inside one process. Headline demo: lift the Tickets module out
and run it as its own service behind a YARP gateway with no rewrite: the promise from 9am,
kept. Close the AI thread at scale: what a mature setup looks like (custom slash commands for
repeated workflows, specialized subagents, AI code review in CI), demoed briefly on the day's
codebase.

### 4:40-5:00: Failure gallery, team adoption, wrap (Session 7)

The candor session: real examples of plausible-but-wrong agent output (phantom fixes, claimed
green tests that never ran) and the verification habits that catch them; what to check into
the repo (`.claude/` as shared team infrastructure, exactly like `.editorconfig`); rules of
thumb for what to delegate vs keep. Take-home: the day's solution as a public repo with
snapshot branches per lab, plus a starter kit (context file template, two example hooks, one
custom command).
