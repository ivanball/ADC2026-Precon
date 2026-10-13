# Lab 5 (1:30-2:15): Ship it

**Type:** framing (4 min) + six lab steps and an instructor demo (38 min) + debrief and hand-off (3 min).
**Phase:** review + integrate + release. This is the block where the repository stops being a
folder on a laptop and becomes a project with gates.
**Goal:** every attendee ends the block with a PUBLIC repository whose `main` is protected by a
required check, an agent-authored CI workflow that restores in locked mode and runs build plus
three test tiers against a real SQL Server, one pull request that went red on a fitness test
and green on a fix, and a container image published to the GitHub container registry from a
tag. Payoff line: "the gate you wrote at lunchtime just rejected a pull request while you
watched, and nobody had to remember the rule." Snapshot branch: `lab5-end`.

**You need:** your PUBLIC reference repository already created, already pushed, protection
already on, the `ANTHROPIC_API_KEY` repository secret already set, and `agent-review.yml`
already merged to `main` BEFORE the demo pull request is opened (on the pull request that adds
the file, the action skips with a warning instead of reviewing), because none of that is
worth doing live. A pull request pre-opened on it from the `lab5-violation` content, left red,
never merged: that is the wifi fallback and the queue-time fallback both. `gh` signed in on the
projector machine (`gh auth status` before the room comes back, not during the block). Docker
Desktop running, since step 6 ends with `docker run`. The handout carries every command, so
nobody is transcribing from the screen.

**Room note:** this block depends on the internet twice, once for Actions and once for the
registry. Red-to-green on a public repository is about three minutes of queue plus run. Plan
the talking points AROUND that wait rather than staring at it: the supply-chain beat and the
least-privilege beat both fit inside one CI run.

## Rescue: starting from the snapshot (the handout prints this under its snapshot line)

**Starting from the snapshot instead of your own work?** Clone it into a new folder and make
it your `main` (a plain `git checkout lab4-end` leaves your next commits on a branch named
`lab4-end`):

```sh
git clone --branch lab4-end https://github.com/ivanball/adc2026-helpdesk.git helpdesk-lab5
cd helpdesk-lab5
git switch -c main --track origin/lab4-end
dotnet tool restore
```

`dotnet tool restore` installs the `dotnet ef` version the snapshot pins. From `lab3-end` on,
the repository carries a tool manifest, and `dotnet ef` refuses to run until it is restored,
even with the global tool installed.

## Minute-by-minute

| Time | Beat | Min |
|------|------|-----|
| 1:30 | Framing: why public, what a required check is, lock files + audit mode | 4 |
| 1:34 | Steps 1-2 solo: push to a public repository, protect `main` | 8 |
| 1:42 | Step 3 solo: the agent writes `ci.yml`; lock files and audit mode land with it | 8 |
| 1:50 | Step 4 solo: the pull request that breaks a rule. Red, fix, green, close | 10 |
| 2:00 | Instructor demo (no step number): agent code review as an advisory check on the reference repository | 5 |
| 2:05 | Steps 5-6 solo: release workflow, squash merge, tag `v0.1.0`, pull the image, run it | 7 |
| 2:12 | Debrief: the day's SDLC map, and hand off to Lab 6 | 3 |
| 2:15 | Lab 6: Run it | |

## Files this session touches

Everything the branch `lab5-end` adds on top of `lab4-end`, and nothing else in the repository
changes during this block. `git diff --stat lab4-end lab5-end` = 19 files, 2330 insertions, 0
deletions. Bold **manual path** citations mark content needed only by attendees not using an
agent; on the AI path the agent writes the two workflows from the prompts below.

| File | Change | Content |
|------|--------|---------|
| `.github/workflows/ci.yml` | new (59 lines) | step 3 below (AI path = the prompt; **manual path** = paste it) + handout lab5, step 3 |
| `Directory.Build.props` | edit (+10 lines) | step 3 below, the supply-chain beat + handout lab5, step 3 |
| `packages.lock.json` in 9 projects | generated (1988 of the 2330 insertions are these nine files) | never pasted: `dotnet restore Helpdesk.slnx` writes them the moment `RestorePackagesWithLockFile` is true. Commit them |
| `CLAUDE.md` and `AGENTS.md` | edit | one identical `Ship:` line each, step 3 below |
| `docs/shipping.md` | new (151 lines) | the attendee procedure. It follows the handout step for step, including the two commits (the violation in step 4, the image files through a `ship-image` pull request in step 5) and closing the red pull request instead of merging it |
| `Dockerfile` | new (27 lines) | step 5 below + handout lab5, step 5 |
| `.dockerignore` | new (11 lines) | step 5 below + handout lab5, step 5 |
| `.github/workflows/release.yml` | new (36 lines) | step 5 below (AI path = the prompt; **manual path** = paste it) + handout lab5, step 5 |
| `.github/workflows/agent-review.yml` | new (44 lines) | the instructor demo below (no step number), instructor only |
| `.gitattributes` | edit (+2 lines) | `*.yml text eol=lf` and `Dockerfile text eol=lf`. One sentence: a workflow file that lands with CRLF is a file the runner reads differently from your editor, and the same trap that killed the Lab 4 hook scripts kills these |

Test count is unchanged from `lab4-end`: 11 green on `dotnet test` (Domain 4, Architecture 5,
Api 2). Nothing in this block adds a test; it adds the machine that runs the tests you already
have. The published image is about 103 MB compressed (a few hundred MB on disk), which is worth saying
out loud when it lands.

The two files on `lab5-violation` are NOT part of the 19: that branch exists only to be the
red pull request in step 4, and it changes exactly two files that already exist on `lab5-end`.

## Talking points (4 min framing, plus filler during the CI waits)

**The supply-chain beat.** Two properties and a commit. Lock files make restore deterministic:
`packages.lock.json` records the exact resolved graph, and `--locked-mode` in CI fails the
restore if anything resolves differently from what is committed, which turns "it worked on my
machine last Tuesday" into a build error with a name. `NuGetAudit`, with `NuGetAuditMode` set to
`all` and `NuGetAuditLevel` at `low`, raises NU1901-NU1904 on a known-vulnerable package, direct
or transitive, and because `TreatWarningsAsErrors` is already on (and CI passes `-warnaserror`),
that warning fails the BUILD instead of scrolling past where nobody reads it. The payoff shape:
bumping a package is now a VISIBLE DIFF in a lock file, reviewed like any other change, rather
than an invisible change in what the build downloads.

**Why the repository has to be public.** Branch protection is not on the free plan for private
repositories. That is the only reason today's repository is public, and be blunt about it: this
is a workshop helpdesk with no secrets in it. In a real private repository you pay for the plan
and the mechanics are identical.

**What a required check actually is.** A check is a status posted against a commit, named after
the JOB, not the step. `ci.yml` has one job, `build-and-test`, with three test steps inside it,
so there is exactly ONE context to require, not three. Say this BEFORE step 3: the agent
sometimes writes three jobs, and the JSON body on the handout names one context, so those
attendees end up with a gate full of holes unless they list all three.

**Least-privilege tokens, the promise from Lab 4 coming due.** Every workflow here declares its
own `permissions:` block rather than inheriting the default token. CI gets `contents: read`.
Release gets `contents: read` plus `packages: write`, because publishing an image is the one
thing it is for. Review gets `contents: read`, `pull-requests: write`, `id-token: write`. Each
token is minted for one run and dies with the job, and the model credential is a repository
secret referenced by name. No personal access token ever goes in a file, because a file gets
committed.

**What "agent-authored" means here.** The attendee writes the prompt, the agent writes the YAML,
the attendee READS THE DIFF and owns the result. The interesting part is not that a model can
produce a workflow file; it is that a workflow file is a small, checkable artifact with an
immediate red-or-green verdict, which is exactly the shape of work worth delegating. Compare it
with the domain model from this morning, which nobody should have delegated.

**What the red pull request teaches.** Two things, and the second lands harder. The fitness test
is the reviewer that never gets tired, never runs out of attention on file eleven, and never
approves something at 5pm on a Friday. And look at what the violation actually did: binding the
concrete handler instead of the interface means the request skips the validation and logging
decorators entirely. It compiles. It returns 201. A human skimming a two-file diff sees a type
name change and moves on; the test names the offender in one line.

## Push it public, protect main (8 min, attendee)

### Step 1: create the repository and push it

Everything runs from the repository root. `<owner>` is the attendee's GitHub account name in
LOWER CASE, because container registry names must be lower case and the same string is reused
in step 6. `git branch -M main` comes first: an attendee who skipped Lab 1's `-b main` has
`master` (Git for Windows ships `init.defaultBranch=master`), the snapshot branch is
`lab4-end`, and whatever gets pushed becomes the default branch, so the protection call on
`branches/main` would hit a branch that does not exist.

Say out loud: `<owner>` left in with its angle brackets is a file redirect and fails before
`gh` runs ("The system cannot find the file specified" in cmd.exe), and any repo name other
than `helpdesk` must be swapped into every later `<owner>/helpdesk` too.

Attendees who rescued by CLONING the workshop repo already have an `origin`: `gh repo create`
then prints `X Unable to add remote "origin"` and pushes nothing. `git branch -M main` over the
clone's `main` also leaves `main` tracking the workshop repo, so step 3's bare `git push` would
aim there. The handout gives them this first:

```sh
git remote rename origin workshop
git checkout -B main
git branch --unset-upstream
```

If they already hit the error, the empty repo exists and a rerun says "Name already exists":
the three lines, then `git remote add origin https://github.com/<owner>/helpdesk.git` and
`git push -u origin main`.

```sh
git branch -M main
gh repo create <owner>/helpdesk --public --source=. --remote=origin --push
```

### Step 2: protect main

Then protection. The body names the one check context from step 3, so the check does not exist
yet: that is fine and worth naming, because a required check that has never run simply blocks
the merge until it does.

The handout tells attendees to run this in Git Bash (Terminal on a Mac) from the repository
root, replace `<owner>`, and paste the whole block including the closing `JSON` line (a partial
paste leaves the shell waiting at a `>` prompt, `heredoc>` in a Mac's zsh, for the rest of the
heredoc; Ctrl+C and paste again).

```sh
gh api -X PUT repos/<owner>/helpdesk/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["build-and-test"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null
}
JSON
```

Then the check, from the handout word for word:

```sh
gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'
```

It prints `["build-and-test"]`; before the PUT, the same call answers "Branch not protected".

Read the four keys out loud while it runs. `strict: true` means a branch has to be up to date
with `main` before it merges, without which two pull requests that are each green can merge
into a red `main`. `enforce_admins: false` is why the attendee can still push `ci.yml` straight
to `main` in the next step: they are the admin, and the gate binds everybody else.
`required_pull_request_reviews: null` keeps them able to merge their own pull request, which
matters when they are the only person in the repository. `restrictions: null` is no push
allowlist. The whole procedure is checked in as `docs/shipping.md`, so nobody re-derives it
from memory next week.

## Step 3: let the agent write the CI workflow (8 min, attendee)

### Step 3, AI path: the agent writes ci.yml

The prompt, verbatim from handout step 3 ("**AI path.**"); it names the four gates, the service
container, and the one thing the agent must not do:

> Write `.github/workflows/ci.yml` for this repository. One job named `build-and-test` on
> ubuntu-latest, triggered on pull requests and on pushes to main. Four gates in this order:
> restore the solution in locked mode, build it with warnings as errors, then three SEPARATE
> test steps, one per test project, `tests/Helpdesk.Tickets.Domain.Tests`,
> `tests/Helpdesk.ArchitectureTests` and `tests/Helpdesk.ApiTests`, each named so I can tell
> them apart in the checks list. The API tests need a database, so add a SQL Server 2022
> service container publishing 1433 on host port 14330 with a sqlcmd health check, because the
> tests use the same connection string they use on my laptop. Give the workflow a read-only
> `permissions` block. Do not weaken any test, do not add continue-on-error, and do not change
> any file outside `.github/workflows`. Stay on the current branch, main: do not create a
> branch, commit, or push.

**Review checklist.** ONE job, not three: if the agent split the test steps into separate jobs,
either merge them back or list all three job names in the protection body from step 2, because
a context you did not list is a gate that does not hold. Is the port mapping `14330:1433`? Is
there a health check on the service? Did any test step gain `continue-on-error`? Which action
versions did it pick? Compare with the manual-path block (`checkout@v7`, `setup-dotnet@v6`); a
"Node.js 20 is deprecated" warning in the run is the agent's training cutoff showing.

What the agent should produce: `.github/workflows/ci.yml` only (`git status` shows just
`?? .github/`): one job `build-and-test`, the SQL service on `14330:1433` with a sqlcmd health
check, `restore --locked-mode`, `build -warnaserror --no-restore`, three named test steps,
`permissions: contents: read`, no `continue-on-error`. The agent takes about 30 s; the first
green run on GitHub about 1.5 min. Expect older action versions (`checkout@v4`,
`setup-dotnet@v4`) and the Node.js 20 deprecation annotation.

Say the last sentence out loud before they send it. The agent's objective is the gate you name,
so "make CI pass" and "write a CI workflow that runs these tests" are different instructions,
and only one of them leaves the tests intact.

### Step 3, manual path: paste ci.yml

**Manual path** (handout step 3, "Paste it:"; also the reference answer for diff review):

**File: `.github/workflows/ci.yml` (new file)**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-and-test:
    runs-on: ubuntu-latest

    # The API tests connect to localhost,14330 exactly as they do on a laptop,
    # so the service container publishes 1433 on that host port and nothing
    # in the test code changes between here and docker-compose.
    services:
      sql:
        image: mcr.microsoft.com/mssql/server:2022-latest
        env:
          ACCEPT_EULA: "Y"
          MSSQL_SA_PASSWORD: "Workshop!Passw0rd"
        ports:
          - 14330:1433
        options: >-
          --health-cmd "/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P Workshop!Passw0rd -Q 'SELECT 1'"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 12
          --health-start-period 20s

    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Set up .NET
        uses: actions/setup-dotnet@v6
        with:
          dotnet-version: 10.0.x

      - name: Restore (locked mode)
        run: dotnet restore Helpdesk.slnx --locked-mode

      - name: Build
        run: dotnet build Helpdesk.slnx -warnaserror --no-restore

      - name: Unit tests
        run: dotnet test tests/Helpdesk.Tickets.Domain.Tests --no-build

      - name: Architecture (fitness) tests
        run: dotnet test tests/Helpdesk.ArchitectureTests --no-build

      - name: API integration tests
        run: dotnet test tests/Helpdesk.ApiTests --no-build
```

Three things to point at on screen while the first run queues. The `services:` block with the
`14330:1433` mapping is why NOTHING in the test code changes between a laptop and a runner: the
connection string is identical, which is the same reason the compose file picked that port in
Lab 3. The health check is not decoration; without it the first API test hits a SQL Server that
is still starting and the run fails in a way that looks like a code bug. And `--locked-mode` on
the restore step is the supply-chain gate: it is the CI half of the property pair that lands
next.

### Step 3, both paths: the supply-chain half, by hand

Then the properties, which the attendee adds by hand (it is four lines of XML and the point is
that they read them):

**File: `Directory.Build.props` (edit)**

```xml
  <!-- Stage 5: reproducible restore. Every project writes a packages.lock.json, and CI
       restores in locked mode so a package cannot change under us between runs.
       After changing a package version, re-run restore with the force-evaluate switch. -->
  <PropertyGroup>
    <RestorePackagesWithLockFile>true</RestorePackagesWithLockFile>
    <NuGetAudit>true</NuGetAudit>
    <NuGetAuditMode>all</NuGetAuditMode>
    <NuGetAuditLevel>low</NuGetAuditLevel>
  </PropertyGroup>
```

Read the comment out loud and say why it is phrased that way: MSBuild rejects a double hyphen
INSIDE an XML comment (MSB4024, and the message is not obvious), so the comment does not spell
the switch. Thirty seconds that saves somebody an evening.

Then the one line the context files gain, identical in both, at the end of the `## Commands`
list. It goes in BEFORE the commit below, so it lands with the CI push instead of riding along
unnoticed in step 5's `git add -A`:

**File: `CLAUDE.md` (edit)**

```text
- Ship: CI is .github/workflows/ci.yml (one job, build-and-test, the required check on main; restore runs in locked mode, so run dotnet restore --force-evaluate after changing a package). Release: push a v* tag; .github/workflows/release.yml publishes the image to GHCR.
```

The same line goes in `AGENTS.md`. Same beat as Lab 3: the agent just learned a prerequisite it
had no way to guess, and both tools read one of those two files.

And two lines in `.gitattributes`, beside the Lab 4 one, so the workflow files and the
Dockerfile you are about to add can never land with CRLF on a Windows checkout:

**File: `.gitattributes` (append)**

```text
*.yml text eol=lf
Dockerfile text eol=lf
```

Generate and commit the lock files (`git branch --show-current` must print `main`):

```sh
git branch --show-current
dotnet restore Helpdesk.slnx
git add -A && git commit -m "CI, lock files, audit mode" && git push
```

Nine `packages.lock.json` files appear, one per project. That push to `main` works because
`enforce_admins` is `false`; everything after this goes through a pull request.

## Step 4: the pull request that breaks a rule (10 min, attendee)

The setup, in one sentence: somebody takes a shortcut that compiles, and the question is
whether anything stops them.

The change is two files, made on a branch, or fetch the branch of that name from the workshop
repository (both are on the handout). Put the branch line on screen first, before either edit:

```sh
git checkout -b lab5-violation
```

Skipped, the commit lands on `main` and the push fails with "src refspec lab5-violation does not
match any". Recovery is on the handout: `git switch -c lab5-violation`,
`git branch -f main origin/main`, then the push. First, the handler stops being internal, because a concrete type has to be public to be
injected from another assembly:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CreateTicket.cs` (edit)**

```csharp
public sealed class CreateTicketHandler(ITicketRepository tickets, IUnitOfWork unitOfWork)
    : ICommandHandler<CreateTicket, Guid>
```

Then the endpoint binds that concrete type instead of the interface:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` (edit)**

```csharp
        // Shortcut: take the concrete handler straight out of the container so the
        // request skips the validation and logging decorators.
        app.MapPost("/tickets", async (CreateTicketRequest request,
            CreateTicketHandler handler, CancellationToken ct) =>
```

Commit it and open it. The handout carries the commit line; without it `gh pr create` fails
with "No commits between main and lab5-violation". Attendees who fetched the branch already
have the commit and skip the first line:

```sh
git commit -am "Call the handler straight from the endpoint"
git push -u origin lab5-violation
gh pr create --base main --head lab5-violation --title "Call the handler straight from the endpoint" --body "Deliberate layer violation. CI should reject this."
```

`gh pr create` prints only the pull request URL, and attendees will wait for the failure to
appear there. Point them at the run instead:

```sh
gh pr checks lab5-violation --watch
gh run list --branch lab5-violation --limit 3
gh run view <run id> --log-failed
```

`build-and-test` ends as fail. The run id is the ID column of `gh run list` (handout step 4;
the URL in `gh pr checks` truncates on a narrow terminal), or bare `gh run view --log-failed`
picks from a list.

While the run queues, ask the room to predict which gate catches it. The compiler will not: the
change compiles. The unit tests will not: the domain is untouched. The API tests will not:
`POST /tickets` still returns 201 with an id, which is the quietly alarming part, because the
endpoint now skips validation, so a blank title reaches the domain instead of the validator
(`400 Tickets.EmptyTitle` from the domain instead of `400 Tickets.Validation.EmptyTitle`).
In CI the API step shows skipped, because the architecture step failed first; show the 201
locally if the room wants proof. The architecture step is the one that goes red (red X in the
step list), and the step log names the offender:

```text
  Failed Helpdesk.ArchitectureTests.LayerRulesTests.Rule4_Handlers_are_internal [72 ms]
  Error Message:
   Public handlers found: Helpdesk.Tickets.Application.Tickets.CreateTicketHandler
```

That is the manual-path wording from the Lab 4 reference tests. If your Lab 4 tests came from
the AI path, the class, method and message are your agent's, for example
`ArchitectureRulesTests.Rule4_Command_and_query_handlers_are_internal` with "Command and query
handlers must be internal, not public. Offending types: ...CreateTicketHandler". What must
match, whichever path you took:

| Check | Where to look | What you should see |
|---|---|---|
| Only the architecture step is red | The run's step list, or the step name in `gh run view --log-failed` | Red X on the architecture test step; the API test step skipped |
| The failing test is the handler rule | The `Failed` line | Rule 4: `Rule4_Handlers_are_internal` (reference) or your agent's name for it |
| The message names the offender | `Error Message:` | `Helpdesk.Tickets.Application.Tickets.CreateTicketHandler` |
| Nothing else failed | The summary line | `Failed: 1, Passed: 4` (`Total: 5`, one test per rule) |

That is the line to leave on screen. It names the rule, names the type, and tells the next
person what to do, which is the difference between a fitness test that survives and one that
gets deleted in six months.

The fix is to put the interface back in the endpoint and `internal` back on the handler: revert
both edits on the branch, then commit and push to the same branch:

```sh
git commit -am "Put the interface back" && git push
```

Watch `build-and-test` go green. Then CLOSE it rather than merging:

```sh
gh pr close lab5-violation
```

The fix is a full revert, so the branch now changes nothing, and a squash merge would land an
empty commit titled after the violation in `main`. The merge
habit moves to step 5, which has a real change to merge.

## Instructor demo: agent code review as an advisory check (5 min, no step number)

This runs on the instructor's reference repository, because it needs a model credential that
the room does not all have. Say that in one sentence and move: anyone with their own key can
copy the file tonight, and it is in the starter kit.

**File: `.github/workflows/agent-review.yml` (new file)**

```yaml
# instructor demo; needs the ANTHROPIC_API_KEY secret; attendees without a key skip this file
name: Agent review

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  contents: read
  pull-requests: write
  id-token: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Review the pull request
        uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: |
            REPO: ${{ github.repository }}
            PR NUMBER: ${{ github.event.pull_request.number }}

            Review this pull request against two things only.

            1. The layer rules in AGENTS.md. Domain references only Helpdesk.SharedKernel
               and no NuGet packages. Application references Domain. Infrastructure and
               Presentation reference Application. Only Helpdesk.Host references
               Infrastructure. Modules never reach into another module's internals.
               Quote the file and line for every violation you find.

            2. Anything that weakens a test or a gate: a deleted or relaxed assertion,
               a skipped or commented out test, a lowered threshold, a suppressed
               analyzer or warning, a narrowed architecture rule. Say plainly which
               check got weaker and what it used to enforce.

            Report only what you can point at. If the diff breaks neither, say so in
            one line and stop.
          claude_args: |
            --allowedTools "mcp__github_inline_comment__create_inline_comment,Bash(gh pr diff:*),Bash(gh pr view:*),Bash(gh pr comment:*)"
```

Show the run, then the review comment on the pre-opened pull request. Three points, in this
order:

1. **The prompt is narrow on purpose.** It reviews against exactly two things: the layer rules
   in `AGENTS.md`, and anything that weakens a test or a gate. It asks for a file and line for
   every layer violation, and it says to report only what it can point at. A review prompt
   that says "review this pull request" produces prose; this one produces citations. (Its
   findings post as inline comments; `gh pr comment` is in `--allowedTools` so a clean "breaks
   neither" verdict can be posted as a plain comment. Demo it on the red one.)
2. **The second half is the one to steal.** "Anything that weakens a test or a gate: a deleted
   or relaxed assertion, a skipped test, a lowered threshold, a suppressed analyzer, a narrowed
   architecture rule." That is the highest-risk shape in an agent-written pull request, because
   an agent whose objective was "make CI green" has a perfectly valid solution available to it:
   loosen the check. A human reviewer reads the code and misses the gate. Put the gate first.
3. **`permissions:` and `--allowedTools` together are the blast radius.** The token reads code
   and comments on pull requests. The tool list is four entries. The reviewer cannot push, it
   cannot merge, and it cannot edit the workflow that runs it. That is Lab 4's beat 4, running.

Then the honest framing, which the room will want: this check is ADVISORY on the reference
repository, and it should be. A review that can block a merge and is occasionally wrong trains
people to click through it, which is exactly the two-percent-prior problem from Lab 4. The
deterministic gates block; the agent comments.

## Tag it, ship the image (7 min, attendee)

### Step 5: tag a release

First, back to an up-to-date `main` before anyone writes the three new files (handout step 5):

```sh
git checkout main && git pull
```

#### Step 5, both paths: the Dockerfile and .dockerignore

The image first. Both files paste; nobody hand-types a Dockerfile in a lab.

**File: `Dockerfile` (new file)**

```dockerfile
# Build stage: the SDK image restores from the committed lock files and publishes the host.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY Directory.Build.props ./
COPY src/ ./src/

# Locked mode fails the build if a package resolves to anything the lock files do not list.
RUN dotnet restore src/Helpdesk.Host/Helpdesk.Host.csproj --locked-mode

RUN dotnet publish src/Helpdesk.Host/Helpdesk.Host.csproj \
    --configuration Release \
    --no-restore \
    --output /app

# Runtime stage: no SDK, no source, no build output beyond what publish produced.
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app ./

# APP_UID is the non-root account the dotnet base images ship with.
USER $APP_UID

ENV ASPNETCORE_HTTP_PORTS=8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "Helpdesk.Host.dll"]
```

**File: `.dockerignore` (new file)**

```text
bin/
obj/
**/bin/
**/obj/
.git/
.github/
.vs/
TestResults/
tests/
docs/
*.user
```

Call out three lines and no more. The build stage restores with `--locked-mode`, so the image
cannot be built from a package graph that differs from the one CI tested. The runtime stage is
the `aspnet` image, not the SDK: no compiler, no source, nothing but what publish produced.
`USER $APP_UID` is the non-root account the base images ship with, and it costs one line.

#### Step 5, AI path: the agent writes release.yml

Then the release workflow. AI path prompt (handout step 5, verbatim):

> Write `.github/workflows/release.yml`. It triggers on pushed tags matching `v*`. It logs in
> to ghcr.io using the built-in GITHUB_TOKEN and the actor who pushed the tag, then builds the
> Dockerfile at the repository root and pushes it as `ghcr.io/<owner>/helpdesk` tagged both
> with the tag name that triggered the run and with `latest`. Give it exactly two permissions,
> `contents: read` and `packages: write`. Do not add any other trigger. Stay on the
> current branch: do not create a branch, commit, or push.

What the agent should produce: `.github/workflows/release.yml` with `on: push: tags: ["v*"]`
only, exactly `contents: read` + `packages: write`, a ghcr.io login with `github.actor` /
`GITHUB_TOKEN`, and a build-push of the root Dockerfile tagged `:${{ github.ref_name }}` and
`:latest`. About 10 s; older action versions (`docker/login-action@v3`, `build-push-action@v6`)
and a hard-coded owner are all fine.

#### Step 5, manual path: paste release.yml

**Manual path:**

**File: `.github/workflows/release.yml` (new file)**

```yaml
# the agent wrote this from the prompt in the Lab 5 handout; edit as you like
name: Release

on:
  push:
    tags:
      - "v*"

permissions:
  contents: read
  packages: write

jobs:
  image:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7

      - name: Log in to the container registry
        uses: docker/login-action@v4
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # The tag that triggered the run is the image tag, so v0.1.0 publishes
      # ghcr.io/<owner>/helpdesk:v0.1.0 alongside :latest.
      - name: Build and push the image
        uses: docker/build-push-action@v7
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/helpdesk:${{ github.ref_name }}
            ghcr.io/${{ github.repository_owner }}/helpdesk:latest
```

#### Step 5, both paths: land it, merge, tag

Land the three files through a pull request, like everything since step 3 (they are still
untracked here, and tagging `main` without them starts no release run):

```sh
git checkout -b ship-image && git add -A && git commit -m "Dockerfile and release workflow" && git push -u origin ship-image
gh pr create --base main --head ship-image --title "Dockerfile and release workflow" --body "Release on tag."
```

Wait for `build-and-test` (about one more minute of CI in this step), then merge it the way the
whole day has been merging (handout word for word):

```sh
gh pr checks ship-image --watch
gh pr merge --squash --delete-branch
```

Merge before the check finishes and GitHub answers "the base branch policy prohibits the
merge": that is your step 2 protection working, so wait and run the merge again. `--auto`
(merge as soon as the check passes) is fine; `--admin` is not, because it uses your owner
rights to skip the very check you just made required.

Attendees TYPE this one. Asked to merge, the agent is refused by their own Lab 4
`confirm-merge.sh` ("merging can deploy to production"); the handout says so, so nobody
mistakes the hook working for a bug. If someone hits it, point at the room: that is Lab 4 paying
off.

Two habit beats while that lands. Squash, because one deliberate change is one commit in
history, not four "fix CI" commits. And the merge is the action that was gated by a hook in Lab
4 for a reason: in plenty of repositories, merging IS deploying.

Tag and push. The merge to `main` only ran CI; pushing the TAG is what triggers the release:

```sh
git checkout main && git pull && git tag v0.1.0 && git push origin v0.1.0
gh run list --workflow release.yml --limit 1
gh run watch <run id> --exit-status
```

`gh run list` shows the Release run the tag started, with its id in the ID column. `gh run watch`
waits until it finishes; a red run exits non-zero.

### Step 6: pull the image and run it

Then, once the run is green:

```sh
docker pull --platform linux/amd64 ghcr.io/<owner>/helpdesk:v0.1.0
docker run --rm --platform linux/amd64 -p 8080:8080 ghcr.io/<owner>/helpdesk:v0.1.0
```

`--platform linux/amd64` changes nothing on a Windows laptop. On an Apple Silicon Mac it
asks for the amd64 image the CI runner built and runs it under Rosetta; without it Docker looks
for an arm64 image, finds only amd64 plus a build attestation, and, depending on your Docker
version, either stops with `no matching manifest for linux/arm64/v8` or pulls the amd64 image
anyway with a platform-mismatch warning. The flag makes both behave the same.

About 103 MB compressed (`docker image ls` shows a few hundred MB on disk; quote the compressed
number). Say the number, it lands better than any slide about layer caching. The container starts
without a database and answers `/health`; the ticket endpoints need a database the container
can reach (the baked-in connection string says `localhost,14330`, which inside the container
is the container itself), which is precisely the thing Lab 6 stops doing by hand.

Show both halves live, from a second terminal while `docker run` holds the first (it runs in
the foreground):

```sh
curl -i localhost:8080/health
```

Then the contrast call:

```sh
curl -sS -i -X POST localhost:8080/tickets -H "content-type: application/json" -d '{"title":"Printer on fire"}'
```

The first is `200 OK` with the body `OK` (`app.MapGet("/health", () => "OK")` in
`Helpdesk.Host/Program.cs`), and the first terminal shows `Application started` with no SQL
exception. The second takes about 15 seconds (SQL connect timeout; warn the room it is
not hung) and is a 500 with an empty body (Production, so no developer exception
page; point at the SQL connection error in the first terminal's log instead), even though the
compose SQL container is up on the host: the container's `localhost` is itself. That 500 is the
bridge into Lab 6; say so. Ctrl+C stops the container, `--rm` cleans it up. PowerShell 5.1 users type
`curl.exe`.

One fact to state before anyone asks: the package is linked to the public repository and
inherits its visibility, so it is PUBLIC and anyone can pull it anonymously. Fine for this image, which does carry the workshop `sa` password in
`appsettings.json`, already public in `ci.yml`; say "never ship a real one this way". From a
private repository the package is private and a teammate's pull is denied until access is
granted on the package settings page.

## Verification (attendee, end of step 6)

What attendees run to check they are done (handout "Verification"):

```sh
gh pr checks lab5-violation
gh run list --limit 5
gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'
docker pull --platform linux/amd64 ghcr.io/<owner>/helpdesk:v0.1.0
```

`gh pr checks` shows per-check status on the violation PR, and `gh run list` the last five
workflow runs. Done when `gh pr checks` showed `build-and-test` FAILING on the violation and
PASSING after the fix, and the `docker pull` succeeds.

## Debrief (3 min)

Put the day's map back up, because this is the block where it closes:

> Plan (Lab 1) -> design and build (Labs 2 and 3) -> verify (Lab 4) -> **review, integrate and
> release (here)** -> deploy and operate (Lab 6) -> extend (Lab 7) -> govern (Lab 8).

Where this lab sits: it is the first block where a gate runs somewhere that is not the
attendee's laptop, judging work that is not on the attendee's laptop. Everything before lunch
was a rule you had to remember to run. From here it runs whether anyone remembers or not, and
that is the whole difference between a convention and a gate.

What production adds, in three sentences, said quickly so nobody thinks today was the finish
line. Real pipelines add ENVIRONMENTS, so the same image is promoted through dev and staging
rather than rebuilt per target. They add APPROVALS on the environments that matter, which is
where a human belongs in an otherwise automatic path. And they add supply-chain artifacts
around the image, an SBOM and a signature, so that six months from now somebody can answer
"what is actually in the thing we are running" without guessing.

## Transitions

**In, at 1:30, from Lab 4.** Lab 4 ended on least-privilege tokens for the agent in CI, which
was a promise with no CI behind it. Open with: "Forty minutes ago I told you the agent gets a
scoped token in CI. There was no CI. Let us fix that, and then hand it the token."

**Out, at 2:15, to Lab 6.** "You have an image. It is 103 MB, it is in a registry, and it
starts. What it does not have is a database, a connection string, or any way for you to see
what it is doing. Next block the agent builds the graph: the app, its SQL Server, and a
dashboard that shows you a trace through a create-ticket call. The image exists; now run it."

## If things go wrong

- **Apple Silicon: `no matching manifest for linux/arm64/v8` on `docker pull`** (older Docker;
  newer Docker pulls with a platform warning instead). The command lost its
  `--platform linux/amd64` (the release builds amd64 only). Add the flag to the pull and the run. If the container then exits at once, Docker Desktop's
  Rosetta setting is off; the Lab 1 fix applies.
- **`git commit` says "nothing to commit" in step 5.** The agent committed the release
  workflow itself, so `ship-image` branched from `main` without it.
  `git log --oneline --all -3` finds the commit; on `ship-image`, `git cherry-pick <sha>`,
  then `git push -u origin ship-image` and `gh pr create` as written. For agents that ignore
  the prompt's "do not commit".
- **`git push` says "The current branch ... has no upstream branch".** The attendee's
  agent ignored "Stay on the current branch, main" and branched for the CI work (for example
  `ci/build-and-test`), so the commit landed off `main` and the bare push has nowhere to go. Do
  not push the branch: step 4 expects the workflow ON `main`. Recovery, one line:
  `git checkout main && git merge --ff-only <branch> && git push && git branch -d <branch>`.
- **Room wifi dies.** Stop the solo work immediately rather than letting thirty people retry in
  parallel; switch the whole block to a walk-along on the reference repository, which is on the
  projector and already has everything. Attendees do the reading and the diff review, and run
  the commands tonight from the handout. Say it once, clearly, so nobody thinks they broke it.
- **The Actions queue is slow.** This is the likelier failure and it is not an error. Do not
  wait in silence: go to the pre-opened violation pull request on the reference repository,
  which is already red with the offender named, and teach step 4 from it while the room's own
  runs catch up. The supply-chain talking point is also sized to fill exactly one wait.
- **An attendee made the repository private.** Branch protection is greyed out or the `gh api`
  call comes back 403 with an upgrade message. Two options and no third: make it public
  (`gh repo edit <owner>/helpdesk --visibility public --accept-visibility-change-consequences`)
  or drop protection and follow along for step 4. Everything else in the block still works on a
  private repository.
- **`gh auth` is missing scopes.** `gh api -X PUT .../protection` fails on an account whose
  token has no `repo` scope, typically one authenticated long ago for
  something else. Fix in one command: `gh auth refresh -h github.com -s repo,workflow`. Also
  the cause when `git push` succeeds but the workflow file is rejected: pushing `.github/`
  content needs the `workflow` scope.
- **`NuGetAudit` goes red on a package nobody chose.** It will happen eventually, because a new
  advisory lands somewhere in the transitive graph without anybody touching the repository. Do
  not suppress it, do not lower the level, and do not treat it as a workshop bug: bump the
  package live, re-run `dotnet restore Helpdesk.slnx --force-evaluate`, commit the lock file
  diff, and point at what just happened. THAT is the lesson. Ten minutes of the room watching a
  vulnerability get bumped beats any slide about supply chains.
- **Restore fails with a lock file mismatch in CI but works locally.** A package changed and the
  lock files were not regenerated. `dotnet restore Helpdesk.slnx --force-evaluate`, commit the
  nine `packages.lock.json` files, push.
- **The API test step fails in CI and passes locally.** Check that the service container health
  check is present (without it the first test hits a SQL Server that is still starting, and the
  failure looks like a code bug) and that the port mapping is `14330:1433`.
- **A workflow file "looks fine" and the runner disagrees.** CRLF: `.gitattributes` pins
  `*.yml` and `Dockerfile` to LF, and a file that landed with CRLF on a Windows checkout reads
  differently on the runner. Same trap as the Lab 4 hook scripts.
- **`docker pull` is denied for a teammate.** The repository, and so the package, is private;
  grant access on the package settings page.
- **The agent-review workflow fails for attendees** (only those who copied it from
  `lab5-end`; no handout step adds it). Expected, and worth predicting out loud before somebody
  raises a hand: without the repository secret, the run on the pull request that ADDS the file
  passes with a "Skipping action due to workflow validation" warning, and every later pull
  request shows `review` failing with "Either ANTHROPIC_API_KEY, CLAUDE_CODE_OAUTH_TOKEN, or
  workload identity federation ... is required". It is advisory and not in the protection body,
  so it never blocks a merge: the pull request stays mergeable (GitHub calls that state
  UNSTABLE). Two clean options: delete the file, or leave it failing and unlisted as a reminder to
  wire it up at home. Do not let anybody spend lab time on it.
- **Behind schedule.** Cut in this order: the instructor demo becomes a thirty-second "here is the file,
  here is the review comment, it is in the kit" (it is already instructor-only), then steps 5-6
  become a walk-along on the reference repository with attendees pulling the image tonight.
  Step 4 is never cut. It is the reason this block exists.
