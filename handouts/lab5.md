# Lab 5 Handout: Ship it (1:30-2:15)

Snapshot branch if you get stuck: `lab5-end`
Prerequisite: `lab4-end` plus your Lab 4 work (pull the branch if your solution diverged during
Lab 4), a GitHub account, `gh auth login` already done, and Docker running (step 6 pulls and
runs the image). Everything below runs from the
repository root. Replace `<owner>` with your GitHub account name in LOWER CASE: container
registry names must be lower case, and the same string comes back in step 6.

**Starting from the snapshot instead of your own work?** Clone it into a new folder and make
it your `main` (a plain `git checkout lab4-end` leaves your next commits on a branch named
`lab4-end`):

```sh
git clone --branch lab4-end https://github.com/ivanball/adc2026-helpdesk.git helpdesk-lab5
cd helpdesk-lab5
git switch -c main --track origin/lab4-end
dotnet tool restore
```

`dotnet tool restore` installs the `dotnet ef` version the snapshot pins (from `lab3-end` on
the repository carries a tool manifest, and `dotnet ef` refuses to run until it is restored,
even with the global tool installed).

**Goal:** a public repository whose `main` is protected by a required check, an agent-authored
CI workflow that restores in locked mode and runs build plus three test tiers, one pull request
that goes red on a fitness test and green on a fix, and a container image published from a tag.

The same procedure is checked into the snapshot branch `lab5-end` as `docs/shipping.md`; copy
it into your own repo tonight, so you (and your agent) have it next week.

---

## Step 1: create the repository and push it

Branch protection is free on PUBLIC repositories only, so create it public. This is a workshop
helpdesk with no secrets in it. Name the local branch `main` first (Lab 1's `git init -b main`
already did, but the snapshot branch is `lab4-end`): whatever you push becomes the default
branch, and step 2 protects `main` by name.

Replace `<owner>` with your GitHub account name in lower case, without the angle brackets,
here and in every later command (for example `gh repo create octocat/helpdesk ...`). Left in,
the shell reads `<owner>` as a file redirect and fails before `gh` even runs.

Got your code by cloning the workshop repo (a snapshot branch)? Then `git remote` already lists
`origin`, and `gh repo create` stops with `Unable to add remote "origin"` and pushes nothing.
Run these three lines first. They rename the workshop remote to `workshop` (the name Lab 6
uses), make a clean local `main` from where you are, and drop its link to the workshop repo:

```sh
git remote rename origin workshop
git checkout -B main
git branch --unset-upstream
```

Then run the two lines below as printed (`git branch -M main` is then a no-op). Already hit the
error? The empty repo exists, so a second `gh repo create` says "Name already exists": run the
three lines, then `git remote add origin https://github.com/<owner>/helpdesk.git` and
`git push -u origin main` instead.

```sh
git branch -M main
gh repo create <owner>/helpdesk --public --source=. --remote=origin --push
```

## Step 2: protect main

The required check is the CI JOB name. The three test steps run inside one job, so there is one
context to require, not three. The check does not exist yet; that is fine.

This turns on branch protection: from now on a pull request can merge into `main` only after
the CI job `build-and-test` passes. Run it in Git Bash (on a Mac, in Terminal) from the repository root: the
`<<'JSON'` ... `JSON` lines are a heredoc that feeds the settings to `gh`, and neither Command
Prompt nor PowerShell can run one. Replace `<owner>`, then paste the whole block at once,
including the final `JSON` line.

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

GitHub answers with a JSON description of the protection. Check that it took:

```sh
gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'
```

It prints `["build-and-test"]`. Before this step, the same call answers "Branch not protected".

What the four keys buy you. `strict: true`: a branch must be up to date with `main` before it
can merge, without which two pull requests that are each green can merge into a red `main`.
`enforce_admins: false`: you are the admin, so you can still push straight to `main`, which is
what makes step 3 possible. `required_pull_request_reviews: null`: you can merge your own pull request, which
matters when you are the only person in the repository. `restrictions: null`: no push
allowlist.

## Step 3: let the agent write the CI workflow

**AI path.** The prompt, verbatim:

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

**Manual path.** Paste it:

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

Then the supply-chain half, which you add by hand because it is four lines and you should read
them. Lock files record the exact resolved package graph; `--locked-mode` in CI fails the
restore if anything resolves differently. `NuGetAudit` raises NU1901-NU1904 on a
known-vulnerable package, direct or transitive, and because `TreatWarningsAsErrors` is already
on in this file, that warning fails the BUILD instead of scrolling past.

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

(The comment says "the force-evaluate switch" rather than spelling the switch because MSBuild
rejects ANY double hyphen inside an XML comment: MSB4024, and the error does not explain
itself. The same goes for every `--switch` you might mention in a project-file comment.)

One line in each context file, at the end of the `## Commands` list, so the agent knows how
to ship:

**File: `CLAUDE.md` (edit)**

```text
- Ship: CI is .github/workflows/ci.yml (one job, build-and-test, the required check on main; restore runs in locked mode, so run dotnet restore --force-evaluate after changing a package). Release: push a v* tag; .github/workflows/release.yml publishes the image to GHCR.
```

Add the identical line to `AGENTS.md`.

And two lines in `.gitattributes`, beside the Lab 4 one, so the workflow files and the
Dockerfile you are about to add can never land with CRLF on a Windows checkout:

**File: `.gitattributes` (append)**

```text
*.yml text eol=lf
Dockerfile text eol=lf
```

Generate the nine lock files, one per project, and commit everything (`git branch --show-current`
must print `main`):

```sh
git branch --show-current
dotnet restore Helpdesk.slnx
git add -A && git commit -m "CI, lock files, audit mode" && git push
```

That push to `main` works because `enforce_admins` is `false`. Everything after this goes
through a pull request.

## Step 4: the pull request that breaks a rule

Somebody takes a shortcut that compiles. The question is whether anything stops them.

Make the change on a branch, or fetch the branch of that name from the workshop repository. It
is exactly two files. Create the branch first, before either edit:

```sh
git checkout -b lab5-violation
```

Skip it and the commit below lands on `main`, and `git push -u origin lab5-violation` fails
with "src refspec lab5-violation does not match any". If that already happened, recover
without redoing the edits: `git switch -c lab5-violation`, then `git branch -f main origin/main`,
then carry on from the push.

The handler stops being internal, because a concrete type has to be public to be injected from
another assembly:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CreateTicket.cs` (edit)**

```csharp
public sealed class CreateTicketHandler(ITicketRepository tickets, IUnitOfWork unitOfWork)
    : ICommandHandler<CreateTicket, Guid>
```

The endpoint binds that concrete type instead of the interface, which means the request now
skips the validation and logging decorators:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` (edit)**

```csharp
        // Shortcut: take the concrete handler straight out of the container so the
        // request skips the validation and logging decorators.
        app.MapPost("/tickets", async (CreateTicketRequest request,
            CreateTicketHandler handler, CancellationToken ct) =>
```

Commit it, push it and open the pull request (if you fetched the branch, it is already
committed: skip the first line):

```sh
git commit -am "Call the handler straight from the endpoint"
git push -u origin lab5-violation
gh pr create --base main --head lab5-violation --title "Call the handler straight from the endpoint" --body "Deliberate layer violation. CI should reject this."
```

`gh pr create` prints only the pull request URL; the run starts a few seconds later and the
failure lives in its log, on GitHub. Watch it from the terminal, or open the link in a browser:

```sh
gh pr checks lab5-violation --watch
gh run list --branch lab5-violation --limit 3
gh run view <run id> --log-failed
```

`gh pr checks --watch` waits for the run, and `build-and-test` ends as fail. The run id is the
number in the ID column of `gh run list`; paste it into `gh run view` without the angle brackets.

The link `gh pr checks` prints also holds the run id (the number after `/runs/`), but a narrow
terminal cuts it short, so `gh run list` is the reliable place to read it. Or skip the id:
`gh run view --log-failed` on its own lets you pick the run from a list.

Predict which gate catches it before you look. Not the compiler: it compiles. Not the unit
tests: the domain is untouched. Not the API tests: `POST /tickets` still returns 201 (in CI
the API step shows skipped, because the architecture step failed first; run it locally to see
the 201, with the SQL container up, and if the first run right after `docker compose up -d`
fails to connect, rerun it: SQL Server takes a few seconds to start). In the run's step list the architecture test step has the red X and the API test
step is skipped (the reference workflow calls them `Architecture (fitness) tests` and
`API integration tests`; on the AI path your agent named them). The step log names the
offender:

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

Fix it by putting the interface back in the endpoint and `internal` back on the handler, then
commit and push to the same branch:

```sh
git commit -am "Put the interface back" && git push
```

Wait for `build-and-test` to go green, then CLOSE the pull request rather than merging it:

```sh
gh pr close lab5-violation
```

The fix reverted both edits, so the branch now changes nothing, and squash-merging it would put
an empty commit named after the violation into `main`. You merge for real in step 5.

## Step 5: tag a release

Start from an up-to-date `main`. The violation pull request is closed, so leave its branch
before you write anything: the three new files, and the agent if you take the AI path, then
work on `main`.

```sh
git checkout main && git pull
```

Paste both files. Nobody hand-types a Dockerfile in a lab.

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

The build stage restores in locked mode, so the image cannot be built from a package graph that
differs from the one CI tested. The runtime stage is the `aspnet` image: no compiler, no
source. `USER $APP_UID` is the non-root account the base images ship with, and it costs one
line.

**AI path** for the release workflow:

> Write `.github/workflows/release.yml`. It triggers on pushed tags matching `v*`. It logs in
> to ghcr.io using the built-in GITHUB_TOKEN and the actor who pushed the tag, then builds the
> Dockerfile at the repository root and pushes it as `ghcr.io/<owner>/helpdesk` tagged both
> with the tag name that triggered the run and with `latest`. Give it exactly two permissions,
> `contents: read` and `packages: write`. Do not add any other trigger. Stay on the
> current branch: do not create a branch, commit, or push.

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

Land the three files through a pull request like everything else since step 3:

```sh
git checkout -b ship-image && git add -A && git commit -m "Dockerfile and release workflow" && git push -u origin ship-image
gh pr create --base main --head ship-image --title "Dockerfile and release workflow" --body "Release on tag."
```

Wait for `build-and-test` to go green (`--watch` waits for CI, about a minute), then squash it in:

```sh
gh pr checks ship-image --watch
gh pr merge --squash --delete-branch
```

Merge before the check finishes and GitHub answers "the base branch policy prohibits the
merge": that is your step 2 protection working, so wait and run the merge again. `--auto`
(merge as soon as the check passes) is fine; `--admin` is not, because it uses your owner
rights to skip the very check you just made required.

Type this one yourself, in your terminal. If you ask the agent to merge, your own Lab 4
`confirm-merge.sh` hook refuses it ("merging can deploy to production"): that is the hook
working, not a bug. The human merges, after reading the checks. One deliberate change is one
commit in history, not four "fix CI" commits.

The merge to `main` only runs CI. Pushing the TAG is what triggers the release:

```sh
git checkout main && git pull && git tag v0.1.0 && git push origin v0.1.0
gh run list --workflow release.yml --limit 1
gh run watch <run id> --exit-status
```

`gh run list` shows the Release run the tag started, with its id in the ID column. `gh run watch`
waits until it finishes; a red run exits non-zero.

## Step 6: pull the image and run it

Wait for the release run to finish, then:

```sh
docker pull --platform linux/amd64 ghcr.io/<owner>/helpdesk:v0.1.0
docker run --rm --platform linux/amd64 -p 8080:8080 ghcr.io/<owner>/helpdesk:v0.1.0
```

`--platform linux/amd64` changes nothing on a Windows laptop. On an Apple Silicon Mac it
asks for the amd64 image the CI runner built and runs it under Rosetta; without it Docker looks
for an arm64 image, finds only amd64 plus a build attestation, and, depending on your Docker
version, either stops with `no matching manifest for linux/arm64/v8` or pulls the amd64 image
anyway with a platform-mismatch warning (Docker 29.8 on the 2026-10-12 Mac run). The flag makes
both behave the same.

About 103 MB compressed (a few hundred MB on disk once it is unpacked: `docker image ls`
reported 367 MB on Windows and 250 MB on a Mac, depending on Docker's image store). It starts without a database and answers `/health` on port 8080; the ticket
endpoints need a database the container can reach (the baked-in connection string says
`localhost,14330`, which inside the container is the container itself), and wiring that up is
exactly what Lab 6 stops doing by hand.

Prove both halves. `docker run` without `-d` stays in the foreground, so leave it running and
open a second terminal (in Windows PowerShell 5.1, type `curl.exe`):

```sh
curl -i localhost:8080/health
```

Expect `HTTP/1.1 200 OK` with the plain-text body `OK`, and in the first terminal the normal
startup lines (`Now listening on: http://[::]:8080`, `Application started`) with no SQL
exception: the host does not touch the database at startup. Then the contrast call:

```sh
curl -sS -i -X POST localhost:8080/tickets -H "content-type: application/json" -d '{"title":"Printer on fire"}'
```

That one waits about 15 seconds (the SQL connect timeout; it is not hung) and answers
`500 Internal Server Error` with an empty body (the container runs as
Production, so there is no developer exception page), and the SQL connection error appears in
the first terminal's log instead. It fails even with your compose SQL container running on the
host, because the container's `localhost` is itself. Ctrl+C in the first terminal stops
the container, and `--rm` deletes it.

The package is linked to your public repository and inherits its visibility, so it is PUBLIC:
anyone can `docker pull` it without logging in. That is fine for this workshop image (it does
carry the workshop `sa` password in `appsettings.json`, already public in your `ci.yml`; never
ship a real one this way). In a private repository the package is private too, and a teammate's pull is denied
until you grant access on the package settings page.

## Instructor demo: agent code review as an advisory check

`.github/workflows/agent-review.yml` on the `lab5-end` branch (no step above adds it to your
repository) asks an agent to review every pull request for two things only: layer violations,
with a file and line for each, and anything that weakens a test or a gate. Note its
`permissions:` block and its `--allowedTools` list: together they are the blast radius, so the
reviewer can read code and comment, nothing more. It needs an `ANTHROPIC_API_KEY` repository
secret, and it is advisory: it is not in your protection body, so it never blocks a merge. To
use it at home, copy it from `lab5-end` and add the secret; copied without the secret, it fails
on every pull request.

## Verification

```sh
gh pr checks lab5-violation
gh run list --limit 5
gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'
docker pull --platform linux/amd64 ghcr.io/<owner>/helpdesk:v0.1.0
```

`gh pr checks` shows per-check status on the violation PR, and `gh run list` the last five
workflow runs. You are done when `gh pr checks` showed `build-and-test` FAILING on the violation and PASSING
after the fix, and the `docker pull` succeeds.

## Troubleshooting

- **Apple Silicon: `no matching manifest for linux/arm64/v8` on `docker pull`** (older Docker;
  newer Docker pulls with a platform warning instead). The command
  lost its `--platform linux/amd64`; the release builds amd64 only. Add the flag to the pull and
  the run. If the container then exits at once, turn on Docker Desktop's Rosetta setting
  (Settings > General > "Use Rosetta for x86_64/amd64 emulation on Apple Silicon").
- **`git commit` says "nothing to commit" in step 5.** The agent committed the release
  workflow itself (often on a branch it created), so `ship-image` started from `main` without
  it. `git log --oneline --all -3` finds the commit; on `ship-image`, `git cherry-pick <sha>`,
  then `git push -u origin ship-image` and carry on with `gh pr create`.
- **`git push` says "The current branch ... has no upstream branch".** The agent created a
  branch for the CI work (`ci/build-and-test` or similar) although the prompt asks it to stay
  on `main`. Land its commits on `main` and continue the step:
  `git checkout main && git merge --ff-only <branch> && git push && git branch -d <branch>`.
  If `--ff-only` refuses, `main` moved meanwhile: `git merge <branch>` instead, then push.
- **Branch protection is greyed out, or `gh api` returns 403 with an upgrade message.** The
  repository is private. Make it public:
  `gh repo edit <owner>/helpdesk --visibility public --accept-visibility-change-consequences`.
  Everything else in this lab works on a private repository; only the protection does not.
- **`gh api -X PUT .../protection` fails on scopes.** Your token was authenticated for
  something else long ago. `gh auth refresh -h github.com -s repo,workflow`. The same missing
  `workflow` scope is why a push containing `.github/` content can be rejected while an
  ordinary push succeeds.
- **The run sits queued for minutes.** Normal on a public repository, roughly three minutes
  red-to-green including queue time. Read the workflow diff while you wait rather than
  re-pushing; a second push just queues a second run.
- **`NuGetAudit` fails the build on a package you never chose.** A new advisory landed in the
  transitive graph. Do not suppress it and do not lower `NuGetAuditLevel`. Bump the package,
  re-run `dotnet restore Helpdesk.slnx --force-evaluate`, and commit the lock file diff. That
  diff is the feature: your package changes are now reviewable.
- **Restore fails with a lock file mismatch in CI but works locally.** You changed a package
  and did not regenerate. `dotnet restore Helpdesk.slnx --force-evaluate`, commit the nine
  `packages.lock.json` files, push.
- **The API test step fails in CI and passes locally.** Check the service container health
  check is present; without it the first test hits a SQL Server that is still starting, and the
  failure looks like a code bug. Check the port mapping is `14330:1433`.
- **A workflow file "looks fine" and the runner disagrees.** The repository's `.gitattributes`
  pins `*.yml` and `Dockerfile` to LF. A file that lands with CRLF on a Windows checkout is a
  file the runner reads differently from your editor: the same trap that killed the Lab 4 hook
  scripts.
- **`docker pull` is denied for a teammate.** The repository, and so the package, is private;
  grant access on the package settings page.
