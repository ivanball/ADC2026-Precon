# ADC 2026 Precon: Instructor Kit (agenda v3.1)

Materials for teaching the full-day workshop **"Build an AI-Ready .NET App with an AI Pair:
Clean Architecture, MCP, and Agentic Workflows"**. Tagline: one day, the whole SDLC with an AI
pair. Friday October 16, 2026 at Improving (Alpharetta): setup clinic 8:15, sessions 9:00-5:00.
Agenda source of truth: `./ADC-Precon-Workshop-2026-v2-agenda.md` (v3.1, approved 2026-09-16;
the v2 filename is historical). The original proposal `./ADC-Precon-Workshop-2026.md` is
superseded and kept for history.

Hard rule carried through every file: **framework-neutral**. No internal framework packages,
templates, repo names, or docs links appear in anything attendees see. All code is hand-rolled
from a blank solution. The field report in S9 may say "my open-source .NET framework and the two
production apps built on it" and nothing more specific.

## File map

| File | Block | Time |
|------|-------|------|
| `01-s1-sdlc-with-an-ai-pair.md` | S1: the SDLC with an AI pair (Map) | 9:00-9:15 |
| `02-lab1-spec-driven-skeleton.md` | Lab 1: spec-driven walking skeleton (Plan) | 9:15-10:05 |
| `03-lab2-domain-layer.md` | Lab 2: domain layer, Result, aggregates, test-first (Design + build) | 10:20-11:10 |
| `04-lab3-cqrs-slices.md` | Lab 3: CQRS by hand, `/slice` skill, API test first, outbox mention (Build + test) | 11:10-12:05 |
| `05-lab4-fitness-tests-guardrails.md` | Lab 4: fitness tests, THE FLIP, hooks, permission modes, tokens (Verify) | 12:50-1:30 |
| `06-lab5-ship-it.md` | Lab 5: public repo, agent-authored CI, red PR, release image (Review + integrate + release) | 1:30-2:15 |
| `07-lab6-run-it.md` | Lab 6: Aspire AppHost, dashboard, health gates, Aspire MCP loop, deploy demo (Deploy + operate) | 2:15-2:45 |
| `08-lab7-mcp-server.md` | Lab 7: the module as an in-app MCP server, injection demo (Extend) | 3:00-3:55 |
| `09-lab8-evals.md` | Lab 8: evals, the agent as judge, scorer + verifier (Govern) | 3:55-4:20 |
| `10-s9-field-report-and-wrap.md` | S9: field report + wrap with the extraction clip (Maintain + improve) | 4:20-5:00 |
| `11-starter-kit.md` | The take-home kit: contents, provenance, S9 walkthrough, publishing checklist | n/a |

Each run sheet has the same shape: **Goal / You need / Files this session touches /
Minute-by-minute / Talking points / Code + prompts / Transitions / If things go wrong**. Every
code fence that shows repo content carries a `File:` label verified against the branch it
targets (see Verification below).

The three run sheets for blocks the v3 agenda dropped (outbox session, extraction finale,
failure gallery) are not in this repo; their teaching content was folded into Lab 3, the wrap,
and S9.

## Built assets (2026-09-20)

| Asset | Location |
|-------|----------|
| Reference solution (published 2026-10-07, public, all 13 branches, no tags; commit authors rewritten to the GitHub noreply address before the first push; all local backup tags deleted afterwards, so no `pre-*` rollback tags remain) | `C:\Projects\MMCA\Workshops\ADC2026\helpdesk`, origin <https://github.com/ivanball/adc2026-helpdesk> |
| Snapshot branch chain | `lab1-end` -> `lab2-end` -> `lab3-end` -> `lab4-end` -> `lab5-end` -> `lab6-end` -> `lab7-end` -> `main` (17 tests, 6 layer rules); demo branches `lab5-violation`, `lab6-fault`, `lab8-demo`; historical `session4-end`, `session6-end`; `docs/branches.md` on `main` lists them all |
| Starter kit repo (30 files; published 2026-10-07, public, MIT, `main` only, commit authors rewritten to the GitHub noreply address before the first push; backup tag deleted afterwards) | `C:\Projects\MMCA\Workshops\ADC2026\agentic-dotnet-starter-kit`, origin <https://github.com/ivanball/agentic-dotnet-starter-kit> |
| Lab handouts 1-8 (printable, AI + manual paths) | `handouts/lab1.md` .. `lab8.md` |
| Slide deck (100 slides, v3.3 2026-10-06, SOLID mapping slide added in Lab 3, break and lunch slides added 2026-10-11 (each arms its countdown on `T`), self-contained HTML, works offline, letterboxed 16:9 stage) with speaker notes on every slide. Visuals: 3D cube turn between blocks, depth push inside a block, flip-in reveals, extruded lab numerals and an isometric layer stack on title cards, syntax-coloured code panels; `M` toggles motion off (also honors the OS reduced-motion setting), `?static` in the URL starts with motion off. Keys: `S` speaker view in a second window (MUST SAY, ENGAGE, cues, next slide, block pacing against the agenda clock), `N` notes overlay for single-screen rehearsal, `T` lab timer (arms from the slide's minutes; `Shift+T` resets, `+`/`-` a minute), `B` blackout, `G` number `Enter` jump, `?` help; add `?reveal` to the URL to show every build step at once. Earlier versions (v3.1, v3.2) are not in this repo | `slides/adc2026-precon-slides.html` |
| Attendee email with the embedded setup scripts | `comms/attendee-email.md` |
| Workshop A welcome email (draft v2, 2026-10-10; attach both setup checkers) | `comms/welcome-email-workshop-a-2026-10-10.md` |
| Mac and Windows setup addendum email (draft, 2026-10-12; send only if the welcome email already went out, after the starter kit's `fix/mac-and-windows-setup-checks` branch is merged) | `comms/os-setup-addendum-email-2026-10-12.md` |
| Setup checker (SDK, Docker, SQL image, port 14330, port 5000, HTTPS dev certificate, EF tools, Git, gh, gh signed in, Aspire CLI with agent commands, Aspire templates, Node, IDE, Claude Code optional; Windows adds Git Bash, 16 checks; macOS adds zsh interactivecomments and, on Apple Silicon, Rosetta 2, up to 17; the macOS port-5000 hint names AirPlay Receiver). Mirrored in the starter kit under setup/ | `comms/check-setup.ps1`, `comms/check-setup.sh` |
| Listing copy (the atldevcon.com page) | `comms/listing-v3-site-page.md` |
| Organizer logistics, TA briefing | `comms/organizer-logistics.md`, `comms/ta-briefing.md` |

Still on the instructor (the Aspire CLI on this machine is 13.6.0 as of 2026-10-06, so that
item is done): the `aspire run` and MCP Inspector rehearsal, commit and merge the starter kit's
`fix/author-name-and-aspire-version` branch, set the `ANTHROPIC_API_KEY`
secret and branch protection on the public reference repo and pre-open the `lab5-violation`
pull request, record the three-terminal extraction clip for the wrap, USB sticks, and the
workshop-credits conversation. The Lab 6 deploy has no recording: it is talked through, or run
live only if kicked off before the lab (about 16 min; `07-lab6-run-it.md`, Step 5).

## The day's system (one paragraph)

Attendees build `Helpdesk`, a ticketing system: one `Tickets` module through four layers
(Domain, Application, Infrastructure, Presentation) plus a Host, a hand-rolled `Result<T>`,
hand-rolled CQRS with validation and logging decorators, an API-level integration test against
the SQL container, and architecture fitness tests with agent guardrails. In the afternoon they
ship it (public repo, agent-authored CI with lock files and audit mode, a red-then-green pull
request, a tagged container release), run it (an Aspire AppHost with liveness and readiness
gates, and an agent that reads live telemetry to fix a planted fault), extend it (the module as
an MCP server hosted in the app, with a prompt-injection attempt bounded by a minimal tool
surface and the domain rules), and grade it (a five-rule rubric scored by one agent, attacked by
another, and adjudicated by a human). The `main`
branch adds the outbox and a `Notifications` module behind a gateway for the recorded extraction
clip that closes the day. An AI coding agent drives the ceremony in every lab; attendees make
the decisions and review the diffs, and every lab has a manual path.

## Prep checklist

### T-4 weeks

- [ ] Rehearse every lab from its run sheet against the snapshot branches; the branch chain is
      already built and green (`docs/branches.md` on `main`).
- [ ] Run `comms/check-setup.ps1` on the projector machine until every line is OK (the Aspire
      CLI there must be 13.6+; this machine is on 13.6.0 since 2026-10-06).
- [ ] On the public reference repo (github.com/ivanball/adc2026-helpdesk, published
      2026-10-07): turn on branch protection per `docs/shipping.md`, add the `ANTHROPIC_API_KEY`
      secret, and open the `lab5-violation` pull request so it is waiting on the day.
- [x] Push the starter kit public and replace the `<workshop repo link: TODO before the
      conference>` placeholder in its README. The wrap slide links it; the link must work day-of.
      Done 2026-10-07: kit at github.com/ivanball/agentic-dotnet-starter-kit, link filled in
      `e1cfc6d`, pointing at github.com/ivanball/adc2026-helpdesk.
- [ ] Record the three-minute extraction clip (`10-s9-field-report-and-wrap.md`, wrap beat;
      commands in `main`'s README). The Lab 6 deploy is not recorded.
- [x] Optional: validate `aspire deploy` once on your own subscription (`07-lab6-run-it.md`,
      Step 5, "Optional: validate"), on a scratch branch and into a NEW resource group (the
      prompt suggests existing ones; never accept one). About 16 min to deploy and about 19 to
      delete; `az group delete` only on that dedicated group. Validated 2026-10-11.
- [ ] Confirm the conference listing matches `comms/listing-v3-site-page.md` (prerequisites, Claude
      subscription as nice to have, public GitHub repo, Aspire CLI, Node). Ask about workshop
      credits for stragglers as an accelerator, not a requirement.

### T-1 week

- [ ] Rehearse the full day once against a stopwatch. Cut order if behind: the Lab 6 deploy
      shrinks to one sentence first, then the S9 worktree demo, then the S9 waves segment. Never cut
      THE FLIP (Lab 4), the verifier run (Lab 8), the write-a-skill mini-lab, or the wrap.
- [ ] Prepare the offline NuGet cache: on a clean machine, restore the reference solution on
      `main`, then zip the global packages folder (`~/.nuget/packages`). Copy to two USB sticks.
      Attendees can point `NUGET_PACKAGES` at it if the wifi dies.
- [ ] Pre-pull and export the SQL image for the sticks too:
      `docker pull mcr.microsoft.com/mssql/server:2022-latest` then `docker save -o sql2022.tar ...`.
      Pre-cache `npx @modelcontextprotocol/inspector@latest` on the projector machine.
- [ ] Cut the Lab 8 demo branch on the projector clone: `lab8-demo` must be `main` plus the
      public `CloseTicketHandler` AND the three Lab 8 step 1 files (`evals/rubric.md`, both
      agents). The published `lab8-demo` has the planted change but not the three files, so
      run step 1 on it after checking it out (`09-lab8-evals.md`, You need). Keep the verifier
      prompt's five claims as placeholders, filled from the live scorer run.
- [ ] Print the eight handouts (each is written to be printable standalone, AI path and manual
      path both).
- [ ] Brief your TA / room helper from `comms/ta-briefing.md`: floating during labs, pacing the
      manual-path attendees, the rescue branches.

### Day-of (8:00)

- [ ] Room: projector mirrors your terminal + IDE, font cranked to 18pt+, light theme for
      projection.
- [ ] Your machine: Docker running, compose SQL container up on 14330, reference repo cloned
      twice (one clean on `lab1-end` for live-coding, one on `main` as the safety net), the
      extraction clip on the desktop, phone hotspot tested as wifi fallback, `gh` signed in, the Aspire
      MCP config in place.
- [ ] Claude Code signed in, `/clear` run, started with `claude --permission-mode default`
      (attendees should see the permission prompts; that IS part of the teaching). Since
      v2.1.283 a fresh session starts in auto mode, so the flag is required, and the S1 "How
      today works" slide tells the room the same. That holds for Labs 1-3; from Lab 4 on, once
      `.claude/settings.json` is in the repo, start plain `claude` so its
      `defaultMode: acceptEdits` applies (a CLI `--permission-mode` flag overrides it).
- [ ] 8:15-9:00 setup clinic: attendees run
      `powershell -NoProfile -ExecutionPolicy Bypass -File .\check-setup.ps1` (Windows; a plain
      `.\check-setup.ps1` is refused under the default execution policy) or `bash check-setup.sh`, then
      `docker compose up -d`. Anyone still broken at 9:00 pairs with a neighbor until the break.

## Timing summary (wall clock)

```
8:15  Setup clinic
9:00  S1   The SDLC with an AI pair (15)
9:15  L1   Spec-driven walking skeleton (50)
10:05 ---  Break
10:20 L2   Domain layer, test-first (50)
11:10 L3   CQRS, /slice skill, API test first, outbox mention (55)
12:05 ---  Lunch
12:50 L4   Fitness tests, THE FLIP, guardrails (40)
1:30  L5   Ship it (45)
2:15  L6   Run it (30)
2:45  ---  Break
3:00  L7   The module as an MCP server (55)
3:55  L8   Evals, the agent as judge (25)
4:20  S9   Field report (35)
4:55  Wrap Extraction clip, branches, goodbye (5)
5:00  End
```

Rule of thumb while teaching: if a segment is 5+ minutes over at its midpoint, take the cut
list above immediately rather than compressing the wrap.

## Verification

Every run sheet and handout passes the fence-label checker (every `File:` label names a path
that exists on the branch in the file's "Snapshot branch" line; `kit:` labels resolve against the
starter kit):

```
pwsh -NoProfile -File C:\Projects\MMCA\Tools\Scripts\check-fence-labels.ps1 -Path <file>
```

Branding gate over everything attendee-facing (run from this folder; must print nothing and
exit 1). The root `.md` files are instructor-only and name the framework by design, so they
are not in scope:

```
grep -r -i -E "mmca|ivanball" --exclude-dir=_backup handouts comms slides
```
