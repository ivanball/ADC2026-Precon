# Mac dry run, 2026-10-12

Every lab ran on macOS for the first time, and every lab passes on the current branches. The
one blocker, the Claude Code sandbox, was fixed during the run by removing it from the kit and
every rescue branch. Machine: MacBook Apple Silicon, macOS 26.7.1, stock zsh, .NET SDK 10.0.401,
Aspire CLI 13.6.1, Node 24.21, Docker Desktop (SQL Server 2022 amd64 image under Rosetta),
Claude Code 2.1.296. All 17 `check-setup.sh` checks passed before the run.

Method as on Windows (`DRYRUN-2026-10-07.md`): each lab from the previous lab's rescue branch,
once on the manual path (every handout block pasted as printed into an interactive zsh) and
once on the AI path (every handout prompt sent verbatim to headless Claude Code, Sonnet). Lab 5
ran for real on private throwaway GitHub repos; the Lab 6 Azure deploy was skipped by decision
(validated 2026-10-11). Raw evidence: `~/dr-mac/labN/RESULT.md` and `~/dr-mac/labN/evidence/`.

## Results by lab

| Lab | Manual | AI path | What the run proved or broke |
|---|---|---|---|
| 1 | PASS w/ findings | PASS w/ findings | 8-project slnx, 2/2 green, `/health` 200; SQL ready ~6 s under Rosetta |
| 2 | PASS | PASS | CS1061 red, then 4+1 green; CS1519 and CS0103 traps reproduce |
| 3 | PASS w/ findings | PASS w/ findings | 201/400, red 404 then 7 green; `ef database update` fails if SQL just started |
| 4 | PASS w/ findings | PASS w/ findings | 11 green; THE FLIP = build green, rules 1+2 red; hooks fire, `/usr/bin/jq` present |
| 5 | PASS w/ findings | PASS w/ findings | real CI green, red PR then green (~2m40s), tag published to GHCR; amd64 image runs with `--platform` |
| 6 | PASS w/ findings | PASS w/ findings * | 13 green, 2 designed reds; AI Step 1 69 s; closed loop 31.5 s, good fix |
| 7 | PASS w/ findings | PASS w/ findings | 16 green; curl/Inspector claims reproduce; injection demo as designed |
| 8 | PASS w/ findings | PASS w/ findings | scorer rule 3 = 0 at `CloseTicket.cs:9`; verifier finds the rule-5 gap |

\* Lab 6 AI path FAILED with the sandbox on (24 min, nothing compiled); it passes on the
sandbox-free branches. Labs 4, 5 and 8 ran on the old branches; their non-sandbox results
stand.

## Fixed during the run

- **Sandbox removed (was the BLOCKER).** macOS enforces the sandbox (Seatbelt), unlike native
  Windows. With it on, the agent's `dotnet build`/`dotnet test` hung ~5 min then
  `Build FAILED. 0 Warning(s) 0 Error(s)` (MSBuild pipe, `SocketException (13)`), and
  `dotnet restore`, `gh` and localhost curls were denied. `excludedCommands` did not cover
  piped or backgrounded commands. The `sandbox` block is gone from the Lab 4 handout, run
  sheet, slides, S9, starter-kit doc (kit commit `6fed322`), the starter kit (`721d61d`) and the
  eight rescue branches lab4-end .. main. Beat 3 now explains why it stays off.

## Still open (not fixed)

HIGH
1. **Trailing `# comments` break pasted commands in stock zsh** (interactivecomments off is the
   macOS default). Hits attendee commands in Lab 5 (watch/verify: `accepts at most 1 arg(s),
   received 6`), Lab 6 (`dotnet test ... # 2 red` at `handouts/lab6.md:501`, run sheet :640,
   :656: `MSB1008`, the red proof never shows), Lab 4 (`# only the three...` turns into git
   pathspecs and hides FLIP leftovers) and run sheets 03:460, 09:48. The setup check flags it,
   but anyone who skipped the fix breaks. Fix: move comments to their own line or prose.
2. **Lab 3 section D: `dotnet ef database update` right after `docker compose up -d`** fails
   with `pre-login handshake ... SocketException (22): Invalid argument` while SQL starts
   (~5 s under Rosetta). Fix: healthcheck + `docker compose up -d --wait`, or a "wait and rerun
   the update" line. Also the handout says rerun both ef commands; rerunning `migrations add`
   fails (`The name 'Initial' is used by an existing migration`).
3. **Lab 5 Step 1 fails for attendees on a rescue clone**: `origin` already exists,
   `X Unable to add remote "origin"`, nothing is pushed. Tested fix in `~/dr-mac/lab5/RESULT.md`.
4. **Lab 6 `aspire agent init` writes to the home folder** without the handout saying so: a
   PostToolUse hook in `~/.claude/settings.json` (runs `~/.aspire/hooks/track-telemetry.sh`
   after every tool call in every session), `~/.agents/skills` (7 skills), `~/.aspire/hooks`.
5. **Hooks silently skip when the repo path has a space** (any OS): `$CLAUDE_PROJECT_DIR` is
   unquoted in the handout, run sheet and branches; the starter kit already quotes it.

LOW (selected; full lists in each RESULT.md)
- `docker compose up -d` prints an amd64/arm64 platform warning every time (harmless).
- `dotnet new web` writes CRLF on Mac; attendee diffs differ from `lab1-end` line by line.
- No handout gives the command to switch to a rescue branch; `git checkout lab1-end` then
  committing leaves work on a branch named `lab1-end`.
- Handout CLAUDE.md/AGENTS.md have a `## Git` section the branches lack.
- Fresh rescue clones need `dotnet tool restore` before `dotnet ef` (dotnet-ef 10.0.10 pinned).
- Lab 7: Q3 needs a second approval for `close_ticket`; default-scope `claude mcp add` writes
  `~/.claude.json`; Inspector `@latest` is now 2.10.1.
- Lab 8: this Claude Code build has no Glob/Grep tools, so the scorer/verifier fall back to
  Bash (they still finish); agent-written `grep --include=*.cs` hits zsh `no matches found`.
- zsh prints `%` after curl JSON bodies without a trailing newline.

## Not exercised
Interactive Claude Code UI (trust dialog, plan approval, Shift+Tab, permission prompts, startup
banner): all runs were headless, which also ignores `permissions.allow` until the folder is
trusted. AirPlay Receiver on port 5000 (off on this Mac; a busy port was simulated and gave the
handout's error). Keychain prompt for the dev cert (already trusted). Lab 5 agent-review
workflow (needs the `ANTHROPIC_API_KEY` secret). Lab 8 neighbour swap. Azure deploy.

## Cleanup
- GitHub (private): repos `ivanball/helpdesk-dryrun-mac-1012` and `-1012-ai`; packages
  `ghcr.io/ivanball/helpdesk-dryrun-mac-1012` and `-1012-ai`.
- `~/.claude/settings.json`: remove the `"hooks"` block the Lab 6 run's `aspire agent init`
  added; optionally delete `~/.agents/skills` and `~/.aspire/hooks`.
- Local: `~/dr-mac/` (evidence; delete when done). No containers, volumes or listeners remain.
