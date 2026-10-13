# Starter kit: the take-home (built before the conference, walked through in S9)

The kit is a public repo, `<you>/agentic-dotnet-starter-kit`, MIT licensed, linked from the
last slide. It is built and pushed before the conference; S9 at 4:52 walks it in three
minutes and nobody reads a file on screen. Nine items, in adoption order, and the order is
the argument: items 1 to 5 are guardrails, items 6 to 9 are acceleration, and the
acceleration only compounds safely once the guardrails exist.

Every file came out of a reference branch of the workshop solution, so the kit and the
solution cannot disagree with each other. Where a file is kit-original (the rubric, the two
agent definitions, the two non-slice skills, the token checklist and the Aspire MCP note), it
was written against the same solution and the lab builds the same thing live. Everything is
framework-neutral: the concrete names are replaced by placeholders and each file carries a
header saying what to rename. It is a seed, not a product, and it does not build.

The nine sections below match the kit README and S9, in the same order.

Skills replaced the command template the earlier draft of this kit shipped: a skill fires on
its description without being named, which is what makes it survive contact with a team.

## Repo layout

```
agentic-dotnet-starter-kit/
  README.md
  LICENSE
  .gitattributes
  CLAUDE.template.md
  AGENTS.template.md
  TOKEN-DISCIPLINE.md
  .claude/
    settings.json
    hooks/
      block-dangerous.sh
      confirm-merge.sh
    skills/
      slice/SKILL.md
      spec-first-change/SKILL.md
      ci-diagnose/SKILL.md
    agents/
      rubric-scorer.md
      evidence-verifier.md
  evals/
    rubric.md
  fitness-tests/
    LayerRulesTests.cs
  templates/
    Dockerfile
    Directory.Build.props
    github/
      ci.yml
      release.yml
      agent-review.yml
  aspire/
    README.md
    MCP-SETUP.md
    AppHost.cs
    AppHost.csproj
    ServiceDefaults.Extensions.cs
    ServiceDefaults.csproj
  mcp-host/
    README.md
    TicketTools.example.cs
    Program.snippet.cs
```

Thirty files. `README.md` carries the adoption list in the same order as the
sections below, the per-item verification checks, and the one placeholder that has to be
filled before the repo goes public: the workshop repo link. `LICENSE` is MIT so teams can
copy without asking anybody. `.gitattributes` pins `*.sh`, `*.yml` and `*.md` to LF, which is
not cosmetic: a carriage return in a hook shebang makes the hook fail silently on some
shells, and a guardrail that fails silently is worse than one that is absent.

## 1. Context files: CLAUDE.template.md and AGENTS.template.md (Lab 1)

**What it is.** Two templates, one per file name, because different tools read different
names: Codex, the Copilot coding agent and Cursor read `AGENTS.md`; Claude Code reads it too
(v2.1.277+), but only when there is no `CLAUDE.md`. Keep both and make `CLAUDE.md` a one-line
`@AGENTS.md` import, so there is one set of rules, not two copies that drift. Both have the
same four sections: Commands, Layer rules, Conventions, Never. Every value is an
angle-bracket blank.

**Taught in** Lab 1 (the spec-driven skeleton writes the first version of this file before it
writes any code). **Came from** the helpdesk solution's `CLAUDE.md` and `AGENTS.md` on
`lab1-end`, with the concrete values stripped back to blanks.

**File: `kit:CLAUDE.template.md` (new file)**

```markdown
# <Project name>

<If you also keep AGENTS.md, replace this whole file with the one line `@AGENTS.md`, so
Claude Code loads the same rules as every other agent. Otherwise fill in the blanks below.>

<One paragraph: what this system is, its module/layer shape, where the composition root is.>

## Commands

- Build: <command>
- Test: <command> (<what has to be running first: a database container, a service>)
- Run: <command>
- Run (orchestrated): <command, if you have an app host that starts the dependencies too>
- Single test: <command>
- MCP: <endpoint and transport, if the app exposes one; delete this line if it does not>
- Ship: <path to your release doc, plus the one gotcha: what to regenerate after a package
  change, which restore mode CI uses>

## Layer rules (enforced by <path to fitness tests>)

- <Your domain-equivalent> references only <allowed>.
- <Who may reference infrastructure, and who may not>.
- <Module boundary rule if modular: where modules are allowed to meet>.

## Conventions

- Errors: <Result pattern / exceptions policy>. Never throw for business rule failures;
  exceptions are for bugs and infrastructure faults only.
- <Entity construction convention: private constructors, static factory methods.>
- <Handler/endpoint conventions: one command or query per file, handler beside it,
  internal visibility.>
- <Style: nullable, warnings-as-errors, file-scoped namespaces.>

## Never

- Never add a NuGet package without asking.
- Never modify tests to make them pass; fix the code or flag the test as wrong.
- Never touch the database schema without a migration.
- <The gotcha you tell every new hire.>
```

`AGENTS.template.md` opens with the reason it exists and then repeats the same four sections
verbatim:

**File: `kit:AGENTS.template.md` (excerpt: the opening note)**

```markdown
# <Project name> (agent instructions)

Codex, the Copilot coding agent and Cursor read AGENTS.md. Claude Code reads it too
(v2.1.277+), but only when there is no CLAUDE.md. If you keep both files, make CLAUDE.md
a one-line `@AGENTS.md` import so there is one set of rules, not two copies that drift,
and every agent and every human starts from the same contract.
```

**How to adopt it Monday.** Half an hour on your real repository, filling the blanks from
what you would tell a new hire, and the Never list is the half that pays.

## 2. Settings and the two hooks (Lab 4)

**What it is.** `.claude/settings.json` carries four things: the allow list (read-only and
reversible work), the deny list (the three command classes that must never run, plus reads
of `.env` and `.pem` files), the `defaultMode` permission mode, and the two hooks. It
wires both hooks as `PreToolUse` commands on the `Bash|PowerShell` matcher, and every
allow and deny rule appears for both shells, because on Windows the agent also has a native
PowerShell tool that `Bash` rules do not see (see run sheet 05, Beat 1). The hooks are the
deterministic layer under the probabilistic one: deny rules catch the common spellings, a hook
catches the rewordings a pattern list misses. There is no `sandbox` block, matching Lab 4: on
macOS the sandbox blocks the agent's `dotnet build`, `dotnet test`, NuGet restore and `gh`, and
on native Windows it does nothing. To add it to your own repo, list every command that must
reach outside in `excludedCommands`.

**Taught in** Lab 4. **Came from** `lab4-end`; the settings file is the one the attendees end
Lab 4 with. Both quote the placeholder in the two hook paths (`"${CLAUDE_PROJECT_DIR}"`), so a
project path with spaces still works.

**File: `kit:.claude/settings.json` (new file)**

```json
{
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(dotnet build:*)",
      "Bash(dotnet test:*)",
      "Bash(git status)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "PowerShell(dotnet build *)",
      "PowerShell(dotnet test *)",
      "PowerShell(git status)",
      "PowerShell(git diff *)",
      "PowerShell(git log *)"
    ],
    "deny": [
      "Bash(dotnet ef database drop:*)",
      "Bash(git push --force:*)",
      "Bash(rm -rf:*)",
      "PowerShell(dotnet ef database drop *)",
      "PowerShell(git push --force *)",
      "PowerShell(Remove-Item *-Recurse*)",
      "Read(./.env)",
      "Read(./**/*.pem)"
    ]
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|PowerShell",
        "hooks": [
          { "type": "command", "command": "\"${CLAUDE_PROJECT_DIR}\"/.claude/hooks/block-dangerous.sh" },
          { "type": "command", "command": "\"${CLAUDE_PROJECT_DIR}\"/.claude/hooks/confirm-merge.sh" }
        ]
      }
    ]
  }
}
```

**File: `kit:.claude/hooks/block-dangerous.sh` (new file)**

```bash
#!/usr/bin/env bash
# PreToolUse hook: hard-block destructive commands regardless of how they are phrased.
# Exit 2 = block the tool call and show stderr to the model.
set -euo pipefail

# Prefer jq for precise extraction; fall back to matching the raw JSON when jq is absent
# (the raw match is coarser but fails safe rather than erroring out).
if command -v jq >/dev/null 2>&1; then
  command_text=$(jq -r '.tool_input.command // empty')
else
  command_text=$(cat)
fi

blocklist='database +drop|drop +database|rm +-rf +/|git +push +.*--force|git +reset +--hard +origin'

if echo "$command_text" | grep -Eiq "$blocklist"; then
  echo "Blocked by policy (block-dangerous.sh): this command class is never run by the agent." >&2
  echo "If a human really intends this, they run it themselves in a terminal." >&2
  exit 2
fi

exit 0
```

**File: `kit:.claude/hooks/confirm-merge.sh` (new file)**

```bash
#!/usr/bin/env bash
# PreToolUse hook: merging a PR may be a production deploy. Force an explicit human step.
set -euo pipefail

if command -v jq >/dev/null 2>&1; then
  command_text=$(jq -r '.tool_input.command // empty')
else
  command_text=$(cat)
fi

if echo "$command_text" | grep -Eq 'gh +pr +merge'; then
  echo "Blocked (confirm-merge.sh): merging can deploy to production." >&2
  echo "Policy: the human runs the merge themselves after reviewing checks." >&2
  exit 2
fi

exit 0
```

`confirm-merge.sh` is the strict variant the workshop teaches: the agent never merges, a
human does, after reading the checks. The kit README says so, and says teams who want
agent-assisted merges can relax it later. Start strict.

**How to adopt it Monday.** Check the directory in like any other shared infrastructure, add
one deny rule for your scariest command, and gate on reversibility and on whether an action
leaves the machine, never on how weighty it feels.

## 3. The three skills (Lab 3, Lab 1, Lab 5)

**What it is.** `.claude/skills/` holds `slice`, `spec-first-change` and `ci-diagnose`. A
skill is a folder with a `SKILL.md`: the front matter description is the trigger and is
always resident, the body loads only when the skill fires. Each description is written as the
situation in the words somebody would actually type, which is the whole mechanism.

**Taught in** Lab 3 for `/slice`, Lab 1 for the spec-first discipline, Lab 5 for CI
diagnosis. **Came from** `lab3-end` for the slice skill, generalised with `<App>`, `<Module>`
and `<Aggregate>` placeholders; the other two were written for the kit against the same
solution.

**File: `kit:.claude/skills/slice/SKILL.md` (new file)**

```markdown
---
name: slice
description: Use when asked to add a new command or query slice to a module, wire up a new endpoint, or implement a new use case end to end through Application, Presentation and registration.
---

# Add a vertical slice

Add one command or query, its handler, its validator, its endpoint and its registration.
One use case per slice. Follow CLAUDE.md and AGENTS.md exactly; they are the contract.

Replace `<App>`, `<Module>` and `<Aggregate>` below with your own names once, then delete
this line. The paths are the only part of this skill that is project specific.

## Steps

1. Read CLAUDE.md, then read the nearest existing slice in
   `src/Modules/<Module>/<App>.<Module>.Application/<Aggregate>/` and copy its shape.
   The existing code is the specification; do not invent a second way of doing this.
2. Create the Application file `<UseCase>.cs` beside its siblings. It holds, in order:
   the command or query record implementing `ICommand<TResponse>` or `IQuery<TResponse>`,
   the handler (internal, sealed, thin: load or create through the domain, call the domain
   behavior, save through `IUnitOfWork`), and any response records the query returns.
3. Add a validator implementing `IValidator<T>` in the same file when the input has a
   shape to check. Validators check input shape only. Business rules belong in the domain
   entity and are returned as a `Result` failure, never thrown.
4. Add the minimal-API endpoint in
   `src/Modules/<Module>/<App>.<Module>.Presentation/<Aggregate>Endpoints.cs`.
   Map the `Result` the handler returns: success to 201 Created for a create, 204 No Content
   for a state change, 200 OK for a query; failure to 404 when the error code ends in
   `NotFound`, and 400 Bad Request with the error code and message otherwise.
5. Register the handler in the module's existing registration extension
   (`<Module>Application.cs`). Do not add new infrastructure, a new DI container, or a new
   registration file.
6. Add a test. Domain rules go in `tests/<App>.<Module>.Domain.Tests`. Status-code mapping
   goes in `tests/<App>.ApiTests`, which drives the real host against the database
   container.
7. Verify: start the database container, then run the solution build and the full test
   command from CLAUDE.md. Show the output. Warnings are errors, so a build that reports
   any warning is a failure.

## Constraints

- Never modify the shared kernel, the Domain layer, or an existing test to make a slice pass.
- Never add a NuGet package. Never change the database schema without a migration.
- If a step conflicts with an existing convention, stop and ask rather than improvising.
```

**File: `kit:.claude/skills/spec-first-change/SKILL.md` (new file)**

```markdown
---
name: spec-first-change
description: Use when asked to add a feature, change behaviour, or start any change bigger than a one-line fix, and proactively when a request names an outcome but not the files it touches.
---

# Write the spec before the code

A request is not a specification. Turn it into one, get it approved, then build against it.
The spec is what the verification step checks against at the end, so write the acceptance
checks before you know how you will satisfy them.

## Steps

1. Write the spec first, in the chat or in a file under `docs/specs/` if the change spans
   more than one session. Four headings, nothing else:
   - **Goal.** One sentence, in the language of the people who asked, naming the observable
     outcome rather than the implementation.
   - **Scope.** The files, modules and layers you expect to touch. Name them before you
     open them; a file you did not expect is a finding later.
   - **Out of scope.** What you are deliberately not doing. Write this even when it feels
     obvious. It is the field that stops a small change from growing a refactor.
   - **Acceptance checks.** Numbered, each one a command, an assertion or an observation
     that can come back true or false. "Works correctly" is not a check. "`POST /tickets`
     with an empty title returns 400 and error code `Tickets.Validation.EmptyTitle`" is.
2. Ask the questions now. Anything ambiguous in the request goes back to the human before
   any code is written, not halfway through. This is the last point at which asking is cheap.
3. Enter plan mode and produce the plan: the ordered edits, the test that proves each one,
   and the order you will run them in. Do not edit anything yet.
4. Get the plan approved. If the human changes the goal, go back to step 1 and rewrite the
   spec. A plan that no longer matches its spec is worse than no spec.
5. Implement in the order the plan gives. Write the test before the code it covers, and
   never write a test and the implementation it checks in the same pass: a test written
   alongside its code describes the code instead of the requirement and passes by
   construction.
6. Verify against the acceptance checks, one at a time, by running them. Paste the command
   and its output. A check you cannot run is a check that failed.
7. Summarise what changed: the files touched against the files the scope predicted, each
   acceptance check with its result, and anything in the spec you did not do and why.

## Constraints

- If an acceptance check cannot be made to pass, say so and stop. Never relax the check,
  delete it, or rewrite it to describe what the code does instead.
- Anything you build that is not in the scope list is scope creep, however defensible the
  reason. Raise it, do not absorb it.
- If you cannot write the acceptance checks, the change is not understood yet. Say that
  and ask, rather than starting and discovering it in the third file.
```

**File: `kit:.claude/skills/ci-diagnose/SKILL.md` (new file)**

````markdown
---
name: ci-diagnose
description: Use when CI is red, a check failed, or the user asks why the pipeline is failing, why the build broke, or what is wrong with the run, and proactively right after a push or a pull request is opened.
---

# Diagnose a red pipeline

Find the first thing that broke, name it, and propose the smallest fix. A pipeline reports
its failures in cascade order, so the last red line is usually a consequence and the first
one is the cause.

## Steps

1. List the recent runs and find the failing one:

   ```sh
   gh run list --limit 10
   ```

2. Read only the failed portion of the log. Never download the whole log:

   ```sh
   gh run view <run-id> --log-failed
   ```

3. Name the **first** failed step, by its step name, with the first error line under it.
   Say the step name out loud before saying anything about a cause. If three steps are red,
   the other two are almost certainly downstream of the first.

4. Classify the failure into exactly one of these, because the fix differs by class:

   - **Build.** A compiler error, or a warning promoted to an error by warnings-as-errors.
     The fix is in the code the error names. Read that file at that line.
   - **Test.** An assertion failed. Read the assertion message first: a good one names the
     offender. Decide whether the test is right and the code is wrong, which is the usual
     case, or the requirement moved, which needs a human to confirm.
   - **Restore or lock drift.** A locked-mode restore refusing a package the committed lock
     files do not list. Somebody changed a package version without regenerating the locks.
     The fix is to regenerate them and commit the result, not to drop locked mode.
   - **Audit.** A package with a published advisory. The fix is to bump the package, or to
     pin a fixed version of a transitive one by naming it directly. Never suppress it.
   - **Infrastructure.** A service container that never went healthy, a runner that timed
     out, a registry that was unreachable, a step that failed in under a few seconds with
     no output at all. This class is not a code defect: re-run the failed jobs once and
     say that is what you did.

5. Propose the smallest fix that addresses the class you named, and say which acceptance
   the fix restores. One fix per red run. If the fix is not obvious from the log, say what
   you would need to see rather than guessing.

6. Re-verify locally where you can, then push and watch the same check go green. Report the
   run id and the check name, not "it should be fine now".

## Never

- Never weaken a test, delete an assertion, add a skip attribute, lower a threshold,
  narrow an architecture rule, or suppress an analyzer to make a run go green. Those are
  all valid solutions to the problem "make CI pass" and none of them is a solution to the
  problem that made it fail. If you believe a gate is genuinely wrong, say so, leave it
  red, and hand the decision to a human.
- Never disable a workflow, remove a required check, or merge past a red one.
- Never claim a run is green without the run id and the check name to point at.
````

**How to adopt it Monday.** Take your most-repeated request, write it once as a skill, and
rewrite the description in your own words before you use it: if it does not fire when you
describe the situation without naming it, the description is wrong, not your phrasing.

## 4. The fitness-test seed (Lab 4)

**What it is.** `fitness-tests/LayerRulesTests.cs`, six architecture rules as xUnit tests over
NetArchTest: domain dependency direction, no EF Core in the domain, application not reaching
outward, internal handlers, only the composition root touching infrastructure, and the module
boundary. The header carries the substitution map, so adapting it is six find-and-replace
operations rather than a reading exercise.

**Taught in** Lab 4, where attendees write these live and watch each one fail on purpose.
**Came from** `main`, `tests/Helpdesk.ArchitectureTests/LayerRulesTests.cs` (lab4-end has the
first five; the module-boundary rule arrives with the Notifications module), with the concrete
names replaced.

**File: `kit:fitness-tests/LayerRulesTests.cs` (excerpt: the header)**

```csharp
// Architecture fitness tests: the executable form of the layer rules in CLAUDE.md.
// Six rules, the same six the workshop solution enforces, with the concrete names
// replaced by placeholders. Substitute them once and the file compiles:
//
//   YourApp          -> your solution prefix
//   SomeAggregate    -> any type that lives in your domain assembly
//   SomeHandler      -> any type that lives in your application assembly
//   Module           -> one module name (used in every rule)
//   OtherModule      -> a second module, for rule 6
//   OtherModuleRegistration -> any public type in the second module's infrastructure
//                       assembly, for rule 6
//
// Then prove each test can fail by temporarily breaking the rule it guards and watching
// the red run. A fitness test that has never failed is decoration, not a gate.
//
// Package: NetArchTest.Rules
```

The full file is taught in Lab 4; do not walk it on screen in S9.

**How to adopt it Monday.** Substitute the six placeholder names, add the project to your
solution, put it in the required check, and then break each rule once to prove the test can
fail. A fitness test that has never failed is decoration.

## 5. CI, release, agent review and the Dockerfile (Lab 5)

**What it is.** `templates/github/ci.yml` (restore in locked mode, build, three test tiers),
`templates/github/release.yml` (tag to container image in the GitHub registry),
`templates/github/agent-review.yml` (agent review as an advisory pull-request check, never a
required one), `templates/Dockerfile` (two stages, non-root) and
`templates/Directory.Build.props` (the lock files and the package audit that CI and the
Dockerfile rely on). Each one opens with a numbered header naming
exactly what to change and what to leave alone.

**Taught in** Lab 5, where the agent authors all four against the real repository. **Came
from** `lab5-end`, verbatim, `.github/workflows/` and the repository-root `Dockerfile`. The
throwaway SQL password stays in `ci.yml` on purpose: it belongs to a container that lives for
the length of one job, and the header tells the reader to replace it anyway.

**File: `kit:templates/github/ci.yml` (excerpt: the header)**

```yaml
# TEMPLATE. Copy to .github/workflows/ in your repo. Change four things:
#   1. the solution name (`Helpdesk.slnx`) in the restore and build steps;
#   2. the three test project paths, or collapse them into one `dotnet test <sln>`
#      step if you do not want the failure to name which tier broke;
#   3. the SQL password, in BOTH the service `env` block and the health command,
#      and in the connection string your tests read. It is a throwaway for a
#      container that lives for one job, but do not paste a real one here;
#   4. the host port 14330 if your local compose file publishes a different one.
#      Keep it identical to local so no test code changes between laptop and CI.
# Lock files and the package audit come from templates/Directory.Build.props, copied
# to the repository root. Without it, locked mode has nothing to lock to.
# Required-check name to protect `main` with is the JOB name, `build-and-test`,
# not the step names. The three test steps run inside that one job.
name: CI
```

**File: `kit:templates/github/release.yml` (excerpt: the header)**

```yaml
# TEMPLATE. Copy to .github/workflows/ in your repo. Change three things:
#   1. the image name (`helpdesk`) on both tag lines, to your own image name;
#   2. the Dockerfile `context` if your Dockerfile is not at the repository root;
#   3. nothing else. GITHUB_TOKEN is provided by Actions; no secret to create.
# Container registry names must be lower case, including the owner segment.
```

**File: `kit:templates/github/agent-review.yml` (excerpt: the header)**

```yaml
# TEMPLATE. Copy to .github/workflows/ in your repo. Needs an ANTHROPIC_API_KEY
# repository secret; without one, delete this file rather than letting it fail.
# Change the layer rules quoted in the prompt to your own, and keep the second
# instruction verbatim: the gate-weakening check is the half that catches the
# failure mode agent-written pull requests actually have.
# Keep it advisory: never add this job to the branch-protection required checks.
```

**File: `kit:templates/Dockerfile` (excerpt: the header)**

```dockerfile
# TEMPLATE. Copy to your repository root. Change three things:
#   1. the project path in the restore and publish lines;
#   2. the entry point assembly name on the last line;
#   3. the COPY list, if your build needs more than Directory.Build.props and src/.
#      Directory.Build.props is templates/Directory.Build.props, copied to the root.
# Keep the two stages and keep USER $APP_UID: the runtime image ships that
# non-root account, and running as root is the default nobody notices.
```

The full files are taught in Lab 5.

**How to adopt it Monday.** Copy `ci.yml` first, make its job the required check on `main`,
and only then add the other three. The agent review workflow needs an API key secret; without
one, delete the file rather than letting it fail red forever.

## 6. The Aspire seed and the MCP setup note (Lab 6)

**What it is.** Four seed files (`AppHost.cs`, `AppHost.csproj`,
`ServiceDefaults.Extensions.cs`, `ServiceDefaults.csproj`) plus `aspire/README.md` for
dropping them in. The wiring that matters is the health one: liveness and readiness are two
different endpoints, the startup gate is on liveness and never on readiness, and
`ServiceDefaults.Extensions.cs` is where that is decided for every service at once.
`aspire/MCP-SETUP.md` is the other half of Lab 6: pointing a coding agent at the running app
so it can read the resources, the logs and the traces of the run in front of it.

**Taught in** Lab 6. **Came from** `lab6-end`: `src/Helpdesk.AppHost/AppHost.cs` and
`src/Helpdesk.ServiceDefaults/Extensions.cs`, renamed to seed files with a header saying what
to rename.

**File: `kit:aspire/AppHost.cs` (excerpt: the header)**

```csharp
// SEED FILE, not a project. See aspire/README.md for how to drop it in.
// Rename: "Helpdesk" -> your own prefix, "Tickets" -> your database resource name,
// Projects.Helpdesk_Host -> Projects.<YourHostProjectName_WithUnderscores>.
```

**File: `kit:aspire/ServiceDefaults.Extensions.cs` (excerpt: the header)**

```csharp
// SEED FILE, not a project. Goes in your ServiceDefaults project as Extensions.cs.
// The namespace below is Microsoft.Extensions.Hosting on purpose: that is what makes
// builder.AddServiceDefaults() resolve in every service without an extra using.
```

The full files are taught in Lab 6, and `aspire/README.md` has the four-step drop-in.

**File: `kit:aspire/MCP-SETUP.md` (new file)**

````markdown
# Pointing a coding agent at a running app

The Aspire CLI can expose the application it is running to a coding agent over MCP. The
agent can then list the resources, read their logs and read their traces from the run in
front of you, which closes the loop between running the app and changing it.

## 1. Check the CLI first

```sh
aspire --version
aspire agent --help
```

The `agent` command arrived in 13.2 (renamed from `aspire mcp`). A CLI that predates it answers
`Unrecognized command or argument 'agent'`. Update before going further: everything
below depends on it, and the failure mode is a config file that looks right and a server
that never starts.

## 2. Write the server entry

```sh
aspire agent init
```

It asks which agent you use and writes the entry for it. For Claude Code that is
`.mcp.json` at the repository root:

```json
{
  "mcpServers": {
    "aspire": {
      "command": "aspire",
      "args": ["agent", "mcp"]
    }
  }
}
```

VS Code reads `.vscode/mcp.json` instead, in the same shape. The file is safe to commit:
it names a command, not a credential.

`aspire agent init` also changes your machine outside the repository. It installs seven
Aspire skills in `~/.agents/skills/`, and adds a `PostToolUse` hook to your user-level
`~/.claude/settings.json` that runs `~/.aspire/hooks/track-telemetry.sh` after every tool
call, in every Claude Code session, to report Aspire skill and MCP usage. Setting
`ASPIRE_CLI_TELEMETRY_OPTOUT=true` stops the reporting, not the install. To undo it, delete
that `hooks` entry from `~/.claude/settings.json` and remove `~/.agents/skills/aspire*`. If you
only want the MCP entry, write the file above by hand instead.

## 3. Restart and confirm

Restart the agent so it picks the server up, then list the connected servers (`/mcp` in
Claude Code) and confirm `aspire` is there and connected. An MCP server that failed to
start is usually silent, so confirm rather than assume.

## 4. What the agent can then read

With the app running under the app host, the agent can enumerate the resources, read a
resource's logs, and read traces. That is enough for the loop this exists for:

> The close endpoint returns 204 but the record reads back unchanged. Use the aspire MCP
> server to read the logs and traces from the running app, find the failure, and fix it.

Work that failed after the response was sent shows up as an error log for a request whose
trace already ended green, and that is exactly the class of bug a passing test suite does
not see and the trace alone does not show. The agent reads that error line, follows the
exception to the handler and proposes
the fix. Confirm the fix the way CI would, by running the test tier that covers it, not
by re-reading the dashboard.

## What to keep in mind

Each MCP server you connect is a dependency with two costs: the tool definitions sit in
the agent's context on every turn, and whatever the server returns arrives in the same
window as your own instructions. Connect the ones the current work needs and disable the
rest, rather than accumulating them.
````

**How to adopt it Monday.** One command that starts the database and the app together is the
whole return on the seed. Add the two health endpoints before you add anything else, and
check the CLI version before you debug a config file that looks right.

## 7. The mini rubric and the two agent definitions (Lab 8)

**What it is.** `evals/rubric.md` is five architecture rules scored 0, 1 or 2 each, with the
line between 1 and 2 being a merge gate rather than effort, plus the three-step procedure:
score, verify, adjudicate. `.claude/agents/rubric-scorer.md` (`model: sonnet`) scores from
evidence read in that run and never totals the score; `.claude/agents/evidence-verifier.md`
(`model: opus`) is adversarial and is handed the claims and the paths, never the scorer's
reasoning.

**Taught in** Lab 8, where the room reads the five rules, writes a sixth, and watches the
instructor run both agents.
**Came from** the workshop's own governance setup, scrubbed to a five-rule version with every
internal name removed.

**File: `kit:evals/rubric.md` (new file)**

```markdown
# The five-rule architecture mini rubric

An eval for a codebase rather than for a model. Five rules, scored 0, 1 or 2 each, out
of a possible 10. It exists so that "is this codebase still the shape we said it was"
has an answer somebody can check, rather than an answer somebody remembers.

Two properties make it work, and both are easy to lose. **Every score is anchored to a
`path:line` read in this run**, so a score is a pointer rather than an opinion. And
**a second agent tries to break every score the first one produced**, because a single
pass grades the argument it just wrote.

## The scale, identical for all five rules

| Score | Meaning |
| --- | --- |
| 0 | The rule is broken somewhere in the codebase, or there is no evidence it is followed. |
| 1 | The rule is followed everywhere you looked, but nothing would stop a change that broke it. Convention only. |
| 2 | The rule is followed AND a check enforces it on every merge: a test in the required CI job, an analyzer at error severity, or a build that fails. |

The line between 1 and 2 is a merge gate, not effort. A rule checked by a nightly job,
a script somebody remembers to run, or a code review is a 1. Open the workflow file and
read which check is required before scoring a 2.

## Rule 1: dependency direction

The domain layer depends on nothing but the shared kernel and the base class library.
No persistence package, no web package, no messaging package anywhere below the
application layer.

**Evidence that counts.** The domain project file, showing which package and project
references it actually has. A fitness test asserting the allowed dependency set, and
the CI step that runs it. **Evidence that does not count.** A statement in a README, a
namespace that looks clean, or the absence of a `using` in the one file you opened.

## Rule 2: failures are returned, not thrown

A broken business rule comes back as a failed result carrying a code and a message.
Exceptions are for defects and infrastructure faults only.

**Evidence that counts.** The result type itself, one aggregate method returning a
failure for a rule it refuses, and the endpoint or adapter that maps that failure onto
a status code. A test asserting the failing path returns rather than throws. **Does not
count.** A try/catch that converts an exception into a result at the boundary: that is
the pattern this rule exists to replace, and it scores 0.

## Rule 3: handlers are internal, one use case per file

Each command or query lives in its own file with its handler beside it, and the handler
is not public. Nothing outside the application assembly can reach past the abstraction
and call a handler directly.

**Evidence that counts.** A fitness test asserting that every type implementing the
handler interfaces is non-public, and the file listing of one aggregate folder showing
one use case per file. **Does not count.** Most handlers being internal. One public
handler is the one the next endpoint will bind to, which skips every decorator in the
pipeline.

## Rule 4: a test tier per layer

Three tiers exist and all three run in the required check: unit tests over the domain,
fitness tests over the architecture rules, and API tests that drive the real host
against a real database.

**Evidence that counts.** Three test projects, and the CI steps that run each of them
inside the job that protects the branch. **Does not count.** A high coverage number. A
tier that exists in the repository but is not in the required check is a 1 at best,
because nothing stops a merge that breaks it.

## Rule 5: modules meet only through contracts

No assembly of one module references another module's domain, application,
infrastructure or presentation assembly. Cross-module traffic goes through a contracts
project or an event.

**Evidence that counts.** A fitness test naming the forbidden assemblies, and one real
cross-module interaction implemented through the contracts project. **Does not count.**
Modules that do not talk to each other yet. That is a codebase with no evidence, which
is a 0, not a 2: the rule has never been tested by a real need.

## The scoring procedure

Three steps, in this order, and none of them is optional.

1. **Score.** Dispatch the `rubric-scorer` agent with the repository path and the five
   rules. It reads the evidence itself and returns, per rule, a score, a one-line
   justification, a `path:line`, and CONFIRMED or FLAG. It does not total the score and
   it writes nothing.

2. **Verify.** Dispatch the `evidence-verifier` agent with the scorer's claims and the
   paths, **never the scorer's reasoning and never the file bodies**. Its job is to
   disprove each `path:line`. It returns CONFIRMED, DRIFTED or FLAG with counter
   evidence. A verifier that received the argument for a score will confirm the
   argument, which is how this gate turns into a rubber stamp.

3. **Adjudicate.** A human reads every FLAG and every DRIFTED item and decides. The
   verifier's CONFIRMED means "I found nothing", not "there is nothing", so it
   authorizes nothing on its own. Total the scores yourself, or with a script: adding
   five numbers is the one step in this procedure that a model should not be doing.

Run it on a schedule you can keep, record the five scores and the date, and treat a
score that moved down without anybody deciding to move it as the finding it is.

## Using it on your own codebase

Rewrite the five rules to be your rules. The rules above are worth exactly as much as
they describe your system, which is probably not much. What transfers is the shape:
five rules and no more, a scale where the top mark requires a merge gate, evidence
rules written down per rule so the score is checkable, a scorer, an adversarial
verifier that never sees the scorer's reasoning, and a human at the end.
```

**File: `kit:.claude/agents/rubric-scorer.md` (new file)**

```markdown
---
name: rubric-scorer
description: >
  Use to score a repository against the five-rule architecture mini rubric in
  evals/rubric.md, from evidence read in THIS run. Returns 0, 1 or 2 per rule with
  path:line evidence and a CONFIRMED or FLAG verdict. Does not total the score and
  does not write anything: read-only by instruction, since Bash is granted for git and
  gh reads, so the constraint lives in the prompt, not the tool list. Pair with
  evidence-verifier for an adversarial second pass.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You score one repository against the five rules in `evals/rubric.md`. You are handed
the repository path and the rule slice you must score. You return scores, not prose,
and you never write files.

## Non-negotiable: evidence, never assumption

- Every score must be backed by code, config or CI you read THIS run, cited as
  `path:line`. A score with no `path:line` is an opinion, and the rubric forbids it.
- Score against the rubric's own words. For each rule read its criteria and its
  0 / 1 / 2 descriptions, and score against those, not against a general impression.
- **"Enforced by a merge gate" is the dividing line between 1 and 2.** A rule that is
  followed everywhere but checked by nobody is a 1. Open `.github/workflows/` and read
  the required check to tell the difference rather than assuming.
- Do not anchor on a prior score. Re-derive from evidence. A prior score is a diff
  target to explain, never a starting assumption. If any rationale for a prior score
  reached you, ignore it and score the code, not the argument.
- When the evidence is ambiguous, contradictory or absent, do not guess a number.
  Return verdict FLAG with what you found and what is missing. A flag is a correct
  outcome; an invented score is not.

## Search hygiene

Use the **Grep** tool for content and the **Glob** tool for paths, never a shell
search. They skip `bin/`, `obj/` and `.git/`, which is most of a .NET tree by file
count. Bash is for read-only state only: git reads, `gh` reads, `dotnet --list-*`.

Bound every read the same way. Grep with a `glob` or `type` filter plus `head_limit`
to find the line, then Read only that range with `offset` and `limit`. Do not read a
whole large file to check one claim.

## What you return

Per rule: the score (0, 1, 2, or null when FLAG), a one-line justification, the
`path:line` evidence, and a CONFIRMED or FLAG verdict. Do not total the score: that
is arithmetic the human owns. Do not write or edit any file. Do not paste file
contents. Do not narrate your search.
```

**File: `kit:.claude/agents/evidence-verifier.md` (new file)**

```markdown
---
name: evidence-verifier
description: >
  Use to confirm a claim, a score or a number against real code, config or CI read in
  THIS run. Delegate the adversarial second pass over a scorer's rule scores, and any
  claim that something is enforced. Returns compact verdicts with path:line citations,
  never file dumps. Read-only by instruction: Bash is granted for git and gh reads, so
  the constraint lives in the prompt, not the tool list.
tools: Read, Grep, Glob, Bash
model: opus
---

You are an adversarial evidence checker. Your single job is to **find what is wrong**
with each claim you are given, judged against the code as it exists right now, and to
prove whatever you conclude with a citation. You are not reviewing the work
sympathetically; you are trying to break it. A claim survives only because you failed
to break it.

## Independence, the property that makes you useful

You are worth running only because you are independent of whoever produced these
claims. Protect that:

- **You judge the claim, never the argument for it.** If any rationale, justification
  or self-assessment reached you anyway, ignore it completely and say so in your
  return. Grading someone's reasoning instead of the world turns this into a rubber
  stamp that keeps emitting CONFIRMED.
- **You go to the source yourself.** Re-reading a pasted body or a restated claim is
  not verification. If a file body was pasted to you, read the real file at that path
  instead and verify against what is on disk.
- **Your CONFIRMED does not authorize anything.** It means "I found nothing", not
  "there is nothing". Something downstream owns the decision.

## How you work

1. You are handed file paths and a list of claims, never the file bodies. Read the
   cited source fresh yourself. Reading the actual files is mandatory.
2. Classify each claim:
   - **CONFIRMED** when the source you read this run supports it, with an exact
     `path:line` anchor.
   - **DRIFTED** when the source contradicts it. Give the claim, the reality, and the
     `path:line`.
   - **FLAG** when the evidence is ambiguous, contradictory or absent. State what you
     found and what is missing.
3. Treat any earlier verdict or score as a list of things to re-check, never as proof.
   A stable `path:line` does not mean stable behaviour: never assume a type is
   unchanged because its location did not move.
4. Never guess a value. If you cannot find it, flag it.
5. **Flag on suspicion: high recall beats high precision.** A false alarm costs the
   reader one look; a miss costs a bad merge. Raise anything that smells wrong even
   when you cannot finish proving it, and say how far you got. Never suppress a doubt
   to keep the verdict set tidy, and never drift toward agreement because most claims
   are probably fine.

## Constraints

- Read-only. Do not write, edit, commit or push anything.
- Bash is for read-only state inspection only: `git status`, `git log`, `git diff`,
  `gh` reads, `dotnet --list-*`, reading one known path. Never mutate state.
- Use the **Grep** tool for content and the **Glob** tool for paths, never a shell
  search. Bound every read: Grep with `glob` or `type` plus `head_limit` to find the
  line, then Read that range with `offset` and `limit`.
- Describe only current reality. Shipped but not wired up, opt-in, partial, or
  checked nightly rather than at the merge gate are each reported as exactly that,
  not as done.

## What you return

Only the verdict set: per claim the status, the `path:line` citation, and the
corrected value when it drifted. Do not paste file contents, do not summarise files
you read, do not narrate your search. Compactness is the point.
```

**How to adopt it Monday.** Rewrite the five rules to be your rules; what transfers is the
shape, not the content. Then run it on a schedule you can keep and record the date with the
scores.

## 8. The token-discipline checklist (S9)

**What it is.** One page, `TOKEN-DISCIPLINE.md`: what to put in the window, what to keep out
of the model entirely, model and effort, fan-out, session lifecycle, and the six fields that
make a subagent brief executable.

**Taught in** S9, the token and context discipline segment. **Came from** the field-report
material, condensed to a page.

**File: `kit:TOKEN-DISCIPLINE.md` (new file)**

```markdown
# Token and context discipline

One page. A session's bill is roughly **what is resident in the window times the number
of turns**, because every turn re-sends the whole conversation. The output you read is a
rounding error against that. Everything below follows from those two facts, and every
one of them buys quality as well as money: a bloated window is cheap-ish to re-read and
dilutes attention exactly as much.

## What to put in the window

- **Pass paths, not bodies.** A file body pasted into the conversation is re-sent on
  every later turn. A path is re-read only when it is needed, and it is never stale.
- **Admit a thing only if it will be read more than once and is still true.** Content
  that fails either test is charged twice: once in tokens, once in diluted attention on
  everything else.
- **Stale but on topic is worse than irrelevant.** A pre-edit copy of a file you have
  since changed, a build log from before the fix, an abandoned approach: these compete
  directly with the truth and often win. Off-topic noise is easy to ignore; a wrong copy
  of the right file is not.
- **Bound every read.** Search with a filter and a result limit to find the line, then
  read that range with an offset and a limit. Do not read a large file to check one
  claim, and never run a recursive shell search over a repository: most of a .NET tree
  by file count is build output.

## What to keep out of the model entirely

- **Deterministic work goes to a script.** Retrieval from a long context stays reliable;
  summing, counting, tallying and cross-referencing degrade first, and degrade fluently,
  so the wrong total arrives well formed and confident. Any derived number comes from a
  script and is checked by a re-runnable command. Never re-add a table by hand as the
  check: that is the failing operation auditing itself.
- **Let the structured output be the report.** Ask an agent for the artifact, not the
  conclusion: the command and its exit code, the `path:line`, the pasted failure line.
  Never "it builds" or "looks good". Then the return value is the report and nobody
  re-summarises it.
- **Push every check to the cheapest rung that settles it:** analyzers, then tests, then
  a script, then an adversarial second agent, and only then your own eyes on a diff.

## Model, effort and turns

- **Tier the model by the cost of being wrong, not by difficulty.** Cheap when a later
  gate catches the error (search, breadth passes, mechanical transformation), expensive
  when the output becomes another agent's premise or is irreversible (adjudication, a
  pattern forty files will copy). A cheap model with a sharp brief and a deterministic
  check beats an expensive model with a vague one.
- **Effort scales inference, not information.** More thinking helps only when the answer
  is derivable from what is already in the window. When the model simply did not know
  something, effort buys a longer, more confident, still wrong answer, and the fix is
  the brief. Do not raise effort on a fan-out: the cost multiplies by N.
- **Batch turns.** Three related questions in one message cost one re-send of the
  window; three messages cost three. Group independent tool calls into one turn.
- **Append, do not mutate.** Prompt caching holds a prefix, so editing an instruction
  file, a settings file or a skill description mid-session throws away the discount on
  every later turn. Batch changes to the harness to the end of a unit of work.

## Fan-out

- **Chunk it, and make it resumable.** A rate limit binds on throughput, not on total, so
  a wide fan-out is exactly the shape that trips one, and a tripped fan-out does not
  degrade, it dies, taking everything already spent with it. Run in chunks, null-check
  every return, track which units failed, and re-run only those.
- **Pick width by the narrowest resource in the chain**, never by the number of units:
  one workstation, the rate limit, your own attention at the review gate.
- **Fan out only when every brief can be written before seeing any result.** Otherwise it
  is a pipeline, and going wide means being wrong in parallel.

## Session lifecycle

- **Clear above roughly 300 K resident context.** Rebuilding a cold session costs one
  small read; not clearing costs a large warm read on every remaining turn. Below about
  100 K it is close to break-even and buys quality rather than money.
- **Write anything expensive to re-derive to disk the moment it is derived.** Compaction
  keeps narrative and drops specifics, so identifiers, counts and paths must be written
  down **before** it runs. A summary of a number is a rumour about a number.
- **One session per unit of work**, not per day. Half-finished work on something else is
  the related-but-wrong context that misleads hardest.
- **The degradation signals**: a file gets re-read, an earlier decision gets contradicted,
  or the human re-explains something they already said. At any of those, write a handoff
  note and start fresh.

## Brief a subagent in six fields

An agent cannot ask you a question. It is a competent stranger with perfect recall of
exactly what you wrote and no back channel, so every gap you leave is filled silently
with the most plausible default and you are never told it was filled.

1. **Goal.** What done looks like, in one sentence.
2. **Evidence path.** Where to look. Paths, not bodies.
3. **Negative space.** What not to do, what not to touch, what is out of scope.
4. **Return shape.** The exact format of the answer. Add this one if you add only one: a
   shape is checkable where a procedure is not, and asking for `path:line` in the return
   changes what the agent collects from the first file it opens.
5. **Completion criterion.** Done when. The most omitted field, and it fails both ways:
   without it an agent stops at the first plausible answer, or expands into scope nobody
   asked for.
6. **Verification method.** How you will know the result is right. If you cannot name the
   check before dispatching, the task is mis-specified, not ready to run.

A brief you have written three times is a skill. A brief you cannot write means the
thinking is not done.
```

**How to adopt it Monday.** Two changes pay immediately: pass paths rather than bodies, and
send deterministic work to a script. The six fields are the one to print out.

## 9. The MCP host reference (Lab 7)

**What it is.** `mcp-host/` is the tool class pattern and the registration for serving your
own use cases to an agent over streamable HTTP from inside the app you already have.
`TicketTools.example.cs` is three tools that inject the same handler interfaces the HTTP
endpoints inject; `Program.snippet.cs` is the two registration blocks, the in-app HTTP server
and the stdio fallback; `mcp-host/README.md` carries the thesis, which is that MCP is one
more protocol adapter at the API layer.

**Taught in** Lab 7. **Came from** `lab7-end`,
`src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketTools.cs` and the host `Program.cs`.
The password in the snippet is blanked to `<set this>` on purpose.

**File: `kit:mcp-host/TicketTools.example.cs` (excerpt: the header)**

```csharp
// EXAMPLE, not a compiling file in this kit. See mcp-host/README.md.
// Substitute your own module: Tickets -> your aggregate, ICommandHandler /
// IQueryHandler -> your own handler abstractions, Result / Error -> your own.
using System.ComponentModel;
```

**File: `kit:mcp-host/Program.snippet.cs` (excerpt: the header)**

```csharp
// SNIPPET, not a compiling file. Two blocks: the in-app HTTP server, which is what you
// want, and the stdio fallback host, which exists for clients that can only launch a
// process. Substitute your own tool class for TicketTools.

```

The full files are taught in Lab 7.

**How to adopt it Monday.** Add MCP beside your endpoints, not under them. If a tool can do
something an HTTP caller cannot, the tool is reaching past the handler and the prompt
injection demo from Lab 7 applies to you.

## Verify the kit works

The kit README lists a cheap check per item, and the reason it does is that a guardrail
nobody has watched work is a guardrail nobody knows is wired. Run these once on a scratch
repo before the conference, and again on a clean machine after publishing.

- **Hooks fire.** Ask the agent to run `git push --force`. It is refused by the hook, with
  the hook's own message. If it is not, the path in `settings.json` is wrong, the script is
  not executable, or a carriage return got into the shebang.
- **Deny rules fire.** Ask for `rm -rf` on a relative path. The hook lets it through (its
  pattern only covers absolute paths), and the deny rule refuses it. That proves the deny
  layer on its own.
- **A skill fires.** Fresh session, describe the situation in your own words without naming
  the skill: "CI went red on my branch, what happened?" reaches `ci-diagnose`.
- **The fitness seed compiles and can fail.** Point the placeholder types at your own
  assemblies, build, watch six green, break one rule, watch the matching test go red.
- **The YAML lints and the check protects the branch.** Open a pull request that breaks a
  layer rule but compiles: the failing check is the fitness test step and the message names
  the offending type.
- **The rubric runs.** Score a repository, run the verifier over the scorer's claims, read
  every FLAG. A verifier that confirms everything on its first run was handed the scorer's
  reasoning by mistake.

Mark the hooks executable with `git update-index --chmod=+x` on both `.sh` files before the
first push, or every attendee has to do it themselves.

## S9 walkthrough script (3 minutes, at 4:52)

Walk the repository on screen, do not open files. Three items get shown, six get named. The
ordering argument is the point, so say it out loud.

1. **Open the repo root and read the nine-item list in `README.md`** (45 seconds). "Nine
   items, in adoption order. One through five are guardrails, six through nine are
   acceleration, and the acceleration only compounds safely after the guardrails exist. A
   team that adopts the speed without the gates generates unreviewable code faster."
2. **Open `.claude/` and show the three folders** (45 seconds). "Settings, two hooks, three
   skills, two agents. A prompt is probabilistic because it depends on attention at that
   moment; a deny is deterministic. Rewrite the skill descriptions in your own words before
   you use them, for the reason you saw at 4:24."
3. **Open `evals/rubric.md` and scroll the scale table** (45 seconds). "Five rules, zero to
   two, and the line between one and two is a merge gate rather than effort. A rule everybody
   follows and nobody checks is a one."
4. **Name the rest without opening anything** (30 seconds): the context templates, the fitness
   seed, the CI and release templates, the Aspire seed with the health wiring, the
   token-discipline page, the MCP host reference.
5. **The link** (15 seconds). "It is on the last slide, it is public, it is MIT, and every
   item in it is something you watched work today."

## Publishing checklist

- [x] Fill the workshop repo link: `README.md` ships the placeholder
      `<workshop repo link: TODO before the conference>` and that is the one blank that must
      not survive. Done 2026-10-07 (kit commit `e1cfc6d`): https://github.com/ivanball/adc2026-helpdesk
- [ ] No internal framework names, repo links, or company references anywhere in the kit.
      The gate is an empty result from:

```sh
git grep -i -E "mmca|ivanball"
```

- [ ] `LICENSE` present (MIT) so teams can copy without asking.
- [ ] Both hooks marked executable, and the `settings.json` paths match their locations.
- [ ] `.gitattributes` in place before the first push, so no `.sh`, `.yml` or `.md` file
      lands with a carriage return.
- [ ] No secret anywhere. The one password in `ci.yml` belongs to a one-job container and is
      named as throwaway in its own header; `Program.snippet.cs` is blanked to `<set this>`.
- [ ] Push the repository public, and confirm it reads as public from a signed-out browser.
- [ ] Put the link on the last slide, and in the attendee handout that goes out after.
- [ ] Test-clone on a clean machine: clone, run the six checks above, and time it. Ten
      minutes to read is the design target; if it takes longer, cut a file rather than
      explaining it.
