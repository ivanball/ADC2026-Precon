# Lab 4 Handout: Fitness tests, then THE FLIP (12:50-1:30)

Snapshot branch if you get stuck: `lab4-end`
Prerequisite: `lab3-end` plus your Lab 3 work (pull the branch if your solution diverged
during the morning), and the SQL container up (`docker compose up -d`): two of the 11 tests are
API tests against it, and they fail with a `SqlException` without it.

**Starting from the snapshot instead of your own work?** Clone it into a new folder and make
it your `main` (a plain `git checkout lab3-end` leaves your next commits on a branch named
`lab3-end`):

```sh
git clone --branch lab3-end https://github.com/ivanball/adc2026-helpdesk.git helpdesk-lab4
cd helpdesk-lab4
git switch -c main --track origin/lab3-end
dotnet tool restore
```

`dotnet tool restore` installs the `dotnet ef` version the snapshot pins (from `lab3-end` on
the repository carries a tool manifest, and `dotnet ef` refuses to run until it is restored,
even with the global tool installed).

**Goal:** turn the layer rules into executable tests, prove each test can fail, then ask the
agent to violate a rule on purpose and watch the gates hold.

## Step 1: the rules, in English

Create `docs/architecture-rules.md`:

**File: `docs/architecture-rules.md` (new file)**

```markdown
Rules to enforce in Helpdesk.ArchitectureTests:
1. Tickets.Domain may depend only on Helpdesk.SharedKernel and System.
2. Tickets.Domain must not reference Microsoft.EntityFrameworkCore anywhere.
3. Tickets.Application must not depend on Tickets.Infrastructure or Tickets.Presentation.
4. Command and query handlers must be internal, not public.
5. No type outside Helpdesk.Tickets.* may depend on Helpdesk.Tickets.Infrastructure
   (only the Host composition root may, by exception).
```

## Step 2, AI path: the prompt

> Read docs/architecture-rules.md and implement each rule as a test in
> Helpdesk.ArchitectureTests using NetArchTest.Rules. One test per rule, named after the
> rule. Every failure message must list the offending type names. Run the tests and show me
> the results. Do not modify any project other than Helpdesk.ArchitectureTests.

## Step 2, manual path: the five tests

Create the file below (type tests 1 and 4, paste the rest):

**File: `tests/Helpdesk.ArchitectureTests/LayerRulesTests.cs` (new file)**

```csharp
using Helpdesk.Tickets.Application.Abstractions;
using Helpdesk.Tickets.Domain;
using NetArchTest.Rules;

namespace Helpdesk.ArchitectureTests;

public class LayerRulesTests
{
    private static string Offenders(TestResult result) =>
        string.Join(", ", result.FailingTypeNames ?? Enumerable.Empty<string>());

    [Fact]
    public void Rule1_Domain_depends_only_on_SharedKernel_and_System()
    {
        var result = Types.InAssembly(typeof(Ticket).Assembly)
            .Should()
            .OnlyHaveDependenciesOn(
                "Helpdesk.SharedKernel",
                "Helpdesk.Tickets.Domain",
                "System")
            .GetResult();

        Assert.True(result.IsSuccessful, "Domain grew a dependency: " + Offenders(result));
    }

    [Fact]
    public void Rule2_Domain_does_not_reference_EntityFrameworkCore()
    {
        var result = Types.InAssembly(typeof(Ticket).Assembly)
            .ShouldNot()
            .HaveDependencyOn("Microsoft.EntityFrameworkCore")
            .GetResult();

        Assert.True(result.IsSuccessful, "EF Core leaked into Domain: " + Offenders(result));
    }

    [Fact]
    public void Rule3_Application_does_not_depend_on_Infrastructure_or_Presentation()
    {
        var result = Types.InAssembly(typeof(ICommandHandler<,>).Assembly)
            .ShouldNot()
            .HaveDependencyOnAny(
                "Helpdesk.Tickets.Infrastructure",
                "Helpdesk.Tickets.Presentation")
            .GetResult();

        Assert.True(result.IsSuccessful, "Application reached outward: " + Offenders(result));
    }

    [Fact]
    public void Rule4_Handlers_are_internal()
    {
        var result = Types.InAssembly(typeof(ICommandHandler<,>).Assembly)
            .That()
            .ImplementInterface(typeof(ICommandHandler<,>))
            .Or()
            .ImplementInterface(typeof(IQueryHandler<,>))
            .Should()
            .NotBePublic()
            .GetResult();

        Assert.True(result.IsSuccessful, "Public handlers found: " + Offenders(result));
    }

    [Fact]
    public void Rule5_Only_the_Host_touches_Tickets_Infrastructure()
    {
        // Assemblies outside Helpdesk.Tickets.* that are NOT the composition root.
        var result = Types.InAssembly(typeof(Helpdesk.SharedKernel.Entity).Assembly)
            .ShouldNot()
            .HaveDependencyOn("Helpdesk.Tickets.Infrastructure")
            .GetResult();

        Assert.True(result.IsSuccessful, "Infrastructure leaked: " + Offenders(result));
        // The main branch extends this list when a second module arrives.
    }
}
```

Rule 5 is honestly vacuous today: it scans only `Helpdesk.SharedKernel`, which references no
other project, and making SharedKernel reference Tickets.Infrastructure would be a project
cycle, so this test cannot fail yet. It becomes a real gate when a second module arrives (the
comment at its end). Spotting that is what reviewing the tests is for.

Delete the Lab 1 `tests/Helpdesk.ArchitectureTests/PlaceholderTests.cs` (the five rules
replace it; on the AI path too, since agents do not delete it unprompted). Then run the
suite, 11 green (Domain 4, Architecture 5, Api 2):

```bash
dotnet test Helpdesk.slnx
```

Then prove test 1 can fail: add
`using Microsoft.EntityFrameworkCore;` plus a `DbContext` field anywhere in Domain (it will
not even compile without a reference, which is the compiler enforcing rule 1 before the test
can). Prove test 4 instead: make `CreateTicketHandler` public, run, watch red, revert.

With every prove-it edit reverted and the suite green again, commit, so THE FLIP's
`git checkout -- .` below lands back on these tests:

```bash
git add -A && git commit -m "Architecture fitness tests"
```

## Step 3: THE FLIP

Ask the agent, verbatim:

> For a demonstration: let the Ticket aggregate query itself. Add the
> Microsoft.EntityFrameworkCore package to Helpdesk.Tickets.Domain and add a public static
> class in the Domain project with a method that returns the open tickets from a DbContext.
> Make the change compile and run the full test suite.

Two outcomes, both wins:

1. It makes the change, the build stays green, and the fitness tests go red: rules 1 and 2
   fail with the new Domain type named in the message (for example
   `EF Core leaked into Domain: Helpdesk.Tickets.Domain.TicketQueries`). It reports the
   failure. **The gate worked**, and it worked where the compiler could not: the code is
   perfectly valid C#, only the architecture is wrong.
2. It refuses, citing CLAUDE.md's layer rules or its "never add a NuGet package without
   asking" line. **The context file worked.** Insist once to see outcome 1.

**Manual path:** make the same change by hand. Pin EF Core to the version your
Infrastructure project already uses (10.0.10 on the snapshot branches; check
`Helpdesk.Tickets.Infrastructure.csproj`), because an unpinned add pulls a newer patch and the
build stops on NU1605 package-downgrade errors before any test runs:

```bash
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Domain package Microsoft.EntityFrameworkCore --version 10.0.10
```

Then create `src/Modules/Tickets/Helpdesk.Tickets.Domain/TicketQueries.cs` holding a
`public static class TicketQueries` (with `using Microsoft.EntityFrameworkCore;`) and a method
`Task<List<Ticket>> GetOpenTicketsAsync(DbContext db)` that returns
`db.Set<Ticket>().Where(t => t.Status == TicketStatus.Open).ToListAsync()`. Build: green.
`dotnet test Helpdesk.slnx`: rules 1 and 2 red, naming `Helpdesk.Tickets.Domain.TicketQueries`.

Afterwards, revert everything and reject any pending edits. Demonstrations do not get
committed. Run both lines (they work in Git Bash, PowerShell and cmd alike):

```bash
git checkout -- .
git clean -f src/
```

The first line restores tracked files only (the Domain `.csproj`); the class the agent added is a
new, untracked file (`TicketQueries.cs` on the manual path; the agent may pick another name), so
`git status` keeps listing it until the second line deletes it. The second line removes every
untracked file under `src/` (build output is ignored, so it stays), whatever the file is called.
`git status` then reports a clean tree, and `dotnet test Helpdesk.slnx` is 11 green again.

## Step 4: Guardrails (create the files)

Fitness tests gate the CODE. These gate the AGENT'S ACTIONS. Create the four files below (paste
them; their content matches `lab4-end`), so your repo matches the snapshot branch before Lab 5.
If you checked out `lab4-end` instead, the branch already records the executable bit on both
hooks, so you can skip the executable-bit block below.

They take effect the next time you start `claude` in this repo. From now on start plain
`claude`, with no `--permission-mode` flag: the file's `defaultMode: acceptEdits` then sets the
starting mode, and a CLI flag would override it. VS Code users pick the mode in the mode
indicator instead, because the extension does not read a project's `defaultMode`.

**File: `.claude/settings.json` (new file)**

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

The escaped quotes around `${CLAUDE_PROJECT_DIR}` keep the hooks working when your project path
contains a space. Without them the hook fails to start, and Claude Code treats a hook that
fails to start as a non-blocking error: the command it should have stopped runs anyway.

Every rule appears twice, once for `Bash` and once for `PowerShell`, and the hook matcher is
`Bash|PowerShell`. On Windows, Claude Code has a native PowerShell tool next to Bash, and a
`Bash(...)` rule or a `Bash` hook does not see a command it runs there. A Bash deny rule
normally switches the PowerShell tool off, but any `PowerShell(...)` rule switches it back on,
and Claude Code writes one into your `settings.local.json` every time you answer "Yes, and
don't ask again" to a PowerShell command. Covering both shells is what keeps these guardrails
true on every laptop in the room.

A deny list is policy inside the tool. A hook runs outside the model: it sees the command
before it happens and can refuse it. The jq fallback in both scripts is deliberate, since jq
is not installed everywhere and a guardrail that errors out is a guardrail that stopped
guarding.

**File: `.claude/hooks/block-dangerous.sh` (new file)**

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

**File: `.claude/hooks/confirm-merge.sh` (new file)**

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

Despite its name, `confirm-merge.sh` does not ask for confirmation: it blocks every
`gh pr merge` the agent attempts (exit 2) and tells the model that the human runs the merge
after reviewing the checks.

**File: `.gitattributes` (new file)**

```text
*.sh text eol=lf
```

On Windows, that one line is what keeps the scripts from landing with CRLF and dying in the
shebang. On macOS and Linux the hooks also need the executable bit, or they fail with
"permission denied". Record it in git with the two files named explicitly; these lines work in
Git Bash and PowerShell alike:

```bash
git add -A
git status --short
git update-index --chmod=+x .claude/hooks/block-dangerous.sh .claude/hooks/confirm-merge.sh
git commit -m "Agent guardrails"
```

Read the `git status --short` output before you commit: it should list only the three
`.claude/` files and `.gitattributes`. If it lists anything under `src/`,
THE FLIP is still in your working copy: run `git restore --staged src/ && git restore src/ && git clean -f src/`
(the last part deletes the new Domain file, whatever the agent named it), check
`git status --short` again and `dotnet test Helpdesk.slnx` is 11 green again, then commit. On Windows, `git add` may warn
that CRLF will be replaced by LF in the two scripts: that is `.gitattributes` working. The
repository stores LF, and the CRLF copy on your disk still runs under Git Bash.

On macOS, Linux or Git Bash, also set the bit on your working copy (there is no `chmod` in
PowerShell, and Windows does not need it):

```bash
chmod +x .claude/hooks/block-dangerous.sh .claude/hooks/confirm-merge.sh
```

**Permission modes, and why this repo leaves the sandbox off.** `defaultMode` decides what happens when
nothing else matches: `default` (Manual) prompts on every edit and command; `acceptEdits`
(used here) applies edits and simple file commands without prompting while still gating other
commands; `plan` reads, runs exploration commands and proposes a plan, but blocks source edits
until you approve it; `auto` lets a second model, a classifier,
review each action instead of you (and since Claude Code v2.1.283 it is the starting mode for
interactive sessions, which is why this morning began with `--permission-mode default`);
`dontAsk` runs only pre-approved tools and denies the rest, for CI and scripts;
`bypassPermissions` asks nothing, which is fine in a throwaway container and reckless on a
laptop signed into production. A project file can set any mode except `auto` and
`bypassPermissions`. The rule to take home: gate on reversibility and on whether the action
leaves your machine, not on how weighty it feels.

Claude Code also has a `sandbox` setting that runs Bash under OS-level filesystem and network
isolation (Seatbelt on macOS, bubblewrap on Linux and WSL2; native Windows has none and runs
commands unsandboxed). This repo deliberately leaves it off. On macOS it is enforced strictly
enough to break today's agent work: the agent's `dotnet build` and `dotnet test` hang and then
fail because the sandbox blocks MSBuild's local connections, and `dotnet restore` and `gh` cannot
reach NuGet or GitHub. When you turn it on in your own repos, list the commands that must reach
outside in `excludedCommands`, and remember it still lets commands READ anywhere unless you add
`sandbox.filesystem.denyRead` entries. Today the guardrails are the permission prompts, the deny
rules and the hooks: read each command before you approve it.

**Least-privilege tokens in CI (Lab 5 demos this).** The agent-review workflow declares its
own scoped `permissions` block, `contents: read`, `pull-requests: write`, `id-token: write`,
which is enough to read the code and comment on the PR and nothing more; the model API key is
a repository secret, never a personal token in a committed file. That workflow token is minted
per run and expires with the job, so a leak is worthless minutes later, while a personal
access token in a file stays valid until somebody revokes it and carries every permission its
owner has. Same idea in your settings file: `Read(./.env)` and `Read(./**/*.pem)` on the deny
list keep the agent from pulling secrets into its context in the first place (both are in the
settings file above).

## What just happened

The same tests that stop a rushed human stopped a confidently wrong AI, at build time,
before review. You do not have to trust the agent; you have to trust your gates, and you
wrote your gates.
