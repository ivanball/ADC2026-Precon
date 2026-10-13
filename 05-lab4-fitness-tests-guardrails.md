# Lab 4 (12:50-1:30, 40 min): Fitness tests and guardrails: rules that bind humans AND the AI

**Type:** short lecture + lab + guardrails walkthrough. **Goal:** attendees turn the layer
rules from CLAUDE.md into executable tests, then watch those tests catch the agent violating a
rule on purpose. This is one of the two never-cut moments of the day. Snapshot branch:
`lab4-end`.

**Room note:** this is the first block after lunch and it opens with a lecture, so start on
time and start loud. Attendees come back with a cold build; the very first instruction is
"run the tests you had green before lunch" while you talk over the slide.

**Teaching beats:** "a rule that is not executable is a suggestion"; the same gate stops a
rushed human and a confident agent; tool-side guardrails (permission modes, deny rules,
hooks) are the same idea one level up; and the credentials you hand the agent in CI are
the same idea one level up again.

## Rescue: starting from the snapshot (the handout prints this under its snapshot line)

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

## Minute-by-minute

| Time | Beat | Min |
|------|------|-----|
| 12:50 | Lecture: fitness functions in one slide; anatomy of a NetArchTest test | 8 |
| 12:58 | Lab 4a solo (Steps 1-2): describe rules in English, agent writes the tests | 10 |
| 1:08 | Lab 4b solo (Step 3): THE FLIP: ask the agent to break a rule, watch the fitness tests refuse | 8 |
| 1:16 | Debrief: the thesis lands | 4 |
| 1:20 | Step 4, guardrails beats 1 and 2: deny rules in `.claude/settings.json`, then the two hooks | 4 |
| 1:24 | Step 4, guardrails beat 3: permission modes, and why the sandbox stays off | 3 |
| 1:27 | Step 4, guardrails beat 4: least-privilege short-lived tokens for the agent in CI | 3 |
| 1:30 | Hand off to Lab 5: Ship it | |

## Files this session touches

Everything the branch `lab4-end` adds on top of `lab3-end`. Nothing else in the repo changes
during this block. Seven files, `git diff --stat lab3-end lab4-end` = 167 insertions, 12
deletions. Bold **manual path** citations mark content needed only by attendees not using an
agent (highlighted in red in the web version); on the AI path the agent writes the tests from
`docs/architecture-rules.md`.

| File | Change | Content |
|------|--------|---------|
| `docs/architecture-rules.md` | new (7 lines) | handout lab4, step 1 ("the rules, in English"); also reproduced in Lab 4a below |
| `tests/Helpdesk.ArchitectureTests/LayerRulesTests.cs` | new (77 lines) | handout lab4, **"Step 2, manual path: the five tests"** (whole file, reprinted below under "Lab 4a Step 2, manual path"); rule 1 plus the `Offenders` helper is excerpted in the Lecture below |
| `tests/Helpdesk.ArchitectureTests/PlaceholderTests.cs` | delete (12 lines) | no fence needed: the one-assert placeholder from the Lab 1 skeleton that kept the empty test project green. `LayerRulesTests` replaces it; handout lab4 Step 2 now says to delete it (the rehearsal agent did NOT delete it unprompted) |
| `.claude/settings.json` | new (38 lines) | guardrails beat 1 (allow and deny lists) and beat 3 (`defaultMode`; no `sandbox` block, by design); wires both hooks; also in handout lab4, "Guardrails" |
| `.claude/hooks/block-dangerous.sh` | new (22 lines) | guardrails beat 2, first script; also in handout lab4 |
| `.claude/hooks/confirm-merge.sh` | new (17 lines) | guardrails beat 2, second script; also in handout lab4 |
| `.gitattributes` | new (1 line) | `*.sh text eol=lf`. Mention in one sentence: a hook script that lands with CRLF on a Windows checkout dies in the shebang, and a guardrail that silently does not run is worse than no guardrail |

Test count on `lab4-end`: 11 green (Domain 4, Architecture 5, Api 2). Say the number out loud
after Lab 4a; attendees with 12 skipped the `PlaceholderTests.cs` delete, attendees with 10
lost a rule. Two red Api tests with a `SqlException` means the compose SQL container is down
(typical on a fresh rescue clone): `docker compose up -d`, then rerun. The handout prerequisite says so.

Not listed (deliberately): `bin/`, `obj/`, and the project file itself. The
`NetArchTest.Rules` package reference already ships in the Lab 1 skeleton's
`Helpdesk.ArchitectureTests.csproj`, so no `dotnet add package` is needed in this block.

## Lecture (8 min)

- Architecture erodes one "just this once" at a time. Documents do not stop erosion; builds
  do. An architecture fitness test is a unit test whose subject is the dependency graph.
- Anatomy on one slide (NetArchTest.Rules, already referenced in the skeleton):

*Instructor only (not in the handout).*

**File: `tests/Helpdesk.ArchitectureTests/LayerRulesTests.cs` (excerpt: the shared helper plus rule 1 of the 5 that Lab 4a produces)**

```csharp
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
```

- The failure message matters: a fitness test that fails cryptically gets deleted; one that
  names the offending types gets thanked.

## Lab 4a: English in, tests out (10 min)

### Lab 4a Step 1: the rules, in English

Attendees write (or copy from the handout) `docs/architecture-rules.md`:

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

### Lab 4a Step 2, AI path: the prompt

What attendees do (handout lab4, "Step 2, AI path: the prompt", word for word):

> Read docs/architecture-rules.md and implement each rule as a test in
> Helpdesk.ArchitectureTests using NetArchTest.Rules. One test per rule, named after the rule.
> Every failure message must list the offending type names. Run the tests and show me the
> results. Do not modify any project other than Helpdesk.ArchitectureTests.

What the agent should produce: one test file in `Helpdesk.ArchitectureTests` (its own name; the
rehearsal agent wrote `ArchitectureRulesTests.cs`) with five NetArchTest tests named after the
rules, rule 4 selecting BOTH handler interfaces, each failure message naming the offenders; it
leaves `PlaceholderTests.cs` in place, so the run reads 12 until the attendee deletes it, then 11
(rehearsed 2026-10-06: 44 s, and the agent itself called rule 5 "a weak guard today").

Review checklist while floating: do the tests actually FAIL if broken (a test that can never
fail is decoration)? Rule 4 is the interesting one; the agent must combine
`.That().ImplementInterface(typeof(ICommandHandler<,>))` with `.Should().NotBePublic()` and
attendees should check it found both handler interfaces. Rule 5 is honestly vacuous on this
branch: only SharedKernel sits outside `Helpdesk.Tickets.*`, it references nothing, and a
reference to Tickets.Infrastructure would be a cycle. The handout says so; if an attendee spots
it first, that is the checklist working. The handout's "prove each test can fail" step (end of
Step 2, both paths) is a hand edit: the attendee makes `CreateTicketHandler` public, runs,
watches red, reverts. The handout gives the agent no permission to touch `src/`; asked to prove
its own tests, the rehearsal agent honoured the 4a fence and mutated its tests instead, which
proves the assertions, not the selections. If an attendee wants the agent to do it, they grant
`src/` for that one step explicitly and restore with `git checkout`.

### Lab 4a Step 2, manual path: the five tests

Manual path: the handout has all five tests written out; type rule 1 and 4, paste the rest.

What manual-path attendees do (handout lab4, "Step 2, manual path: the five tests"): create the
file below "(type tests 1 and 4, paste the rest)", then work through the steps after it. They are
numbered here for reference; the handout prints them as plain paragraphs in the same order.

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

Then, by hand:

1. Read the rule 5 note: "Rule 5 is honestly vacuous today: it scans only
   `Helpdesk.SharedKernel`, which references no other project, and making SharedKernel reference
   Tickets.Infrastructure would be a project cycle, so this test cannot fail yet. It becomes a
   real gate when a second module arrives (the comment at its end). Spotting that is what
   reviewing the tests is for."
2. Delete the Lab 1 `tests/Helpdesk.ArchitectureTests/PlaceholderTests.cs` (the five rules
   replace it; on the AI path too, since agents do not delete it unprompted).
3. Run the suite, 11 green (Domain 4, Architecture 5, Api 2):

   ```bash
   dotnet test Helpdesk.slnx
   ```

4. Prove test 1 can fail: add `using Microsoft.EntityFrameworkCore;` plus a `DbContext` field
   anywhere in Domain (it will not even compile without a reference, which is the compiler
   enforcing rule 1 before the test can). Prove test 4 instead: make `CreateTicketHandler`
   public, run, watch red, revert.
5. With every prove-it edit reverted and the suite green again, commit, so THE FLIP's
   `git checkout -- .` below lands back on these tests:

   ```bash
   git add -A && git commit -m "Architecture fitness tests"
   ```

## Lab 4b: THE FLIP (8 min)

### Lab 4b Step 3: THE FLIP

#### Lab 4b Step 3, AI path: ask the agent, verbatim

What attendees do (handout lab4, "Step 3: THE FLIP", word for word): "Ask the agent, verbatim:"
the prompt below, then read the handout's "Two outcomes, both wins" list, which is the same two
outcomes as the list below (its outcome 1 quotes
`EF Core leaked into Domain: Helpdesk.Tickets.Domain.TicketQueries`; its outcome 2 ends "Insist
once to see outcome 1.").

The moment the day is named after. Prompt (verbatim):

> For a demonstration: let the Ticket aggregate query itself. Add the
> Microsoft.EntityFrameworkCore package to Helpdesk.Tickets.Domain and add a public static
> class in the Domain project with a method that returns the open tickets from a DbContext.
> Make the change compile and run the full test suite.

Two acceptable outcomes, both wins; name them beforehand so attendees know what to watch for:

1. The agent makes the change, the build stays GREEN, and rules 1 and 2 go red naming the new
   type (`EF Core leaked into Domain: Helpdesk.Tickets.Domain.TicketQueries` in the rehearsal
   run). The agent reports the failure, possibly offering to revert. **The gate worked, and it
   worked where the compiler could not**: valid C#, wrong architecture. Say that sentence.
2. The agent refuses or pushes back, citing CLAUDE.md's layer rules or the "never add a NuGet
   package without asking" line. **The context file worked.** (Then have them insist once, to
   see outcome 1.)

Why this violation and not "reference Infrastructure from Application": that one never reaches
the fitness tests. Infrastructure already references Application, so the new reference is a
cycle and the build stops at restore with a circular-dependency error, and an agent
told to "make the change compile" may then break the cycle some other way. The Domain-to-EF
violation compiles cleanly, so the only thing standing in the way is the tests you just wrote.
Also not "make a handler public": attendees already do that to prove rule 4 in Lab 4a, and the
Lab 5 red PR and `lab8-demo` reuse the same violation, so the room has seen it.

What the agent should produce: outcome 1. `Microsoft.EntityFrameworkCore` 10.0.10 added to
Domain ("the same version Infrastructure uses") plus a `TicketQueries.cs`; build green with 0
warnings; rules 1 and 2 red, both naming `Helpdesk.Tickets.Domain.TicketQueries`;
`Failed: 2, Passed: 3` in the Architecture project (rehearsed 2026-10-06: 22 s, no refusal).

#### Lab 4b Step 3, manual path: the same change by hand

Manual path: the handout pins the package, `dotnet add ... package
Microsoft.EntityFrameworkCore --version 10.0.10` (the EF Core version the repo already uses).
An unpinned add pulls a newer patch and the build goes red on NU1605 package-downgrade errors
before any fitness test runs, which is not the outcome the room should watch.

What manual-path attendees run (handout lab4, "Step 3: THE FLIP", "**Manual path:**", word for
word):

```bash
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Domain package Microsoft.EntityFrameworkCore --version 10.0.10
```

Then create `src/Modules/Tickets/Helpdesk.Tickets.Domain/TicketQueries.cs` holding a
`public static class TicketQueries` (with `using Microsoft.EntityFrameworkCore;`) and a method
`Task<List<Ticket>> GetOpenTicketsAsync(DbContext db)` that returns
`db.Set<Ticket>().Where(t => t.Status == TicketStatus.Open).ToListAsync()`. Build: green.
`dotnet test Helpdesk.slnx`: rules 1 and 2 red, naming `Helpdesk.Tickets.Domain.TicketQueries`.

#### Lab 4b Step 3 revert (both paths)

Have everyone revert afterwards (or reject the edit): another habit beat, demonstrations do not
get committed. Put both lines on screen:

```bash
git checkout -- .
git clean -f src/
```

Call out the second line: `git checkout -- .` only restores tracked files, so the new class file
survives it and `git status` still lists it as untracked (caught in the 2026-10-11 rehearsal).
It cleans all of `src/`, not one path, because on the AI path the agent names the file itself
(`OpenTicketsQuery.cs` in the 2026-10-12 Mac run, where a hard-coded `TicketQueries.cs` path
removed nothing and Step 4's `git add -A` then staged the leftover). Clean tree, then 11 green, before Step 4.

## Debrief: land the thesis (4 min)

Say it plainly, this is the sentence the workshop was built to earn:

> "This morning the tests pinned WHAT the code does. These tests pin HOW the code is shaped.
> With both in place, delegation gets safe: a rushed teammate, a clever contractor, and a
> confidently wrong AI all hit the same wall, at build time, before review. You do not have to
> trust the agent. You have to trust your gates, and you wrote your gates."

Optional discussion question if a couple of minutes exist (else skip): "the outbox relay from
Lab 3 delivers at least once, so a consumer must be idempotent. Could you write a fitness test
for that?" (Honest
answer: not really structurally; it needs a behavioral test. Good tension to name: fitness
tests are necessary, not sufficient.)

## Guardrails on the tool side (10 min, paste along)

### Step 4: Guardrails (create the files)

Frame: "Fitness tests gate the CODE. The tool has the same layering for gating the AGENT'S
ACTIONS, and so does the CI account you hand it." Four beats. Attendees PASTE the four files
as you show them (handout lab4, Step 4: `.claude/settings.json`, both hooks, `.gitattributes`, reprinted below),
then run the handout's `git update-index --chmod=+x` / commit block (plus `chmod +x` on macOS,
Linux or Git Bash), so every repo matches `lab4-end` going into Lab 5, file mode included (the
branch records the executable bit on both hooks). Pasting only, no
typing: the beats run at the same pace. The files take effect the next time `claude` starts in
the repo; say so, or someone will look for a hook firing in the session they already have
open. And say the start command changes here: from now on plain `claude`, no
`--permission-mode default`, so the repo's `defaultMode: acceptEdits` applies (a CLI flag
overrides it). VS Code users pick the mode in the mode indicator; the extension ignores the
project's `defaultMode`.

#### Beat 1: permission prompts and deny rules (2 min)

Level 0 is the permission prompt: every write and every command asks. Fine for a workshop,
useless at scale. Fifty prompts a day, forty-nine of them `git status`, teaches a two percent
prior, and prompt fifty (the one that publishes or deletes) gets the same reflex click. So
allowlisting the routine work is a SAFETY measure, not a convenience. Level 1 is that policy
written down, checked into the repo, shared by the whole team:

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

The escaped quotes around `${CLAUDE_PROJECT_DIR}` are deliberate. Unquoted, a project path with a
space splits, the hook exits 127, and Claude Code treats that as a non-blocking error, so the
command runs. The 2026-10-12 Mac dry run proved it in a real session: the bare form let
`git reset --hard origin/...` through, the quoted form blocked it.

Read the lists out loud: `allow` is build, test and read-only git, all of it local and
repeatable; `deny` is drop a database, force-push, `rm -rf`, and reading `.env` or `.pem` files
(beat 4 comes back to those two). Point at what is NOT allowlisted,
because that is the actual lesson: nothing that leaves the machine.

Then point at the doubled rules and the `Bash|PowerShell` matcher (the handout explains it
under the file). Verified 2026-10-07 on Claude Code 2.1.292, Windows: the PowerShell tool is on
by default for claude.ai accounts; a Bash deny rule turns it off, but a single `PowerShell(...)`
rule in `settings.local.json` (written by any "Yes, and don't ask again" on a PowerShell command
in Labs 1-3) turns it back on, and then the Bash-only rules and a `Bash`-only hook matcher do not
see what it runs. With both shells covered, `echo gh pr merge 99` through PowerShell was
blocked by `confirm-merge.sh`, `git push --force` by `block-dangerous.sh`, and
`Remove-Item -Recurse` by the deny rule. The takeaway for the room: a guardrail written for one
tool does not cover another, so watch each one fire.

#### Beat 2: hooks, the rule the model cannot argue with (2 min)

A deny list lives inside the tool's own policy. A hook runs OUTSIDE the model: a script that
sees the tool call before it happens and can refuse it. Two ship on the branch.

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

The fourth file, from handout lab4 Step 4:

**File: `.gitattributes` (new file)**

```text
*.sh text eol=lf
```

Then, with all four files on disk (update-index needs them staged first, which `git add -A`
does), attendees record the executable bit on both hooks and commit (handout lab4 Step 4; works
in Git Bash and PowerShell alike):

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

On macOS, Linux or Git Bash, also set the bit on the working copy (no `chmod` in PowerShell,
and Windows does not need it):

```bash
chmod +x .claude/hooks/block-dangerous.sh .claude/hooks/confirm-merge.sh
```

Two things to call out while they are on screen. First, the jq fallback is deliberate and not
defensive padding: jq is missing on plenty of attendee machines, and a guardrail that errors
out when a dependency is absent is a guardrail that quietly stops guarding. Second, the
stories, one sentence each. An agent troubleshooting a migration error WILL eventually propose
dropping the database, politely and confidently, and the hook makes that a non-event instead
of a judgment call at 5pm. And in some repos merging a PR IS a production deploy, so
`confirm-merge.sh` encodes "this action is bigger than it looks" where it cannot be skipped.
Despite the name it does not prompt: it blocks every `gh pr merge` the agent tries (exit 2),
and the human runs the merge after reviewing the checks.
The transferable rule, now in its full form: **anything you would say twice in code review
belongs in CLAUDE.md; anything that must NEVER happen belongs in a hook.**

#### Beat 3: permission modes, and why the sandbox stays off (3 min)

Back to the top of the same file, the two blocks nobody reads.

`defaultMode` sets what happens when nothing else matches. Six values; the handout lists all
six, name them because attendees will pick one this afternoon:

- `default`: prompt on every edit and every command. Safest, slowest.
- `acceptEdits`: file edits inside the project apply without prompting; commands are still
  gated. What the branch uses, and the right setting for a lab, because an edit inside a git
  working tree is reversible with one command.
- `plan`: read, explore and propose; source edits stay blocked until you approve the plan
  (exploration commands still run, classifier-reviewed or prompted). This is where you send an
  agent to investigate a codebase you do not want it touching yet.
- `auto`: a classifier model reviews each action instead of you; since Claude Code v2.1.283
  the starting mode for interactive sessions, which is why Lab 1 began with
  `--permission-mode default`. A project settings file cannot set it.
- `dontAsk`: only pre-approved tools run, everything else is denied; for CI and scripts.
- `bypassPermissions`: nothing asks. Legitimate in a throwaway container with no credentials
  in it, and a bad idea on the laptop where you are signed into production.

Then the setting the file deliberately does NOT have: the `sandbox` block. Name it, because
attendees will meet it in the docs. It runs Bash under OS-level filesystem and network
isolation (Seatbelt on macOS, bubblewrap on Linux and WSL2), so a command that goes wrong
cannot WRITE outside the repo or reach a host you have not allowed, and with
`autoAllowBashIfSandboxed` those commands skip the prompt because the blast radius is bounded.
It can still READ anywhere unless you add `sandbox.filesystem.denyRead` entries; say that part
out loud, it is the one people get wrong.

Why it is off here, in one breath: the room is mixed. On native Windows it does nothing
(`claude` prints `Sandbox disabled: ... Commands will run WITHOUT sandboxing`, verified in the
2026-09-28 rehearsal). On macOS it is enforced strictly enough to break the labs: the 2026-10-12
Mac dry run saw the agent's sandboxed `dotnet build` and `dotnet test` hang about 5 minutes and
then fail with `Build FAILED. 0 Warning(s) 0 Error(s)` (MSBuild's local pipe denied,
`SocketException (13): Permission denied`), and sandboxed `gh` and NuGet restore could not reach
the network. Turning it on in a real repo means listing every such command in
`excludedCommands`; that is homework, not a lab step. Today the guardrails are the prompts,
the deny rules and the hooks, the same on every laptop.

Say the rule plainly, it is the one they should take home: **gate on reversibility and on
whether the action leaves the machine, not on how weighty it feels.** A commit feels big and
is trivially undone; a merge feels routine and ships to customers. Gate the second one.

#### Beat 4: least-privilege, short-lived tokens for the agent in CI (3 min)

Last level up, and the bridge to Lab 5. In forty minutes the agent gets a CI account, and the
question stops being "what may it run on my laptop" and becomes "what may it do to the repo
while nobody is watching". Answer: the least that makes the job work, for the shortest time
that makes the job work.

The agent-review workflow the instructor demos in Lab 5 (it ships on the reference branch and
in the starter kit) declares a scoped `permissions` block rather than
inheriting the default token: `contents: read`, `pull-requests: write`, `id-token: write`.
That is exactly enough to check out the code, leave review comments on the PR, and request an
OIDC identity, and nothing else. It cannot push to `main`, cannot edit workflows, cannot touch
another repo. The model API key is a repository secret, referenced by name, never a personal
token pasted into a file that gets committed on a bad Tuesday.

Why short-lived beats long-lived, in two sentences. The workflow token is minted for one run
and dies when the job ends, so a token that leaks into a log line is worthless by the time
anyone finds it. A personal access token in a config file is valid until somebody remembers to
revoke it, carries every permission its owner has, and is the single most common way an agent
setup turns into an incident.

And close the loop back to beat 1: the deny list is also where secrets go out of reach.
`Read(./.env)` and `Read(./**/*.pem)` sit in `deny` so the agent cannot pull credentials into
its context at all (both are in the snapshot `settings.json`; point at them). Context it never
had is context it cannot leak into a PR description.

## If things go wrong

- Lab 4a agent writes tests that pass vacuously (empty type selection): great catch to
  showcase; the fix: give the agent explicit permission (the handout prompt forbids it) to
  break each rule temporarily in `src/` (that step only), show the red run naming the offender, then
  `git checkout` and a clean `git status`.
- Lab 4b outcome 2 with a stubborn refusal even on insistence: demo outcome 1 yourself from
  the front; the point lands either way.
- An attendee ends Lab 4a with 12 tests instead of 11 (`PlaceholderTests.cs` survived) or with
  10 (a rule went missing). One line, keep moving: `git diff --stat lab3-end` on their own work.
- Someone copies the hooks and they never fire: on a Windows checkout without the
  `.gitattributes` line the scripts land with CRLF and bash chokes on the shebang. Good
  thirty-second story, it is exactly the "half-working is worse than broken" point.
- Running long, in this order: drop beat 4 to one spoken sentence ("Lab 5 shows the scoped
  token"), then collapse beats 1 and 2 to the settings file plus `block-dangerous.sh` only.
  Beat 3 stays, it is the newest material in the block. The flip is never cut.
- Running short: open `.claude/settings.json` live, point at `Read(./.env)` on the deny list,
  create a dummy `.env`, and ask the agent to read it in front of the room.
