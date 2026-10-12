# Workshop A welcome email (draft v2, 2026-10-10)

Built from `attendee-email.md` (setup content unchanged from the 2026-10-07 dry-run version)
and `listing-v3-site-page.md` (agenda times and block content).
Recipients from `Personal/Conferences/attendees_report_20261010_181914.csv`.

**Attach:** `check-setup.ps1` and `check-setup.sh` (this folder; not published in either repo).

---

**Subject:** You're in! Friday we build, ship and run a .NET 10 app with an AI pair (setup inside)

Hi everyone,

Welcome aboard, and thank you for signing up for my precon workshop at the Atlanta
Developers' Conference 2026. I'm Ivan Ball-llovera, and I'll be your instructor on Friday.

AI agents can already write code faster than any of us. The question that matters now is
whether they write **your** code: the architecture you chose, the rules your team agreed
on, and the tests that prove it. Friday is a full, hands-on day answering that question,
with Claude Code as your pair and you making the decisions.

We are a small group, which is great news for you: plenty of one-on-one help, and time to
dig into the problems you bring from your own codebase.

## By 5 PM, you will have...

- **Started from a spec, not a prompt.** Context files, a written spec and plan mode come
  first, then the agent scaffolds a modular .NET 10 solution and you review it like a lead.
- **Built the core test-first, with nothing hidden.** A rich domain model where illegal
  states cannot exist, and a hand-rolled CQRS pipeline with no frameworks, so you see every line.
- **Watched the AI break your architecture, and the build catch it.** Fitness tests, hooks
  and deny rules that bind humans and agents alike.
- **Shipped through real gates.** Agent-written CI, branch protection, a pull request that
  goes red on a layer violation and green after the fix, and a tagged release that
  publishes a container image.
- **Let the agent debug from live telemetry.** It reads Aspire traces, finds a planted bug,
  fixes it, and proves the fix.
- **Turned your app into an MCP server.** Drive it in plain English from Claude Code or
  VS Code, then watch your domain rules stop a prompt-injection attack.
- **Put the AI on trial.** One agent scores your architecture with file-and-line evidence,
  and a second agent tries to disprove every score.

You also take home a starter kit (context-file templates, skills, agents, eval rubric) and
a snapshot branch for every lab, so you can replay the whole day on your own.

## The agenda

**Friday, October 16, 2026, at Improving, 11675 Rainwater Dr #100, Alpharetta, GA 30009**

| Time | Block | What happens |
|---|---|---|
| 8:15-9:00 | Setup clinic | Last-minute install help and a smoke test |
| 9:00-9:15 | Map | The software lifecycle with an AI pair |
| 9:15-10:05 | Lab 1: Plan | Spec-driven walking skeleton: context files, spec, plan mode, scaffold |
| 10:05-10:20 | Break | |
| 10:20-11:10 | Lab 2: Design and build | The domain layer, test-first: making illegal states unrepresentable |
| 11:10-12:05 | Lab 3: Build and test | CQRS by hand, the decorator pipeline, slices from an Agent Skill, an API test against real SQL |
| 12:05-12:50 | Lunch | |
| 12:50-1:30 | Lab 4: Verify | Fitness tests and guardrails: ask the agent to break a rule, watch the build fail |
| 1:30-2:15 | Lab 5: Ship it | GitHub, agent-written CI, branch protection, red-to-green PR, tagged release |
| 2:15-2:45 | Lab 6: Run it | Aspire dashboard, then the agent finds and fixes a bug from live traces |
| 2:45-3:00 | Break | |
| 3:00-3:55 | Lab 7: Extend | Your app as an MCP server, and a prompt-injection attack it shuts down |
| 3:55-4:20 | Lab 8: Govern | Evals for architecture: the agent as judge, a second agent as skeptic |
| 4:20-4:55 | Field report | A year of production work with Claude Code: what the agent caught, what it missed, what it costs in tokens, plus a write-your-own-skill mini-lab |
| 4:55-5:00 | Wrap | |

## Your pre-flight checklist (about 30 minutes, best done before this Friday)

The workshop is hands-on from 9:15, so please install and verify everything below BEFORE
you arrive.

### Install

1. **.NET 10 SDK**: https://dotnet.microsoft.com/download
2. **Docker Desktop** (SQL Server runs as a container; you will not install SQL itself):
   https://www.docker.com/products/docker-desktop/
   If your company does not license Docker Desktop, another engine that provides the `docker`
   and `docker compose` commands may work (we have not tested every one): the check script
   below must report OK. On an Apple Silicon Mac, install Rosetta 2
   (`softwareupdate --install-rosetta`) and turn on Docker Desktop's Rosetta x86/amd64
   emulation setting: the SQL Server image is amd64 only.
3. **EF Core tools**: `dotnet tool install --global dotnet-ef`
4. **Git**, plus the **GitHub CLI** signed in (`gh auth login`): https://cli.github.com
   On Windows that means **Git for Windows**, which includes **Git Bash**: run the day's
   terminal commands there (Command Prompt cannot run them, PowerShell runs most of them).
5. A **GitHub account**. The repo you push in the afternoon will be PUBLIC, because
   branch protection with required checks is only free on public repositories.
6. **Aspire CLI 13.6 or newer and the Aspire templates**: install the CLI following the
   instructions on aspire.dev, then `dotnet new install Aspire.ProjectTemplates`
7. **Node.js 22.19 or newer (Node 24 LTS recommended)**: https://nodejs.org (we run the MCP
   Inspector with `npx @modelcontextprotocol/inspector@latest`, which requires 22.19)
8. An IDE you like (Visual Studio, Rider, or VS Code)
9. **Claude Code** (CLI, or the VS Code / JetBrains extension), signed in. Nice to have,
   see below. Install it following the instructions on claude.com/claude-code.

### One-time settings for your OS (2 minutes)

The day's terminal commands are printed once, for bash, and run as printed on both a Mac and
a Windows laptop with these settings:

- **Both:** trust the HTTPS development certificate, `dotnet dev-certs https --trust`
  (Windows shows a security dialog: answer Yes; macOS asks for your login password). The
  Lab 6 dashboard runs on `https://localhost`.
- **Windows:** run the day's commands in **Git Bash** (it comes with Git for Windows; open it
  from the Start menu, or pick it as a Windows Terminal or VS Code terminal profile).
- **macOS:** the stock Terminal (zsh) is fine, with two settings. Some commands end in a
  `# comment`, which zsh passes to the command as arguments unless you run
  `echo 'setopt interactivecomments' >> ~/.zshrc` once and open a new terminal. And port
  5000, the port the workshop API uses, belongs to AirPlay Receiver on a Mac: turn it off in
  System Settings > General > AirDrop & Handoff > AirPlay Receiver. If `dotnet ef` says
  "command not found" after you installed it, run
  `echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile` and open a new terminal.

### Pre-pull the database image (5 minutes, saves the room's wifi)

```
docker pull mcr.microsoft.com/mssql/server:2022-latest
```

### Clone two repos

Clone both into the folder where you will build the day's repository, so they sit side by
side with it:

- The workshop reference repo (public). It holds a snapshot (rescue) branch for every lab
  (`lab1-end` to `lab7-end`, plus `main`), so if you fall behind you can jump to the
  current lab's branch:

  ```
  git clone https://github.com/ivanball/adc2026-helpdesk.git
  ```

- The starter kit. It has the take-home templates and the source of three
  files Lab 8 copies into your repository:

  ```
  git clone https://github.com/ivanball/agentic-dotnet-starter-kit.git
  ```

### Verify (2 minutes)

From the root of the starter kit you just cloned, run the setup checker and make sure every
line says OK:

- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .\setup\check-setup.ps1`
- macOS/Linux: `bash setup/check-setup.sh`

Stuck? Reply to this email, or come to the **setup clinic at 8:15** (we start at 9:00
sharp) and we will sort it out together.

## Claude Code access: nice to have, not a prerequisite

The AI-pair parts of the labs move faster with a **Claude Pro, Max, Team or Enterprise
plan, or an Anthropic Console (API) account** (the free claude.ai plan does not include
Claude Code). Set one up if you can. If you can't, you won't miss anything: every lab
handout has a manual path with the same end state, the MCP lab works with the free MCP
Inspector or VS Code, and the evals lab has a follow-along path. The architecture is the
curriculum, and the AI is the accelerator.

## What to bring

Your laptop and charger. That's it: we build the day's
system from an empty folder, and there is no required reading.

## A quick favor

Hit reply and tell me (1) your OS, (2) whether you'll have Claude Code access on the day,
and (3) the one thing you most want to walk away with. I'll use your answers to tune the
day for this group.

See you Friday. Bring your toughest questions about working with AI on real codebases.

Ivan Ball-llovera
https://ivanball.github.io/
