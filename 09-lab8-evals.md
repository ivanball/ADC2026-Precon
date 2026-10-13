# Lab 8 (3:55-4:20): Evals for architecture: the agent as judge

**Phase:** Govern. **Type:** framing (4 min) + rubric read and writing mini-lab (5 min) +
instructor scorer run (6 min) + instructor verifier run (5 min) + adjudicate and debrief
(3 min) + hand-off (2 min). **Goal:** the room leaves holding three ideas that fit together.
A rubric is an executable opinion: five rules, a scale where the top mark means a merge gate,
and a written rule for what counts as evidence. A judge that must cite `path:line` cannot
bluff, because every score becomes a pointer somebody can open. And a second agent whose only
job is to disprove the first turns a score into evidence rather than a mood.
Snapshot branch: `lab7-end` (attendees); the instructor demo runs on `lab8-demo`.

**Room note:** this is the shortest block of the day and the only one where most of the room
watches rather than types. Say that at 3:55, in one sentence, before anybody decides they are
about to be left out: the part everybody does with their hands is writing a rule, the two
agent runs happen once on the projector, and an agent of your own is a nice-to-have here.
The room is also tired: Lab 7 ended on the injection demo four seconds ago. Open standing up,
and know now that the verifier run at 4:10 is the one beat that is never cut.

**Teaching beats:** a rubric is the opinion you already have, written down where it can be
checked; a judge that must cite cannot bluff; one pass grades the argument it just wrote, so
the second pass must never see that argument; and tier the models by the cost of being wrong,
because a wrong score becomes the record and everybody inherits it.

**You need:**

- The starter kit repo open on the projector at `evals/rubric.md`, with the two agent
  definitions in `.claude/agents/` one keystroke away.
- The starter kit's public URL on screen for handout step 1:
  `https://github.com/ivanball/agentic-dotnet-starter-kit` (public, MIT, no account needed to
  clone). The handout prints it too; the screen is for the people who type rather than paste.
- The reference helpdesk on `main`, plus **one deliberate weakness planted on a scratch
  branch** so at least one rule scores below 2. Cut `lab8-demo` from `main` before the room
  arrives and make `CloseTicketHandler` public:
  `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CloseTicket.cs:9`, change
  `internal sealed class` to `public sealed class`. It still compiles, the fitness test
  `Rule4_Handlers_are_internal` goes red, and rubric rule 3 is now a 0 with a citation. Alternative if you would
  rather move a different rule: delete the "API integration tests" step from
  `.github/workflows/ci.yml` and watch rule 4 drop from 2 to 1.

  `lab8-demo` must also hold the three step 1 files, because the prompt reads
  `evals/rubric.md` and the agents from the repository. The published `workshop/lab8-demo`
  has the planted change but not `evals/` or `.claude/agents/` (and it was cut from an older
  `main`), so either run step 1 on it after checking it out, or cut it from a `main` that
  already has them. In a practice repo at the end of Lab 8 step 1, that is:

  ```sh
  git switch -c lab8-demo
  ```

  Run the demo from a repository whose `main` is protected with `build-and-test` required (your
  Lab 5 practice repo after its Step 2). On a fresh clone of the workshop repository, `origin`
  is the reference repo, whose `main` is unprotected until the prep-checklist item is done: the
  agents' `gh api` call returns 404 `Branch not protected`, rules 1 to 4 come back FLAG with
  null scores, and the verifier calls the CLAUDE.md required-check line false (2026-10-12 Mac
  run). Check before the room arrives:
  `gh api repos/<owner>/<repo>/branches/main/protection --jq '.required_status_checks.contexts'`
  must print `["build-and-test"]`. Attendees who caught up from a rescue clone will see exactly
  those flags; handout step 3 tells them that is the rubric working.

  Edit `CloseTicket.cs` line 9: `internal sealed class` becomes `public sealed class`. Then:

  ```sh
  git commit -am "Plant a weakness: CloseTicketHandler public"
  ```

  Anchors from your own cut differ from the expected output below (which came from
  `workshop/lab8-demo`); the shape does not. Never push it, and `git switch main` afterwards so
  the planted change stays off `main`.
- Both dispatch prompts in a scratch file, ready to paste. Twenty-five minutes does not
  survive typing a prompt in front of the room. The verifier prompt's five numbered lines stay
  as placeholders there: fill them from the live scorer run (score plus its `path:line`s, copied
  from the table), never from the example in step 4.
- One rehearsal of the whole run on `lab8-demo`, in the room, before doors, with its output
  saved to a slide. The scorer takes about ninety seconds and the verifier about two minutes;
  if yours ran longer, cut the volunteers at 4:02 and decide that now, not at 4:11.

## Rescue: starting from the snapshot (the handout prints this under its snapshot line)

**Starting from the snapshot instead of your own work?** Your Lab 5 repository has no snapshot
branches, so add the workshop repository as a second remote (skip the `remote add` line if
you already have it), commit or stash your own work, and switch to the snapshot:

```sh
git remote add workshop https://github.com/ivanball/adc2026-helpdesk.git
git fetch workshop
git switch -c lab7-end --track workshop/lab7-end
```

No repository of your own? Clone instead:
`git clone --branch lab7-end https://github.com/ivanball/adc2026-helpdesk.git helpdesk-lab8`, then `cd helpdesk-lab8`.

## Minute-by-minute

| Time | Beat | Min |
|------|------|-----|
| 3:55 | Framing: what an eval is here, versus a unit test, versus a fitness test | 4 |
| 3:59 | Step 2, the rubric: read the five rules, then everybody writes a sixth | 5 |
| 4:04 | Step 3, instructor run 1: dispatch the scorer, read the returned table, find the planted weakness | 6 |
| 4:10 | Step 4, instructor run 2: dispatch the verifier on the scorer's claims, read CONFIRMED and FLAG | 5 |
| 4:15 | Step 5, adjudicate and debrief: the human decides, and what production adds | 3 |
| 4:18 | Hand off to S9: Field report | 2 |

## Files this session touches

Nothing in the attendee repository changes during this block. The three files come from the
**starter kit**, and the instruction is to copy them into your own repository, not to type
them. That is why every fence below is labelled `kit:`: the source is the kit, the
destination is the attendee's repo.

| Source (starter kit) | Destination | What it is |
|------|--------|---------|
| `evals/rubric.md` | `evals/rubric.md` in your repo | 109 lines. Five rules, the 0/1/2 scale, what counts as evidence per rule, and the three-step scoring procedure. Excerpted below and in handout lab8, steps 1 (the scale) and 2 (rule 1) |
| `.claude/agents/rubric-scorer.md` | `.claude/agents/rubric-scorer.md` | 49 lines. The judge. `model: sonnet`, no Edit or Write tool, cites `path:line` for every claim, never totals, never writes. Frontmatter excerpted below and in handout lab8, step 1 |
| `.claude/agents/evidence-verifier.md` | `.claude/agents/evidence-verifier.md` | 71 lines. The adversary. `model: opus`, no Edit or Write tool, returns CONFIRMED / DRIFTED / FLAG with counter-evidence, never writes. Frontmatter excerpted below and in handout lab8, step 1 |

### Step 1: copy the three files into your repo

What attendees run first (handout lab8, "Step 1: copy the three files into your repo"). Two
moves, both from the root of their own repository in Git Bash (Terminal on a Mac). First they clone the kit as a
sibling of their repository, with the URL on the screen:

```bash
git clone https://github.com/ivanball/agentic-dotnet-starter-kit.git ../agentic-dotnet-starter-kit
```

Then they copy the three files and list them:

```bash
mkdir -p evals .claude/agents
cp ../agentic-dotnet-starter-kit/evals/rubric.md evals/
cp ../agentic-dotnet-starter-kit/.claude/agents/rubric-scorer.md .claude/agents/
cp ../agentic-dotnet-starter-kit/.claude/agents/evidence-verifier.md .claude/agents/
ls evals .claude/agents
```

**In Command Prompt (cmd.exe) instead?** `mkdir -p` answers `The syntax of the command is
incorrect.` and nothing is created. Use backslashes and `copy` there, still from the root of
the repository (the prompt ends in the repository's folder name, not its parent). The handout
prints the same block right under its copy block:

```bat
mkdir evals .claude\agents
copy ..\agentic-dotnet-starter-kit\evals\rubric.md evals\
copy ..\agentic-dotnet-starter-kit\.claude\agents\rubric-scorer.md .claude\agents\
copy ..\agentic-dotnet-starter-kit\.claude\agents\evidence-verifier.md .claude\agents\
dir evals .claude\agents
```

The failures you will see from the floor, in order of frequency:

- `The syntax of the command is incorrect.` The attendee is in Command Prompt, not Git Bash,
  and usually one folder too high as well (the prompt ends in the parent, not the repository).
  Nothing was created. Point them at the cmd.exe block above (in the handout, right under the
  copy block), after a `cd` into the repository. Seen in the 2026-10-07 and 2026-10-11
  rehearsals.
- `cp: ... No such file or directory`: the kit was cloned somewhere other than next to the
  repository (inside it, or in the home folder). `ls ..` from the repository root must show
  `agentic-dotnet-starter-kit` beside it.

Anyone without git takes the handout's browser path: view each file raw in the kit and save it
at the same path.

Then they commit (handout lab8, under the copy step's file table, word for word):

Commit the three files before any agent runs, so `git status` afterwards shows anything the
judge or the adversary wrote:

```bash
git add -A && git commit -m "Eval rubric and grading agents"
```

After the copy, attendees must start a FRESH `claude` session. Their repo had no
`.claude/agents/` folder before the copy, and Claude Code only watches agent folders that
existed when the session started, so the session that did the copy answers "Agent type
'rubric-scorer' not found" (seen in the 2026-09-28 rehearsal). The handout says so right under the copy step; repeat it from the front.

Right after the fresh-session note, handout step 1 shows three kit excerpts, in this order:
the scale, then the two frontmatters. The room sees the same three on the projector (the scale
at 3:59, the scorer frontmatter at 4:04, the verifier frontmatter at 4:10); these are the
handout's copies, word for word:

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

The handout's "Three things to notice" paragraph under these (no Edit or Write in `tools:`,
the model tiering, the `description` as the trigger) is what the 4:04 and 4:10 beats say out
loud.

The attendee repository on `lab7-end` has one module, 16 tests and three CI steps, so their
honest score is not the instructor's: rubric rule 5 wants a real cross-module interaction
through a contracts project, and a one-module repository has no evidence at all. That is a 0,
and the rubric says so out loud.

## 3:55 Framing (4 min)

Three kinds of check, and the room has now built two of them. Put them on one slide and say
the difference in three sentences.

- A **unit test** pins what the code does. One input, one expectation, green or red.
- A **fitness test** pins how the code is shaped. Still yes or no, still mechanical, and the
  compiler and the dependency graph can see the whole answer. That is Lab 4, and it is the
  strongest check available, so anything that can be a fitness test should be one.
- An **eval** grades the rules that are judgment-shaped: the ones where the answer is "mostly,
  and here is where it frays". "Failures are returned rather than thrown" is not a graph
  property, and neither is "modules meet only through contracts" in a codebase where one
  module cheats through an interface that happens to be public. You cannot compile that
  question, so you grade it, with evidence, on a scale.

Then the two properties that keep an eval honest, which are also the two that are easiest to
lose:

- **The judge must cite.** Every score is anchored to a `path:line` read in this run, so a
  score is a pointer rather than an opinion, and anybody can open the pointer and disagree.
  Without that rule the model produces a paragraph of fluent architectural appreciation and a
  number, and the number is unfalsifiable. Say it plainly: a judge that must cite cannot
  bluff.
- **A second agent tries to break every score.** One pass grades the argument it just wrote.
  The verifier is not a reviewer, it is an adversary, and it is worth running only because it
  never sees the scorer's reasoning, only the claims and the paths.

Close the framing with the tiering, because it is a decision they make on Monday and the
reasoning transfers past this rubric. The scorer runs on the cheap model: it reads a lot,
returns little, and its mistakes get caught by the pass after it. The verifier runs on the
expensive one, because there is no pass after the verifier. **Tier the model by the cost of
being wrong, not by how hard the task looks.** A wrong score goes in the record, and the next
six months of decisions inherit it.

## 3:59 The rubric, and everybody writes a sixth rule (5 min)

### Step 2: read the five rules, then write a sixth

Put the rubric on screen. Read the scale out loud, all three rows, then the paragraph under
it, which is the whole design in three lines (the scale excerpt under "Files this session
touches" above; attendees met it in handout step 1).

Land the 1-versus-2 line hard, it is the sentence that makes the rubric worth running: a rule
everybody follows and nobody enforces is a 1, forever, no matter how disciplined the team is
or how proud they are of it. It stops being a 1 the day a merge refuses.

Then rule 1, as the shape all five share, and the part nobody writes on their own the first
time is the second half:

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

Name the other four in one breath each, then stop reading and start the mini-lab: failures
are returned rather than thrown; handlers are internal, one use case per file; a test tier per
layer, all three in the required check; modules meet only through contracts.

Say the numbering trap out loud (the handout carries it as a "Careful" note): the test names
in `LayerRulesTests.cs` use Lab 4's numbering, not the rubric's. Rubric rule 3 is checked by
`Rule4_Handlers_are_internal`, and the fitness test called `Rule5_...` is not rubric rule 5.
AI-path attendees' agents chose their own class and method names in Lab 4, so they read theirs
for the same trap.

**Mini-lab, everybody, agent or no agent (3 min).** Write a sixth rule, about your own system
rather than the helpdesk, in the rubric's shape. Template (handout step 2; the slide carries only the instruction):

```
## Rule 6: <the rule, one sentence, present tense, about your system>

<Two or three lines: what the rule requires and where it applies.>

**Evidence that counts.** <Files, a test, a CI step: something somebody can open.>
**Evidence that does not count.** <The thing that looks like evidence and is not.>

0 = broken, or no evidence.   1 = followed, nothing enforces it.   2 = followed AND
enforced at the merge gate.
```

Float for the three minutes and push on one thing only: the "does not count" line. Almost
everybody writes a good rule and a plausible evidence line and leaves the negative space
blank, and that is where the rule gets its teeth. "We use the repository pattern" is not
evidence of anything; a test that fails when a `DbContext` appears in a handler is. **Two or
three volunteers read theirs out at 4:02**, no commentary from you beyond naming what counts
as evidence in each. One volunteer if you are behind.

## 4:04 Instructor run 1: the scorer (6 min)

Show the agent definition first, for thirty seconds, because the file is the lesson and the
run is the demonstration. The frontmatter first (the handout step 1 excerpt under "Files this
session touches" above), then the first block, which the handout does not reprint:

*Instructor only (not in the handout).*

**File: `kit:.claude/agents/rubric-scorer.md` (excerpt: the evidence rule)**

```markdown
## Non-negotiable: evidence, never assumption

- Every score must be backed by code, config or CI you read THIS run, cited as
  `path:line`. A score with no `path:line` is an opinion, and the rubric forbids it.
- **"Enforced by a merge gate" is the dividing line between 1 and 2.** A rule that is
  followed everywhere but checked by nobody is a 1. Open `.github/workflows/` and read
  the required check to tell the difference rather than assuming.
- When the evidence is ambiguous, contradictory or absent, do not guess a number.
  Return verdict FLAG with what you found and what is missing. A flag is a correct
  outcome; an invented score is not.
```

Point at three things and move on: `tools:` has no Edit or Write, so the judge cannot edit
the thing it is grading through the file tools (Bash remains, so "never writes" is still an
instruction, not a guarantee; drop Bash or deny writes in settings to make it physical);
`model: sonnet` is the cheap tier; and "a flag is a
correct outcome" is the line that stops a model from inventing a number to look useful.

### Step 3: score the repository

#### Step 3, AI path: score the repository (instructor demo; attendees with an agent run their own)

Now dispatch it against `lab8-demo`, the branch from the prep list (`main` plus the public
`CloseTicketHandler`, plus the three step 1 files). Attendees score their own branch; the
handout's step 3 shows them how to cut their own `lab8-demo` if they want to see the same drop.

Switch to it yourself before you dispatch (`git switch lab8-demo`, then
`git branch --show-current` prints `lab8-demo`). The prompt names the branch so the scorer
can confirm it, and tells it not to switch: an agent that runs `git checkout` itself rewrites
the working tree, which "do not write, edit or commit" does not cover. Prompt, paste it, do
not improvise it:

Instructor demo prompt (on lab8-demo, projector only):

> Use the rubric-scorer agent against this repository, which is on branch lab8-demo; do not
> switch branches. Score all five rules in evals/rubric.md against the rubric's own wording.
> For every rule return one row: the rule number, the score (0, 1 or 2, or null), a
> one-line justification, the path:line you read this run, and CONFIRMED or FLAG. Do not
> total the scores. Do not read or score anything under bin/ or obj/. Do not write, edit
> or commit any file. You are done when all five rows are returned; return the rows and
> nothing else.

Attendee prompt (their own repo). What attendees with an agent do (handout lab8, "Step 3: score
the repository", "### AI path", word for word): "Dispatch the scorer. Paste this as written:"

> Use the rubric-scorer agent against this repository. Score all five rules in
> evals/rubric.md against the rubric's own wording. For every rule return one row: the rule
> number, the score (0, 1 or 2, or null), a one-line justification, the path:line you read
> this run, and CONFIRMED or FLAG. Do not total the scores. Do not read or score anything
> under bin/ or obj/. Do not write, edit or commit any file. You are done when all five rows
> are returned; return the rows and nothing else.

Then the same handout section tells attendees that rule 4 depends on their machine: FLAG with
a null score when the scorer cannot ask GitHub (no `gh`, not signed in, or the Bash call
declined), a CONFIRMED 2 with "gh api shows ..." in a justification when `gh` is signed in,
and a third, wrong outcome: a CONFIRMED 2 citing their own `CLAUDE.md`, which they are told to
mark for step 4. Either way they settle it with the Lab 5 command, which should print `["build-and-test"]`:
`gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'`.
The handout adds a caveat for rescue branches: that command answers for `main`, and a rescue
branch (`lab6-end` or `lab7-end`) shares no commits with the attendee's `main`, so the
protected check never ran on the code being scored. They weigh that for every rule whose 2
rests on "the required check runs it" (rules 1, 3 and 4 at least); the verifier in step 4 tends
to raise it too.
(The handout's paragraph on the six fields matches the "While it runs" beat below.)

What the agent should produce: five rows, a `path:line` on every row, no total. On `lab8-demo`:
rule 3 `0` citing `CloseTicket.cs:9` CONFIRMED, rule 4 `null` FLAG, rule 2 `1` or `2`
(rehearsed 2026-10-06: 33 s). On an attendee's `lab7-end`: rule 1 `2`, rule 5 `0`, rules 2-3 `2`,
rule 4 FLAG (31 s). The 2026-10-07 rehearsal, on a laptop with `gh` signed in, returned rule 4
as `2` CONFIRMED instead (30 s): the scorer ran the branch-protection query itself and said so
in rule 1's justification. Spot-check one anchor: the rehearsal scorer cited `Result.cs:12-13`, which
are constructor `throw` guards, as evidence that failures are not thrown.

While it runs, say what that prompt is: the six fields that make a brief executable. Goal,
where the evidence lives, what is out of scope, the exact return shape, when it is done, how
you will check. **The return shape is the field that changes the work**, not the tone: an
agent asked for `path:line` collects line numbers from the first file it opens, and one asked
for "a summary of the architecture" does not.

*Instructor only (not in the handout).*

Expected return on `lab8-demo`, roughly (yours will differ in the line numbers, not in the
shape). The `LayerRulesTests.cs` anchors below are `lab8-demo` lines; on an attendee's
`lab7-end` the rule 1 test is at `:13` and `Rule4_Handlers_are_internal` at `:51`:

```
| Rule | Score | Evidence (read this run) | Verdict |
| 1 dependency direction | 2 | Helpdesk.Tickets.Domain.csproj:4 (SharedKernel only); LayerRulesTests.cs:14; ci.yml:56 runs it | CONFIRMED |
| 2 failures returned, not thrown | 2 | Result.cs:23 Failure; Ticket.cs:39 returns on empty title; TicketEndpoints.cs:22 maps to 400 | CONFIRMED |
| 3 handlers internal, one use case per file | 0 | CloseTicket.cs:9 declares CloseTicketHandler public; LayerRulesTests.cs:52 asserts the opposite | CONFIRMED |
| 4 a test tier per layer | 2 | ci.yml:52 unit, ci.yml:55 fitness, ci.yml:59 API, all in the required job | CONFIRMED |
| 5 modules meet only through contracts | 2 | LayerRulesTests.cs:82; Notifications.Application.csproj:5 references only Tickets.Contracts | CONFIRMED |
Total: not computed (the rubric assigns that to the human).
```

Rule 4 comes back one of three ways. The first two are the agent doing its job. "Required" lives in
GitHub branch protection, not in `ci.yml`, and the scorer is told not to assume it. When it
cannot query GitHub it returns FLAG with a null score (the 2026-10-06 rehearsal). When `gh` is
signed in it has the Bash tool to run the query and may return a CONFIRMED 2 (the 2026-10-07
rehearsal). If you get the second, name it in the room: the deciding fact is real but has no
`path:line`, so the verifier at 4:10 cannot test it, which is a small preview of why evidence
has to be something a second reader can open. Either way, adjudicate it with the Lab 5 output
of `gh api repos/<owner>/helpdesk/branches/main/protection --jq '.required_status_checks.contexts'`
(`["build-and-test"]`).

There is a third way, and it is a scorer error, not the agent doing its job: rule 4 as a
CONFIRMED 2 citing `CLAUDE.md`, because the repository's CLAUDE.md says `build-and-test` is
"the required check on main". The 2026-10-11 rehearsal (a practice repo built through the AI
path; the scorer did not run `gh`) returned exactly that, with the justification admitting "the repo itself
doesn't show that build-and-test is the required check; only CLAUDE.md:9 says so", and rule 1
leaning on the same line. The rubric excludes it in words ("A statement in a README ... does
not count"), and the scorer's own definition says to read the required check "rather than
assuming"; the right return was FLAG with a null score. Attendees whose CLAUDE.md gained that
line after Lab 5 will see the same. If it happens on the projector, use it: a document that
claims a gate exists is not the gate, and this is the score the verifier at 4:10 should go
after. If the verifier lets it stand, adjudicate it yourself at step 5 with the `gh api`
output; a scorer and a verifier agreeing on a documentation claim is still a documentation
claim.

What the 2026-10-11 verifier did with it, given the scorer's own claims: rule 4 DRIFTED, but
only on the line number (the sentence is at `CLAUDE.md:10`; `:9` is the Run line). It did not
say a CLAUDE.md sentence is not evidence. It ran `gh api` on branch protection itself, found
`build-and-test` required, and let the 2 hold on that. So the score was right and the citation
still is not evidence: at step 5, keep the 2, cite the `gh api` output, and strike the
`CLAUDE.md` line. The same run also reported `enforce_admins: false` on `main`, an admin can
merge without the check passing. That is Lab 5's deliberate setting (handout lab5 says why),
and it is a fair step 5 question: does "a check enforces it on every merge" hold when the
admin can skip it?

Expect rule 2 to wobble between 1 and 2 across runs over the same
evidence; that variance is the argument for the verifier.

Read the table out loud once, then stop on rule 3. This is the beat the block was built for:
the fitness test for that rule exists, ships and runs in the required check, and the rule
still scores 0, because the rubric grades the codebase rather than the intention. Ask the room
what a judge with no citation rule would have said. It would have said 2, with confidence,
because five minutes in this repository leaves an overwhelming impression of discipline, and
an impression is exactly what the citation rule refuses.

Then say the other half before anybody says it for you: the scorer got this one right, and it
does not always. That is the entire reason for the next five minutes.

#### Step 3, manual path: score it by hand (attendees without an agent)

Every attendee does the mini-lab at 3:59; that part needs nothing but a pen. For the two runs
they score by hand and compare, which is not a consolation prize: the hand path is how you
find out whether your evidence column is written well enough for somebody else to apply it.

- Open the rubric's evidence column for rule 1 and score their own repository on `lab7-end`
  against it. Two minutes, one rule, out loud if they want. Rule 1 is a 2 there, and the
  citation is `Helpdesk.Tickets.Domain.csproj:4`, `LayerRulesTests.cs:13` and `ci.yml:56`, the
  CI step that runs it.
- Call rule 5 deliberately: one module means no cross-module interaction at all, so rule 5 is
  a **0, not a 2**. A rule that has never been tested by a real need has no evidence, and no
  evidence is not a pass. Most common scoring mistake in the room, worth thirty seconds.
- During the instructor's scorer run they check the returned table against their own hand
  scores as it appears, and mark any row where they disagree.

What manual-path attendees do (handout lab8, "Step 3: score the repository", "### Manual path",
word for word): "Score the five rules yourself against your own repository, one column at a
time, using the rubric's evidence rules rather than your memory of the code. Write the
`path:line` next to each score; if you cannot produce one, the score is not a score yet." The
handout's rule 1 evidence adds `ci.yml:16` (the `build-and-test` job that protects the branch:
"Both halves are needed; the test alone is a 1"), and it ends: "Keep your five scores in front
of you. When the instructor's scorer run comes up on the projector, mark every row where you
disagree with it." (Rehearsed by hand on `lab7-end`: 2 / 2 / 2 / 2 / 0, about 6 minutes with an
editor and grep.)

## 4:10 Instructor run 2: the verifier (5 min)

Same move: the file first, briefly. The frontmatter (the handout step 1 excerpt under "Files
this session touches" above), then the independence rule, which the handout does not reprint:

*Instructor only (not in the handout).*

**File: `kit:.claude/agents/evidence-verifier.md` (excerpt: the independence rule)**

```markdown
## Independence, the property that makes you useful

- **You judge the claim, never the argument for it.** If any rationale, justification
  or self-assessment reached you anyway, ignore it completely and say so in your
  return. Grading someone's reasoning instead of the world turns this into a rubber
  stamp that keeps emitting CONFIRMED.
- **Your CONFIRMED does not authorize anything.** It means "I found nothing", not
  "there is nothing". Something downstream owns the decision.
```

`model: opus` here against `model: sonnet` there, and that is the tiering slide made real:
nothing catches the verifier, so the verifier is the expensive one.

### Step 4: try to break the scores

#### Step 4, AI path: try to break the scores (instructor demo; attendees with an agent run their own)

Dispatch it on the scorer's claims: the five rows the step 3 run just returned on the
projector, not a list prepared in advance. Note what you are handing over and what you are
deliberately withholding. Still on `lab8-demo` from step 3; check with
`git branch --show-current` if anything ran in between:

Instructor demo prompt (on lab8-demo, projector only). The prompt text is fixed; the five
numbered lines are filled in live, one per scorer row, with the score and every `path:line`
that row cited exactly as the scorer wrote it, and nothing from its justification column:

> Use the evidence-verifier agent on this repository, which is on branch lab8-demo; do not
> switch branches. Below are five claims and the path:line each one cites. Open each cited file
> yourself and try to disprove the claim; a claim survives only if you failed to break it.
> You have not been given the reasoning behind these scores and you must not ask for it or
> infer it. Return one line per claim: CONFIRMED, DRIFTED or FLAG, with a path:line, and for
> anything that is not CONFIRMED, the counter-evidence. Do not re-score the rubric, do not
> comment on rules you were not given, and do not write any file. You are done when all five
> claims have a verdict.
>
> 1. Rule 1 scores [score], evidence [every path:line the scorer cited for rule 1].
> 2. Rule 2 scores [score], evidence [...].
> 3. Rule 3 scores [score], evidence [...].
> 4. Rule 4 scores [score], evidence [...].
> 5. Rule 5 scores [score], evidence [...].

Example of filled-in lines, from the 2026-10-06 rehearsal on the workshop's `lab8-demo` (its
verdicts are in the instructor-only block below). Do not paste these: they match that one run's
line numbers and that branch's files. Pasted into any other repository (the 2026-10-11
rehearsal pasted them into a practice repo with no `LayerRulesTests.cs` and no Notifications
module), the verifier correctly returns DRIFTED and FLAG on claims your scorer never made, and
whatever your scorer actually got wrong goes untested:

```text
1. Rule 1 scores 2, evidence Helpdesk.Tickets.Domain.csproj:4 and LayerRulesTests.cs:14, enforced by ci.yml:56.
2. Rule 2 scores 2, evidence Result.cs:23, Ticket.cs:39, TicketEndpoints.cs:22.
3. Rule 3 scores 0, evidence CloseTicket.cs:9.
4. Rule 4 scores 2, evidence ci.yml:52, ci.yml:55, ci.yml:59.
5. Rule 5 scores 2, evidence LayerRulesTests.cs:82 and Helpdesk.Notifications.Application.csproj:5.
```

If the scorer cited `CLAUDE.md` for rule 4 (or rule 1), that citation goes into the claim like
any other. It is the one the verifier most needs to see.

Attendee prompt (their own repo). What attendees with an agent do (handout lab8, "Step 4: try
to break the scores", "### AI path", word for word): "Hand the verifier the claims and the
paths, and nothing else:"

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

Then, from the same handout section: "What you withheld is the point. The verifier gets claims
and paths, never the justification and never a pasted file body. Hand it the argument and it
grades the argument, and you have built a machine that emits CONFIRMED forever while feeling
like rigor. If your first verifier run confirms all five with no counter-evidence anywhere,
assume that is what happened." And: "Your prompt goes to the main session, which writes its own
brief for the verifier. Press ctrl+o after the run (or open the transcript) and read the Agent
call: if "do not re-score" or "you have not been given the reasoning" is missing, that is why it
drifted."

What the agent should produce: one verdict line per claim, each with its own `path:line`, and
counter-evidence on every non-CONFIRMED line. On `lab8-demo` the rehearsal returned 1 FLAG,
2 FLAG, 3 CONFIRMED, 4 CONFIRMED (the FLAG stands), 5 DRIFTED at `LayerRulesTests.cs:86`
(64 s); on `lab7-end`, 1 CONFIRMED, 2-4 FLAG, 5 CONFIRMED (74 s). In both runs the main session
rewrote the brief and dropped "You have not been given the reasoning behind these scores" (one
run also dropped "Do not re-score the rubric", and its verifier re-scored claim 2), which is
exactly the ctrl+o check.

Two sentences on what that prompt withholds, because it is the whole gate: the verifier gets
the claims and the paths, never the justifications and never a pasted file body. Hand it the
argument and it grades the argument, which is how this turns into a machine that emits
CONFIRMED forever and feels like rigor.

Show one of each. A CONFIRMED with its own re-read evidence, so the room sees the verifier did
not take the scorer's word for the line number, and one that did not survive:

*Instructor only (not in the handout).*

```
1. CONFIRMED  Helpdesk.Tickets.Domain.csproj:4 - one ProjectReference, SharedKernel. Re-read; ci.yml:56 runs the fitness project in the required job.
3. CONFIRMED  CloseTicket.cs:9 - "public sealed class CloseTicketHandler". Score 0 stands.
4. DRIFTED    ci.yml:52 and :55 are step NAMES. The commands are :53, :56 and :59. The tiers run; the score holds; the anchors were wrong.
5. DRIFTED    LayerRulesTests.cs:86 loads only the assembly holding NotificationsModule (Notifications.Infrastructure). Notifications.Application.csproj:5 references only Tickets.Contracts today, but nothing would stop it referencing Tickets.Domain tomorrow. The gate covers one of the two Notifications assemblies, so "enforced" does not hold for the module.
```

Lines 4 and 5 are true of `lab8-demo`: there is no `continue-on-error` or `if:` anywhere in
its workflows, so do not improvise one, and the rule 5 gap at `LayerRulesTests.cs:86` is the
one the 2026-10-06 rehearsal verifier found on its own.

Then say the sentence, slowly, and let it sit: **a PASS means "I found nothing". It does not
mean "there is nothing", and it authorises nothing.** That applies to every green check they
have built today, and it is the most portable idea in the block.

#### Step 4, manual path: swap with a neighbour (attendees without an agent)

- During the verifier run, pair up: hand a neighbour one of your scores plus its `path:line`,
  never your reasoning, and try to break theirs. Same gate, run on humans, and it fails in
  exactly the same way if you let the argument travel with the claim.

What manual-path attendees do (handout lab8, "Step 4: try to break the scores", "### Manual
path", word for word): "Swap with a neighbour. Give them one score and its `path:line`, and
**not** your reasoning for it. Their job is to open that file and try to disprove the claim:
wrong line, right line but the check is not in the required job, the rule holds in this file
and breaks in the one next to it. They return CONFIRMED, DRIFTED or FLAG with a `path:line` of
their own. Then swap roles." (Rehearsed: given only "Rule 2 = 2, Ticket.cs:14-15,54", the
neighbour returned DRIFTED, because `Ticket.cs:14-15` is an Error declaration, not a return.)

## 4:15 Adjudicate, and what production adds (3 min)

### Step 5: adjudicate

The human decides. Walk the two DRIFTED items out loud, forty seconds each, so the room sees
what adjudication is: rule 4 keeps its 2 and the finding is two citations to correct, not a
score to argue about; rule 5's DRIFTED gets a look at `LayerRulesTests.cs:86`: the rule is
followed, the gate covers half the module, so it is a 1 until the test also loads
Notifications.Application. Then total the five numbers yourself, on
the slide, and say why that step is not delegated: adding five numbers is the operation a
model does fluently and wrong, and a confident wrong total arrives well formatted.

Done check at a table (the handout's "Verification" section, five items):

- A scored table, five rows, a `path:line` on every row.
- At least one row that is not a 2, examined rather than argued with.
- **At least one FLAG or DRIFTED verdict the attendee personally opened the file for.** This
  is the actual completion criterion for the lab.
- A sixth rule in their own words, with its "does not count" line filled in.
- A total, computed by them, with today's date beside it.

What production adds to this, four bullets, no live demo, this is the bridge to S9:

- The score is a **committed artifact**, not a chat message. It has a date, it lives next to
  the code, and it goes in the pull request that moved it.
- **The indices come from a script, never from the model.** Same reason as the total above,
  multiplied by thirty-odd categories.
- It is **re-scored on a cadence you can actually keep**, one that lines up with releases. A
  score that moved down without anybody deciding to move it is the finding.
- Two applications built on the same framework can be scored against each other, and the
  diff is the drift. That is one line here and a segment in the next block.

## 4:18 Hand-off to S9 (2 min)

Close the loop across the afternoon: Lab 4 made a rule executable, Lab 5 put it in the
required check, Lab 7 gave the module a second kind of client, and this block graded the
result with something that had to show its work. One question, one answer: "which of your five
scores would you least like your team to see?" That is the backlog. Then hand off, and go
straight into S9: "You have now watched a judge cite `path:line` and an
adversary try to break every citation it made, on a five-rule rubric, in one repository.
The next thirty-five minutes is what that looks like after a year, on a real codebase, run by
somebody who has to live with the answers."

## If things go wrong

- **The scorer returns 2 for everything.** Two causes, different fixes. Either the weakness was
  never planted, so check you are on `lab8-demo` and that `CloseTicket.cs:9` really says
  `public` (verify that at doors, not at 4:06); or the prompt let it skip evidence, so
  re-dispatch with "every row must carry a path:line you read in this run; return FLAG rather
  than a score where you cannot produce one" and let the room watch the scores move. The
  second failure is better material than the demo you planned.
- **The verifier agrees with everything.** Almost always one cause: it received the scorer's
  reasoning, or a pasted file body, instead of the bare claims. Re-dispatch with the claims and
  the paths only, plus the independence line verbatim: "you judge the claim, never the argument
  for it; if any rationale reached you, ignore it and say so." Then name what just happened, on
  purpose: a rubber-stamp verifier is the failure this design exists to prevent.
- **The verifier re-scores a claim** ("the score of 1 looks too low"). Your prompt went to the
  main session, which wrote its own brief for the verifier, and in the 2026-10-06 rehearsal
  that relay dropped "you have not been given the reasoning" and "do not re-score the rubric".
  Press ctrl+o (or open the transcript), read the Agent call's prompt, and if either line is
  missing, say so to the room: that is why it drifted.
- **The tool cannot spawn subagents** (no agent support, or the dispatch is refused). Run the
  scorer prompt inline as an ordinary prompt: everything except the isolation still works and
  the table is the same. Then skip the verifier run and explain it from the file on screen,
  naming what the inline version loses: a fresh context that never saw the first answer.
- **A run hangs or comes back empty.** Do not retry into silence in front of the room. You
  rehearsed this at doors, so paste the rehearsed output on the slide, say it is the rehearsal
  output, and keep the beat. Twenty-five minutes has no room for a second attempt.
- **An attendee's agent offers to fix the low-scoring rule.** Say no, for now. Scoring and
  fixing in one pass means the thing that grades the change is the thing that made it, and the
  score stops being evidence. Score first, decide second, fix third, preferably in that many
  sessions.
- **An attendee disagrees with the rubric.** Good, and expected: the five rules are worth
  exactly as much as they describe that system, so rewrite them. What transfers is the shape:
  five rules and no more, a top mark that requires a merge gate, evidence rules per rule, a
  scorer, an adversary that never sees the scorer's reasoning, and a human at the end.
- **Running long.** In this order: drop the volunteer readings at 4:02 to one, then cut the
  adjudication walk-through to the rule 5 DRIFTED item only, then compress the production bullets to
  the first and third. The verifier run is never cut, and neither is the sentence about what a
  PASS means; without them the block is a scoring robot, the opposite of the lesson.
- **Running short.** Take the sixth rule from a volunteer, put it on screen, and ask the room
  to score their own repository against it right there. It takes exactly as long as you have
  and it ends on their rule rather than yours.
