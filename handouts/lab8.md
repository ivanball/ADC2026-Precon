# Lab 8 Handout: The agent as judge (3:55-4:20)

Snapshot branch if you get stuck: `lab7-end`
Prerequisite: your own repository at the end of Lab 7, plus the starter kit repo cloned next to
it (step 1 shows how) or open in a browser tab. Nothing here needs the application running or the SQL container. The
agent path needs your agent's usual network access; the manual path needs nothing.

**Goal:** turn "is this codebase still the shape we said it was" into a question with a
checkable answer. You write one rule of your own, you score a repository against five rules
where every score has to point at a `path:line`, and then a second agent tries to break every
one of those scores. Twenty-five minutes, and the piece you take home is the shape, not the
five rules.

**An agent is optional here.** The rule-writing in step 2 is for everybody and it is the part
that transfers. Steps 3 and 4 each have a manual path that works with a text editor and a
neighbour, and the instructor runs the agent version once on the projector either way.

---

## Step 1: copy the three files into your repo

Three files come from the starter kit. You copy them, you do not type them. Run everything
below from the root of your own repository, in Git Bash on Windows or Terminal on a Mac:
`mkdir -p` and the `../` paths are bash (zsh runs them as printed), and cmd.exe and
PowerShell read them differently.

**1. Clone the kit next to your repository**, so both folders share one parent. It is public
at <https://github.com/ivanball/agentic-dotnet-starter-kit>, so no account is needed; skip this
if the kit is already there:

```bash
git clone https://github.com/ivanball/agentic-dotnet-starter-kit.git ../agentic-dotnet-starter-kit
```

The parent folder now holds both, whatever it and your repository are called:

```text
<parent folder>/
  <your repository>/            where you run every command in this lab
  agentic-dotnet-starter-kit/   the kit, only ever read from
```

**2. Copy the three files:**

```bash
mkdir -p evals .claude/agents
cp ../agentic-dotnet-starter-kit/evals/rubric.md evals/
cp ../agentic-dotnet-starter-kit/.claude/agents/rubric-scorer.md .claude/agents/
cp ../agentic-dotnet-starter-kit/.claude/agents/evidence-verifier.md .claude/agents/
ls evals .claude/agents
```

The `ls` lists `rubric.md` under `evals`, and `evidence-verifier.md` and `rubric-scorer.md`
under `.claude/agents`. If a `cp` says `No such file or directory`, the kit is not next to your
repository: `ls ..` must show `agentic-dotnet-starter-kit` beside your repository's folder.

**In Command Prompt (cmd.exe) instead?** `mkdir -p` answers `The syntax of the command is
incorrect.` and nothing is created. Use backslashes and `copy` there, still from the root of
your repository (the prompt ends in your repository's folder name, not its parent):

```bat
mkdir evals .claude\agents
copy ..\agentic-dotnet-starter-kit\evals\rubric.md evals\
copy ..\agentic-dotnet-starter-kit\.claude\agents\rubric-scorer.md .claude\agents\
copy ..\agentic-dotnet-starter-kit\.claude\agents\evidence-verifier.md .claude\agents\
dir evals .claude\agents
```

**No git, or the clone fails:** open the kit in a browser tab instead. Create the `evals` and
`.claude/agents` folders, then open each of the three files in the kit, view it raw, and save
its text at the same path in your repository.

What each one is, in one line:

| File | Lines | What it does |
|------|-------|--------------|
| `evals/rubric.md` | 109 | Five architecture rules, a 0/1/2 scale, what counts as evidence per rule, and the three-step scoring procedure |
| `.claude/agents/rubric-scorer.md` | 49 | The judge. Reads evidence, scores each rule, cites `path:line` for every claim. Never totals, never writes |
| `.claude/agents/evidence-verifier.md` | 71 | The adversary. Tries to disprove every citation the judge produced. Never writes |

Commit the three files before any agent runs, so `git status` afterwards shows anything the
judge or the adversary wrote:

```bash
git add -A && git commit -m "Eval rubric and grading agents"
```

Then start a FRESH `claude` session in the repo (`/exit`, then `claude`). Your repo had no
`.claude/agents/` folder before this copy, and Claude Code only watches agent folders that
existed when the session started, so the session you copied them from answers "Agent type
'rubric-scorer' not found". A fresh session is also the right habit for
judging: no leftover context from the code you wrote this afternoon.

The one line in the rubric that everything else hangs off:

**File: `kit:evals/rubric.md` (excerpt: the scale, identical for all five rules)**

```markdown
| Score | Meaning |
| --- | --- |
| 0 | The rule is broken somewhere in the codebase, or there is no evidence it is followed. |
| 1 | The rule is followed everywhere you looked, but nothing would stop a change that broke it. Convention only. |
| 2 | The rule is followed AND a check enforces it on every merge: a test in the required CI job, an analyzer at error severity, or a build that fails. |

The line between 1 and 2 is a merge gate, not effort. A rule checked by a nightly job,
a script somebody remembers to run, or a code review is a 1. Open the workflow file and
read which check is required before scoring a 2.
```

A rule everybody follows and nobody enforces is a 1. It stays a 1 no matter how disciplined
the team is. It becomes a 2 the day a merge refuses.

The two agent files are ordinary Markdown with frontmatter. The frontmatter is the whole
configuration:

**File: `kit:.claude/agents/rubric-scorer.md` (excerpt: the frontmatter)**

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
```

**File: `kit:.claude/agents/evidence-verifier.md` (excerpt: the frontmatter)**

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
```

Three things to notice before you move on. `tools:` has no Edit or Write on either, so neither
agent can edit the thing it is grading through the file tools; Bash remains, so "never
writes" is still an instruction, not a guarantee (drop Bash, or deny writes in settings, if
you want it physical). The scorer runs on the cheap model and the verifier on the
expensive one, because something catches the scorer and nothing catches the verifier: tier the
model by the cost of being wrong, not by how hard the task looks. And the `description` is
what makes an agent fire at all, so it is written as the situation you would describe, not as
a summary of the mechanism.

## Step 2: read the five rules, then write a sixth

Read `evals/rubric.md`. The five rules are: dependency direction; failures are returned rather
than thrown; handlers are internal, one use case per file; a test tier per layer, all in the
required check; modules meet only through contracts.

Careful: the test names in `LayerRulesTests.cs` are Lab 4's numbering, not the rubric's.
Rubric rule 3 is checked by `Rule4_Handlers_are_internal`, and the fitness test called
`Rule5_...` is not rubric rule 5.
(AI path in Lab 4: your agent chose its own class and method names, so read them for the
same numbering trap.)

Rule 1 is the shape the other four copy, and the second paragraph is the part people leave out
when they write their own:

**File: `kit:evals/rubric.md` (excerpt: rule 1, the shape your sixth rule copies)**

```markdown
## Rule 1: dependency direction

The domain layer depends on nothing but the shared kernel and the base class library.
No persistence package, no web package, no messaging package anywhere below the
application layer.

**Evidence that counts.** The domain project file, showing which package and project
references it actually has. A fitness test asserting the allowed dependency set, and
the CI step that runs it. **Evidence that does not count.** A statement in a README, a
namespace that looks clean, or the absence of a `using` in the one file you opened.
```

Now write **rule 6**, about your own system rather than the helpdesk. Three minutes, in the
handout margin or in `evals/rubric.md` itself:

```
## Rule 6: <the rule, one sentence, present tense, about your system>

<Two or three lines: what the rule requires and where it applies.>

**Evidence that counts.** <Files, a test, a CI step: something somebody can open.>
**Evidence that does not count.** <The thing that looks like evidence and is not.>

0 = broken, or no evidence.   1 = followed, nothing enforces it.   2 = followed AND
enforced at the merge gate.
```

Spend your three minutes on the "does not count" line. The rule is easy and the positive
evidence is easy; the negative space is where the rule gets its teeth, and it is the line that
stops a judge, human or otherwise, from accepting a good impression as proof.

## Step 3: score the repository

### AI path

Dispatch the scorer. Paste this as written:

> Use the rubric-scorer agent against this repository. Score all five rules in
> evals/rubric.md against the rubric's own wording. For every rule return one row: the rule
> number, the score (0, 1 or 2, or null), a one-line justification, the path:line you read
> this run, and CONFIRMED or FLAG. Do not total the scores. Do not read or score anything
> under bin/ or obj/. Do not write, edit or commit any file. You are done when all five rows
> are returned; return the rows and nothing else.

That prompt is six fields: the goal, where the evidence lives, what is out of scope, the exact
return shape, when it is done, and how you will check it. The return shape is the one that
changes the work. An agent asked for `path:line` in its output starts collecting line numbers
from the first file it opens; an agent asked for "a summary of the architecture" does not, and
you cannot add the citations afterwards.

Rule 4 turns on one fact that no file in the repository holds: which check is *required* lives
in GitHub branch protection, and the scorer is told not to assume it. So what comes back
depends on your machine:

- **It cannot ask GitHub** (no `gh`, `gh` not signed in, or you declined its Bash call): rule 4
  comes back FLAG with a null score. That is the agent doing its job.
- **`gh` is signed in:** it may run the query itself and return rule 4 as a 2, CONFIRMED, with
  "gh api shows ..." in a justification. Correct, but that fact has no `path:line`, so nothing
  in step 4 can check it.
- **It cites your `CLAUDE.md`:** rule 4 comes back a 2, CONFIRMED, with `CLAUDE.md:<line>` as
  evidence, because that file says `build-and-test` is the required check. That one is wrong.
  A sentence in a document is not the gate, and the rubric says so ("A statement in a README
  ... does not count"); the honest answer was FLAG with a null score. Rule 1 often leans on
  the same line. Mark both rows and hand the `CLAUDE.md` citation to the verifier with the
  rest. Do not expect it to throw that citation out: in a rehearsal it only corrected the
  line number, settled the score itself with `gh api`, and let the 2 stand. Striking the
  citation is your call at step 5.

Either way, settle it yourself with the command you ran in Lab 5. It should print
`["build-and-test"]`:

```bash
gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'
```

`<owner>/helpdesk` is the repository Lab 5 created. If yours has another name,
`git remote get-url origin` shows it.

That command answers for `main`. If you are scoring a rescue branch (`lab6-end` or
`lab7-end`), it shares no commits with your `main`, so the protected check never ran on the
code being scored. Weigh that for every rule whose 2 rests on "the required check runs it"
(rules 1, 3 and 4 at least); the verifier in step 4 tends to raise it too.

**`lab8-demo` on the projector is the instructor's branch, not yours.** You score your own
repository on the branch you are on. The instructor's branch is `main` plus one planted
weakness, so at least one rule scores below 2. To see the same drop on your own code, plant it
on a scratch branch cut from your `main` (it already holds the three step 1 files):

```bash
git switch -c lab8-demo
```

In `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CloseTicket.cs`, change
`internal sealed class CloseTicketHandler` to `public sealed class CloseTicketHandler`, then:

```bash
git commit -am "Plant a weakness: CloseTicketHandler public"
```

Score again: rule 3 drops to 0 with a citation, and your handlers-are-internal fitness test
goes red if you run the tests (`Rule4_Handlers_are_internal` if you took Lab 4's manual path;
on the AI path your agent named it, for example `CommandAndQueryHandlers_MustBeInternal`). Your `path:line` anchors will not match the projector's; the shape will. Do
not push the branch, and `git switch main` when you are done, so the planted change stays off
`main`.

### Manual path

Score the five rules yourself against your own repository, one column at a time, using the
rubric's evidence rules rather than your memory of the code. Write the `path:line` next to
each score; if you cannot produce one, the score is not a score yet.

Two of them are quick on `lab7-end`:

- **Rule 1** is a 2. Evidence:
  `src/Modules/Tickets/Helpdesk.Tickets.Domain/Helpdesk.Tickets.Domain.csproj:4` (SharedKernel
  only), `tests/Helpdesk.ArchitectureTests/LayerRulesTests.cs:13`, and
  `.github/workflows/ci.yml:56`, which runs it inside the `build-and-test` job (`ci.yml:16`)
  that protects the branch. Both halves are needed; the test alone is a 1.
- **Rule 5** is a **0**, and this is the one nearly everybody gets wrong. Your repository has
  one module, so there is no cross-module interaction to point at. The rubric is explicit:
  modules that do not talk to each other yet is a codebase with no evidence, which is a 0, not
  a 2. A rule that has never been tested by a real need has not been passed.

Keep your five scores in front of you. When the instructor's scorer run comes up on the
projector, mark every row where you disagree with it.

## Step 4: try to break the scores

### AI path

Hand the verifier the claims and the paths, and nothing else:

> Use the evidence-verifier agent on this repository. Below are five claims and the path:line
> each one cites. Open each cited file yourself and try to disprove the claim; a claim
> survives only if you failed to break it. You have not been given the reasoning behind these
> scores and you must not ask for it or infer it. Return one line per claim: CONFIRMED,
> DRIFTED or FLAG, with a path:line, and for anything that is not CONFIRMED, the
> counter-evidence. Do not re-score the rubric and do not write any file. You are done when
> all five claims have a verdict.
>
> 1. <rule 1 score, its path:line>
> 2. <rule 2 score, its path:line>
> ... and so on for all five.

What you withheld is the point. The verifier gets claims and paths, never the justification
and never a pasted file body. Hand it the argument and it grades the argument, and you have
built a machine that emits CONFIRMED forever while feeling like rigor. If your first verifier
run confirms all five with no counter-evidence anywhere, assume that is what happened.

Your prompt goes to the main session, which writes its own brief for the verifier. Press
ctrl+o after the run (or open the transcript) and read the Agent call: if "do not re-score" or
"you have not been given the reasoning" is missing, that is why it drifted.

### Manual path

Swap with a neighbour. Give them one score and its `path:line`, and **not** your reasoning for
it. Their job is to open that file and try to disprove the claim: wrong line, right line but
the check is not in the required job, the rule holds in this file and breaks in the one next
to it. They return CONFIRMED, DRIFTED or FLAG with a `path:line` of their own. Then swap
roles. The gate works the same way on humans and fails the same way if you let the argument
travel with the claim.

## Step 5: adjudicate

You decide, not the agent. Read every FLAG and every DRIFTED item, look at the file yourself,
and either accept the correction or produce a better citation. Then total the five numbers,
out of ten, by hand or with a calculator, and write the date next to them.

Two calls you will probably make on rule 4:

- **A `CLAUDE.md` citation.** If the score rests on a sentence in `CLAUDE.md` (or a README),
  strike the citation even when the score survives. If the `gh api` command from step 3 prints
  `["build-and-test"]`, keep the 2 and cite that output instead; if you cannot run it, the row
  is a FLAG with a null score, not a 2.
- **`enforce_admins: false`.** The verifier may report it. It is the Lab 5 setting that let you
  push `ci.yml` straight to `main`: you, the admin, can merge without the check passing. Decide
  whether "a check enforces it on every merge" still holds for a 2, write down which way you
  went and why, and apply it the same way to every rule whose 2 rests on the required check.

Deciding yourself and totalling by hand are both deliberate. A verifier's CONFIRMED means "I found nothing", not "there is
nothing", so it authorises nothing on its own. And adding five numbers is exactly the
operation a model does fluently and wrong, which is why the rubric hands the arithmetic back
to you.

## Verification

You are done when you have all of this:

- A scored table, five rows, **a `path:line` on every row**. A row without one is an opinion,
  and the rubric forbids it.
- At least one row that is not a 2, examined rather than argued with. If every rule scored 2
  on your first run, something went wrong in the scoring, not in the codebase.
- **At least one FLAG or DRIFTED verdict that you personally opened the file for.** This is
  the actual completion criterion for the lab. Everything before it is setup.
- A sixth rule written in your own words, with its "does not count" line filled in.
- A total, computed by you, with today's date beside it.

## Troubleshooting

- **Everything scored 2.** Either the prompt let the agent skip the evidence requirement, or it
  scored the intention rather than the code. Re-dispatch with "every row must carry a
  `path:line` you read in this run; return FLAG rather than a score where you cannot produce
  one" and watch which rows move.
- **A score with no citation, or a citation that is a folder.** Send it back. `src/` is not a
  `path:line`, and the fix is one sentence: "re-state rule N with the exact file and line
  number you read."
- **The verifier confirms everything on its first run.** It was handed the scorer's reasoning
  or a pasted file body. Re-run with the claims and the paths only.
- **The verifier re-scores the rubric instead of checking claims.** Its prompt lost the "do not
  re-score" line. It is a checker, not a second judge; a second judge just gives you two
  opinions and no evidence.
- **Your tool cannot dispatch a subagent.** Run the scorer prompt as an ordinary prompt in a
  normal session. Everything works except the isolation, which matters for the verifier and
  much less for the scorer. For the verifier, use the manual path with a neighbour: a fresh
  pair of eyes that never saw your reasoning is exactly what the subagent was providing.
- **The agent offers to fix the low-scoring rule.** Say no, for now. Scoring and fixing in one
  pass means the thing that grades the change is the thing that made it, and the score stops
  being evidence. Score first, decide second, fix third, in that order and preferably in that
  many sessions.
- **You disagree with the rubric.** Good, and expected. The five rules are worth exactly as
  much as they describe your system. Rewrite them. What transfers is the shape: five rules and
  no more, a top mark that requires a merge gate, evidence rules written down per rule, a
  scorer, an adversary that never sees the scorer's reasoning, and a human at the end.
