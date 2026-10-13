# S9 (4:20-4:55) + Wrap (4:55-5:00): Field report, how I actually run a production SDLC with an AI pair

**Type:** lecture, with one 5-minute mini-lab and one 4-minute live demo. **Phase:** Maintain
+ improve. **Goal:** by 5:00 the room has seen what the day's disciplines look like after a
year of real use on a real codebase, has written one skill of their own, and leaves with
calibrated trust: impressed by what they built, clear-eyed about how the agent fails, and
holding a concrete list of what to do Monday. This is the only block where you talk about
production work rather than the workshop repo, so the numbers have to be real and the candor
has to be first-hand. Do not soften it.

**You need:** the 3-minute extraction clip already open on the desktop and cued (do not
alt-tab hunting for it at 4:55); two terminals sitting in the two demo worktrees, each with
one command left to type; a third terminal on the reference repo for the merge; the starter
kit repo open in a browser tab with the last slide carrying its URL; the snapshot-branch
slide; about twelve slides. Rehearse the worktree demo twice, once with the network off.

**Snapshot branch:** `lab7-end`. The two demo worktrees branch off it, and the one repo
excerpt in this sheet is read from it.

**Hand-off in:** Lab 8 ends at 4:20 with the room having watched a scorer cite `path:line`
and an adversarial verifier return CONFIRMED, DRIFTED or FLAG on those citations. Open on that:
"That rubric run is the smallest version of what the last thirty-five minutes are about."

## The scrub rule for this block (instructor note, not a slide)

Everything in S9 comes from production work, and none of it is named. Say **"my open-source
.NET framework"** and **"the two production apps built on it"**, and nothing more specific: no
repository names, no package identifiers, no cloud resource names, no client names. Numbers
and mechanisms are the whole value and they carry fine without names. Check every slide and
screenshot before the conference; one visible identifier turns a field report into an
advertisement.

## Minute-by-minute

| Time | Beat | Min |
|------|------|-----|
| 4:20 | Skills as codified workflows (what a command was, why skills replaced it, the three tiers) | 4 |
| 4:24 | Mini-lab: write one skill | 5 |
| 4:29 | Demo: two agents, two worktrees, one merge | 4 |
| 4:33 | Documentation that cannot drift | 5 |
| 4:38 | Context engineering: memory, wiki, generated onboarding | 4 |
| 4:42 | The waves, and the one slide where the agent got it wrong | 4 |
| 4:46 | Token and context discipline: seven rules | 4 |
| 4:50 | Delegation rules of thumb | 2 |
| 4:52 | The starter kit, in adoption order | 3 |
| 4:55 | Wrap: the clip, the branches, Monday morning, goodbye | 5 |

## The candor thread (instructor note)

There is no separate "here is how it fails" segment. Five real failure stories sit inside the
segment whose countermeasure they motivate: name the tell, name the countermeasure, move on.
Do not cluster them. A block of failures reads as a disclaimer; one per segment reads as
experience.

| Story | Lands in |
|-------|----------|
| The phantom fix | Skills (4:20): why every skill ends with "show the output" |
| The confident wrong API | Documentation (4:33): the agent's own summary is a drift source |
| The quiet drift | Context engineering (4:38): the session is a workspace with a lifecycle |
| The helpful bulldozer | The waves (4:42): review capacity is the scarce resource |
| The test that passes because it changed | Delegation (4:50): the highest-risk diff shape |

## 4:20 Skills as codified workflows (4 min)

Frame: "You wrote a skill this morning without me calling it that. Here is what happens when
you have twenty of them."

Talking points:

- **What it replaced.** The first version of this was a slash command: a markdown file with a
  prompt in it, invoked by name, arguments substituted in. That is still a perfectly good
  primitive and it is what Lab 3 would have used a year ago. The problem with a slash command
  is that it only ever fires when a human types its name, so the ones you need most are the
  ones you forget you wrote.
- **What a skill adds.** A skill is the same idea with a trigger attached: frontmatter with a
  `name` and a `description`, and a body of imperative steps. The description is matched
  against what the user actually said. So a skill fires on the situation, not on the name.
- **The rule that decides whether a skill is worth writing at all:** the description is a
  trigger, not a summary. Written as a summary of the mechanism ("Adds a vertical slice using
  the Application and Presentation layers") it never fires. Written as the situation in the
  user's own words ("Use when asked to add a new command or query slice, wire up a new
  endpoint, or implement a use case end to end") it fires on turn one. Say the failure mode
  out loud because it is invisible: **a skill that never fires is indistinguishable from a
  skill that does not exist.** Nobody gets an error. The work is simply done the long way,
  forever.
- **The three tiers, and this is the part teams get wrong.** The `description` is ambient: it
  sits in the window of every single turn, so it is one or two sentences and it is all
  trigger. The body loads only when the skill is invoked, so that is where the steps go. A
  `references/` file loads only when the body says to read it, so that is where the
  background and the rationale go. The test for any line: if it explains *why*, it belongs in
  a reference, not in the body.
- **Candor, story one: the phantom fix.** Early on, an agent edited a file, declared the bug
  fixed, and wrote a summary that read perfectly. The test had never been run and the fix did
  not compile. The tell is a success claim with no command output near it. The countermeasure
  is in your hands already, and it is why the `/slice` skill you ran at 11:37 ends the way it
  does: the last step is "run it and show the output", and warnings are errors so a build that
  reports anything is a failure. **Ask for the artifact, not the conclusion.** The command and
  its exit code, the citation, the pasted summary line. Never "it builds".
- Transition line into the mini-lab: "You have all had a most-repeated request today. Let us
  make it a file."

## 4:24 Mini-lab: write one skill (5 min)

This is a writing exercise, not a build. Nobody runs a test. Five minutes, timeboxed hard,
and it is never the segment you cut.

**The ask, on screen:** "Pick the thing you asked the agent for more than once today. Write
it as a skill in your own helpdesk repo at `.claude/skills/<name>/SKILL.md`. Two minutes on
the description, two on the steps."

Three candidates to offer for anyone who cannot pick (read them out, they are all real):

- **`fitness-rule`** - "add a new architecture rule from an English sentence": turn "the
  domain layer may not reference infrastructure" into a test in the existing fitness project,
  then prove it can fail.
- **`ci-diagnose`** - "read the failed job log and name the FIRST failed step": not the last
  error in the log, the first step that went red, plus the one-line cause.
- **`handoff`** - "write the five-line handoff file before I clear this session": what we are
  doing, where it stands, what was tried and ruled out and why, next action, open questions.

Put the shape on screen while they write, from the skill they already ran this morning:

**File: `.claude/skills/slice/SKILL.md` (excerpt: the shape)**

```markdown
---
name: slice
description: Use when asked to add a new command or query slice to a module, wire up a new
  endpoint, or implement a new use case end to end through Application, Presentation and
  registration.
---

# Add a vertical slice

Add one command or query, its handler, its validator, its endpoint and its registration.
One use case per slice. Follow CLAUDE.md and AGENTS.md exactly; they are the contract.

## Steps

1. Read CLAUDE.md, then read the nearest existing slice and copy its shape. The existing
   code is the specification; do not invent a second way of doing this.
...
7. Verify: run the build and the tests. Show the output. Warnings are errors, so a build
   that reports any warning is a failure.

## Constraints

- Never modify SharedKernel, the Domain layer, or an existing test to make a slice pass.
- If a step conflicts with an existing convention, stop and ask rather than improvising.
```

Narrate the four things that make it work while they type: frontmatter description written as
the situation; "the existing code is the specification" instead of a description of the
pattern; a verification step that demands output; and constraints phrased as a positive
default wherever possible ("stop and ask" rather than only "do not improvise").

**Manual path.** Attendees without an agent write the same two pieces on paper: the
description sentence and the numbered steps. They get the whole lesson, because the lesson is
the writing, not the running.

**The takeaway to land at 4:29:** test a skill
the way you would test a hire's job description. Fresh session, describe the situation in your
own words, never name the skill. If it does not fire, the description is wrong. Not your
phrasing. The description.

## 4:29 Demo: two agents, two worktrees, one merge (4 min)

Rehearsed script. The two agents are already running by the time you finish the first
sentence, and you talk over them. If you have not rehearsed this twice, run the fallback.

Terminal 3, on the reference repo, before the block starts (do this during the mini-lab, not
on the clock):

```bash
git worktree add ../helpdesk-wt-a -b demo/slice-a lab7-end
git worktree add ../helpdesk-wt-b -b demo/slice-b lab7-end
git worktree list
```

Still during the mini-lab, start `claude` once in each worktree (terminals 1 and 2) and accept
the folder trust dialog. A fresh worktree path is untrusted, so the project allowlist in
`.claude/settings.json` is ignored until trust is accepted, and the first launch shows the
dialog. The repo runs without the sandbox (Lab 4, Beat 3), so expect permission prompts for
`docker compose up -d` and `dotnet test` in both terminals at the end of each run. Decide now: approve the build, deny the tests in terminal 2 (that is the scope
fence talking point below, made live).

At 4:29, in terminal 1 and terminal 2, which are already sitting in the two worktrees, type
one line each and hit enter:

```
/slice AddChildTask
```

```
/slice GetChildTasks
```

One command plus one query on behavior `Ticket` already has, so neither agent needs a Domain
change (the skill forbids one); expect a clean merge, 0 warnings, architecture tests 5/5. Each
agent finishes in under a minute, well inside the 150 seconds of talking points, and sits idle
at a prompt while you finish. Do not cut the talking points.

**What to say while both agents run (about 150 seconds, this is the real content):**

- "Two checkouts of the same repository, two branches, two agents, one clone. A worktree is
  not a copy of the history, it is a second working directory on the same object database, so
  this costs a few hundred milliseconds rather than a re-clone."
- "This is the only kind of parallelism I trust by default: independent units, a brief for
  each that I could write before seeing either result. If I had to see slice A before I could
  brief slice B, this is not a fan-out, it is a pipeline wearing a fan-out costume, and
  running it wide just means being wrong in parallel."
- "One writes child tasks, one reads them. Neither needed the other to exist to be briefed,
  which is the test for a real fan-out."
- "Notice what is NOT parallel: my attention. Two agents finishing at once means two diffs to
  review at once, and review is the expensive half. Pick your width by the narrowest resource
  in the chain, which is usually you."
- **The honest detail, say it, it is the best 15 seconds in the demo:** "Both of them want to
  run the test suite against the same database container at the end. They will queue, or they
  will collide. In production I give the second one a scope fence that says build only. One
  database, two writers, is exactly the constraint we just talked about. The second agent's
  test run would drop the first one's database." (True: the API test factory calls
  EnsureDeleted on a shared database name.)

Then merge, in terminal 3:

```bash
git checkout -b demo/parallel lab7-end
git merge --no-edit demo/slice-a
git merge --no-edit demo/slice-b
dotnet build Helpdesk.slnx
dotnet test tests/Helpdesk.ArchitectureTests
```

Two clean merges, because the two slices touched different files in the same predictable
places: one new Application file each, one test file each, one endpoint and one registration
each. The command went after the last command and the query after the last query (on
`lab7-end`, `TicketsApplication.cs` marks the two registration lists with `// Commands` and
`// Queries` comments), so the two edits never touched the same lines. Say the load-bearing
line: **"they merged cleanly because the convention decided where each file goes. Consistency is not a style preference here, it
is what makes parallel agents mergeable."**

If the merge conflicts anyway (placement is the agent's choice, not enforced), say this one
line while resolving: "Both agents appended to the same registration list, so git sees two
inserts at one spot. That is a textual conflict, not a logical one: keep both, then the build
and the architecture tests tell us whether the result is right." Keep both blocks, build, run
the architecture tests. If it is not resolved by 90 seconds, go to the recorded fallback.

Clean up on camera, it takes six seconds and it teaches the habit:

```bash
git worktree remove ../helpdesk-wt-a
git worktree remove ../helpdesk-wt-b
git worktree list
```

**The background-agent variant (one paragraph, slide only, no demo).** The same shape without
two terminals: one session, two background tasks. That is the right tool when the work is
read-heavy and does not write to the tree, such as searching four repositories for every
implementer of an interface, or reading a failed pipeline log while you keep working. It is
the wrong tool for two writers in one working directory, because they will fight over the same
files and the loser is silent about it. Rule of thumb: background for reading, worktrees for
writing.

## 4:33 Documentation that cannot drift (5 min)

Frame it as the problem, not the tooling: "Documentation does not rot because people are lazy.
It rots because nothing fails when it is wrong."

- **Decision records, audited by agent.** 129 architecture decision records, and a command
  that dispatches one agent per record to re-verify every assertion in it against the current
  source, with `path:line` citations, then hands anything it calls drifted to a second,
  adversarial agent that re-reads the source itself. The measured shape of the 2026-09-19 sweep:
  2,265 assertions checked, 1,237 confirmed, 987 drifted, 41 unverifiable.
- **The number that changed how I run this:** the drift splits about **21% real content and
  79% stale line anchors**. Four out of five "the docs are wrong" findings are a citation
  pointing at a line that moved. That is not a documentation problem, it is a linking problem,
  and it means the expensive human review belongs on the 21%. Knowing the split is what made
  the audit affordable.
- **Candor, story two: the confident wrong API, and its grown-up form.** The junior version is
  the agent writing plausible code against a method that does not exist, or a package that
  does not exist at all, which is an actual supply-chain hazard because squatters publish
  packages under commonly hallucinated names. The grown-up version bit me here: **my own
  briefs to the audit agents were a drift source, refuted in seven consecutive cycles.** I
  would hand an agent "here is what I think is wrong with record 49" and it would dutifully
  confirm my error. The fix is one sentence in every brief now: *the proposed fixes are NOT
  authoritative, re-verify against source, source wins, and say so when it does.* That one
  line caught wrong counts, a wrong identifier, and a brief that contradicted itself.
- **Scorecards, where the agent scores and a script counts.** A 34-category rubric, one agent
  per category, each returning a maturity score, an implementation score and the `path:line`
  that justifies it. The indices are NOT computed by the model. A script re-derives both
  indices and every weighted row from the table as written and exits non-zero on a mismatch.
  The general rule, and it is the single most useful thing in this segment: **retrieval from a
  long context is close to solved, aggregation over it is not.** Pulling one fact out of a
  large window stays reliable. Summing 34 weighted rows does not, and it fails *fluently*: the
  wrong total comes back well-formed, confident and off by two. A hand re-sum is not a check,
  it is the failing operation auditing itself.
- **Drift between two apps (one line, as promised in Lab 8).** The same machinery pointed
  sideways: compare the two production apps against each other over every decision record and
  all 34 categories, two passes, the second adversarial. The second pass overturns nine to
  thirteen of the first pass's "drift" findings on every run, which is exactly why it exists
  and why it is never skipped.
- **Onboarding generated from an inventory, not written.** A small tool walks the source with
  a syntax parser and emits every public type with its exact `file:line`; the guide is
  assembled from that inventory, and a verify script fails the build if a section names a type
  that no longer exists. 5,234 types named with their file and line, mechanically, not
  claimed. Nobody writes that by hand and nobody keeps it true by hand.
- **The facts gate.** One generated file in the framework repository holds the framework-wide
  numbers, and a required check compares it against the code on every pull request. If the
  number of packages changes and the file does not, the build goes red. That is the whole
  trick of this segment in one sentence: **documentation that cannot drift is documentation
  something fails on.**

## 4:38 Context engineering (4 min)

"Context is an attention budget, not a storage budget." Put that on the slide and defend it
with the measurements.

- **Attention is a softmax over every position**, so every token admitted takes weight from
  every other token. That is why rule violations cluster late in long sessions rather than
  early: the rules are still in the window, just diluted. The question for anything about to
  enter is never "does it fit", it is **"will this be read more than once, and is it still
  true?"**
- **Related-but-wrong is worse than irrelevant.** Off-topic noise is easy to ignore. A stale
  copy of a file you have since edited is maximally on-topic and factually wrong, so it
  competes with the truth and often wins. The dominant source is self-generated: a pre-edit
  file body, a failed build log, an abandoned approach.
- **Memory files: one fact each, plus an index.** Not a diary. Each file holds one decision or
  one hard-won gotcha, with a one-line description, and the index of those descriptions is
  what is ambient. When a fact is needed, the file is read. The index is the ambient cost; the
  bodies are not.
- **An agent-maintained wiki and generated onboarding** are the same idea at repository scale:
  the agent writes the reference so the reference stays current, and something fails when it
  does not.
- **Candor, story three: the quiet drift.** No single failure. Over a long session the agent's
  model of the codebase ages, and late edits contradict early decisions. The tells are
  specific and worth memorizing: a file being re-read that was already read this session; a
  decision from an hour ago being contradicted; and most reliably, **the user re-explaining
  something they already said.** That last one is about the human, and by the time it happens
  the session is already degraded.
- **So know what survives.** The context files, memory, disk and git survive everything.
  Decisions are lossy through compaction and gone at a clear. **Tool output and a subagent's
  internal work survive nothing.** Which means anything expensive to re-derive goes to disk
  the moment it is derived, not when it is next needed: a version number, a run identifier, a
  count, a decision and its reason, the exact command that worked. Compaction keeps narrative
  and drops specifics, so **a summary of a number is a rumor about a number.**
- **The drill:** if compaction fired right now, what would have to be found again? Write that
  down. My version is a handoff skill that writes five lines to one path that the next session
  reads automatically. Field three, "tried and ruled out, and why", is the only one that is
  truly unrecoverable.
- One session per unit of work, not per day. Half-finished work on another repository is
  precisely the related-but-wrong shape.

## 4:42 The waves, and the one slide where the agent got it wrong (4 min)

Two and a half minutes on the waves, ninety seconds on the FinOps slide. Do not let the waves
eat the FinOps slide; it is the most credible ninety seconds of the day.

**The shape of a wave:** one audit agent per repository against one rubric, findings returned
with citations, then one fix pull request per repository. It is the highest-value thing I do
with agents and it is entirely a function of having a check to run at the end.

- **Accessibility wave (a clean example).** Four repositories, one audit agent each, about 157
  findings, then one fix pull request per repository and new automated scans as the gate.
  **What it caught:** contrast values that were failing as text everywhere a particular colour
  labelled a control, keyboard traps in the mobile navigation, and missing landmarks, all with
  a scan that now runs on every pull request. **What it missed:** the fix itself broke every
  UI test in three applications, because it mirrored notification text into a live region and
  the tests then matched two elements instead of one. It took a second release to undo. A wave
  is only as good as the gate that runs after it.
- **Performance wave.** **What it caught:** dynamic filter values were reaching the database
  as inlined literals rather than parameters, so every distinct filter value produced its own
  query plan on the hottest read path in every consumer. Fixed in one shared configuration
  across 58 call sites. Nothing in the test suite had ever inspected the emitted SQL, which is
  exactly why it survived; the guard now asserts that two different values produce one SQL
  text. **What it missed, and this is the useful half:** four of the plan's premises were
  simply wrong, and checking caught them. Two endpoints it wanted cached are scoped per caller,
  so caching them would have been a correctness bug. An include it wanted dropped from four
  handlers was safe to drop from two, because the other two read those rows to enforce an
  invariant.
- **Candor, story four: the helpful bulldozer.** Asked for a small change, the agent also
  improves the formatting, renames variables and refactors a neighbour file: a 400-line diff
  for a 5-line fix. The tell is diff size out of proportion to the ask. The countermeasure is
  a scope fence in the brief and reject-and-rerun rather than hand-fixing an oversized diff,
  because **review capacity is the scarcest resource you have** and a diff you cannot review
  honestly is not an asset.

**The FinOps slide: what the agent got wrong (90 seconds, one slide).**

Set it up: "A cost pass on the two production apps. It worked. The monthly bill for the larger
one went from about $256 to a run rate around $148. Here is the part that goes on the slide."

- **What it got right, and why:** the biggest lever was two families of runtime metrics that
  were about 65% of log ingestion, roughly 290 of 500 MB a day, with **zero alert or dashboard
  consumers**. The agent checked the consumers before recommending the switch-off. That check
  is the whole difference between a cost saving and an outage in three weeks.
- **What it got wrong:** in the same pass it set an export-interval environment variable on
  every single service, deployed it, and we both believed it was saving money. Measured much
  later, the exporter ignores that variable entirely: the metrics were still arriving every 60
  seconds. A plausible configuration key, shaped exactly right, named exactly the way I would
  have named it, deployed to production, doing nothing.
- **The general lesson, and it is the reason this slide exists:** the compiler catches an
  invented method. **Nothing catches an invented configuration key.** Code that does not exist
  fails loudly; configuration that does not exist fails silently and looks like success. So
  the rule I now hold: a configuration change is not done when it deploys, it is done when a
  measurement shows the thing it was supposed to change actually changed.
- **One more, thirty seconds if you have it:** a scheduled maintenance job was cancelled at
  its timeout part way through, so its cleanup never ran and it left a database copy behind,
  quietly billing. The next scheduled run could not detect it. That is the asynchronous-work
  rule in one incident: **a detector that could not run is a finding, not silence.**

## 4:46 Token and context discipline (4 min)

Open with the measurement, because the rules are obvious once the number is on screen. 253
sessions, 30 days, one workspace, measured by a script that reads the usage records:

| Measured | Value |
|---|---|
| Output tokens, as a share of all tokens processed | **0.51%** |
| Mean context re-sent per main-thread turn | **245 K** |
| Cache hit rate on the expensive sessions | 93 to 99% |
| Cold prefix rebuilt by clearing a session | **61.3 K** |
| Subagent share of billing, versus the main thread | **21.4% / 78.6%** |
| Top 10 sessions, as a share of the month | 32.2% |

"Every turn re-sends the whole conversation, so the bill is roughly resident context times
turns. The thing you read, the output, is half a percent. **Trimming your prompt for concision
is, economically, almost pointless. Ending the session is not.**"

The seven rules, one line each:

1. **Pass paths, not bodies.** Pointers compress perfectly because the agent can go read them.
   Bodies do not compress at all, and a pasted file body is also the fastest way to compromise
   a verifier: give it the claim, never the reasoning that produced the claim.
2. **Deterministic work goes to a script.** Every derived number comes from a re-runnable
   script, never from a second pass of the same model over the same window.
3. **Let the structured output be the report.** Ask for the artifact, not the conclusion, and
   specify the return shape. The shape is checkable where a procedure is not, and asking for
   `path:line` in the return changes what the agent collects from the first file it opens.
4. **Tier the model by the cost of being wrong, not by difficulty**, and keep two effort
   settings rather than one: high effort for the hard main-session turns, ordinary effort for
   narrow, checked, numerous fan-out work where the cost multiplies by N.
5. **Batch turns, and clear early.** One session per unit of work. Above roughly 300 K
   resident, clearing is decisively cheaper; below 100 K it buys quality rather than money.
   And because the cache holds a *prefix*: **append, do not mutate.** Editing your context
   file mid-session throws away the discount on every later turn.
6. **Chunked fan-out with resume.** Rate limits arrive in waves and a rate-limited fan-out
   does not degrade, it dies, taking the completed units with it. Null-guard every return,
   track the failed units, refill in sequential chunks of five, and re-run only what is still
   listed.
7. **Bound every read and never discover code with a recursive shell search.** Measured on an
   idle machine: a recursive shell grep over one repository walks 27,000 files, 96% of them
   build output, and takes 3 minutes 33 seconds. The equivalent indexed search returns in
   about one second.

**The punchline, and it is the one I got wrong:** I fully expected the expensive thing to be
wide fan-outs. Measured, subagents are 21.4% of the bill and the main thread is 78.6%, and the
single most expensive session of the month used **zero subagents** across 1,671 turns at a
413 K mean context. **The lever is main-session length, not fan-out width.** Keep the method,
not my answer: run the measurement on your own workspace, because the expectation arrived
packaged with the framework and the measurement contradicted it.

## 4:50 Delegation rules of thumb (2 min)

**Bingo first (about 30 s, its own slide, "Bingo, then five ways it goes wrong").** Everyone
with a full line stands; glance at one screenshot or noted time, draw one name for the prize,
and name anyone with a full card. Then the five stories on that slide, then the delegation
slide.

One slide, two columns, then one sentence.

**Delegate freely** (mechanical, and you already have the check): scorecard and audit passes,
inventory and documentation regeneration, coverage scouting, build-and-fix loops, namespace
moves, test scaffolding, search, first-draft docs, the slices from Lab 3.

**Keep the pen** (judgment, or you need the model it builds): domain invariants, contracts
between modules and anything public, security boundaries, dependency choices, and any pattern
that forty files will copy. You are buying the mental model, not the code. A pattern you
accepted rather than built is one you cannot later defend, extend, or notice being violated.

The heuristic: **delegate work whose verification you already have, keep work whose
verification you would have to invent.** And the term everybody drops from the break-even:
brief, plus wait, plus **review**. Two minutes to describe beats twenty to write, until
fifteen go into reading the result.

**Candor, story five: the test that passes because it changed.** Asked to make a failing test
pass, an agent edits the test's assertion. Technically compliant, completely wrong, and it is
not misbehaviour: if the goal you stated was "make it green", then loosening an assertion,
suppressing an analyzer or lowering a threshold are all valid solutions to the problem you
actually posed. So the defence is structural rather than vigilance: I run a script over every
diff that classifies whether it touches a gate, a threshold, a suppression or an assertion,
and it asks me at pull-request time. **A change that touches both a test and the code that
test covers is the highest-risk shape in the system.** Read the files touched first, the gates
second, the logic last, and read the diff before you read the agent's summary of it.

## 4:52 The starter kit, in adoption order (3 min)

Walk the repository, do not read the files. The link is on the last slide, it is public, it is
MIT, and every item in it is something you watched work today.

1. **`CLAUDE.md` and `AGENTS.md` templates.** Thirty minutes on your real repository is the
   biggest single lever you have. Include the gotcha you tell every new hire.
2. **`settings.json` and the two hooks**, with deny rules, and the permission-mode
   example from Lab 4. Three tiers, not two: allow the read-only and reversible work, prompt
   on writes beyond the repository and on anything that leaves the machine, and **deny in a
   hook whatever must never happen regardless of who asks.** A prompt is probabilistic
   because it depends on attention at that moment; a deny is deterministic.
3. **The three skills:** the slice skill from Lab 3, a spec-first change, and a CI diagnosis.
   Rewrite the descriptions in your own words before you use them, for the reason in the
   mini-lab.
4. **The fitness-test seed** from Lab 4. Adapt the namespaces, then prove each one can fail. A
   fitness test that cannot fail is decoration.
5. **The CI and release workflow templates** from Lab 5, including the lock files and audit
   mode.
6. **The Aspire AppHost seed** with the liveness and readiness gate wiring from Lab 6, plus
   the setup note for connecting an agent to it.
7. **The mini rubric with the scorer and verifier agent definitions** from Lab 8, scrubbed and
   ready to point at your own repository.
8. **The token-discipline checklist**, one page.
9. **The MCP host reference** project from Lab 7.

Ordering argument, say it explicitly: **1 through 5 are guardrails, 6 through 9 are
acceleration, and the acceleration only compounds safely after the guardrails exist.** A team
that adopts the speed without the gates generates unreviewable code faster.

## 4:55 Wrap (5 min)

**The clip (3 min).** Play the recorded extraction clip. Narrate only the last slide of it, in
this order, slowly:

- Zero changes to the domain, application or presentation layers, or to any handler.
- Zero changes to any test. The fitness tests pass in both topologies.
- The client saw the same URL before and after.
- Total new code: one host entry point, one gateway configuration, and, when you eventually
  need it, one message transport class.

Then the line: "**That is what the four disciplines from nine o'clock bought.** Extraction was
a deployment decision, not an engineering project. And notice you may never need to do it: the
modular monolith you built this morning is a perfectly good place to stay. The point is that
staying is now a choice."

**The snapshot branches (30 seconds).** Slide with the branch list and the repository URL:
`lab1-end` through `lab7-end`, one per lab, plus `main`, which is the take-home: it also has
the outbox and the extracted service from the clip you just watched. `docs/branches.md` on
main lists every branch.

**Monday morning, the last content slide (60 seconds).** Read it, do not elaborate:

1. Write `CLAUDE.md` for your real repository: commands, layer rules, conventions, the Never
   list. Thirty minutes, biggest single lever.
2. Check in `.claude/settings.json` with your deny rules, and add one hook for your scariest
   command. That directory is shared infrastructure exactly like `.editorconfig`: review
   changes to it like code, because it is code.
3. Add three architecture fitness tests to the suite you already have. Your domain layer's
   dependency rule is almost certainly test one.
4. **Turn your most-repeated request into a skill.** You wrote one at 4:24. Ship it.
5. Only after 1 through 4 have settled: agent review in CI, subagents, and the nine kit items
   from the last segment.

**The closing frame (30 seconds), never cut.** Back to the first whiteboard: "This morning I
drew three pictures: a monolith, a modular monolith, and an extracted service. You built the
second, you watched the third, and an AI did most of the typing while your tests kept it
honest. The architecture made the AI safe; the AI made the architecture cheap. Neither claim
works without the other, and now you have both."

Thank the room. You will be around for hallway questions.

## Transitions

- **Into S9 at 4:20:** the "Hand-off in" line at the top, then straight into skills. Do not
  recap the day; the wrap does that.
- **Out of the mini-lab at 4:29:** the two agents in the demo worktrees should already be one
  keystroke from starting. Walk to the terminals while you deliver the description-is-the-
  trigger takeaway.
- **Into the wrap at 4:55:** hard cut. "Two things left." Start the clip.
- **If a question lands at 4:58:** answer one, defer the rest to the hallway. Rooms turn over
  hard at conferences, and the last impression should be the closing frame rather than an AV
  crew unplugging you.

## If things go wrong

- **The worktree demo fails** (an agent stalls, a merge conflicts, the network dies): stop at
  90 seconds, do not debug in front of the room. Two recoveries, in order. Play the recorded
  fallback of the same demo, or narrate the merge from the slide with the commands on it,
  which costs nothing because the content of the segment is the talking points, not the
  output. Say why out loud if it fails live: "that is the other half of the field report."
- **The clip will not play.** Narrate it from the sheet. The four "what we did NOT change"
  lines above carry the entire point without a single frame of video.
- **Running long.** Cut in this order, and only in this order: the worktree demo first (the
  background-agent paragraph plus the merge slide covers it in 60 seconds), then the waves
  segment down to the FinOps slide alone, then the documentation segment down to the drift
  split and the facts gate. **Never cut the mini-lab and never cut the wrap.** The mini-lab is
  the only thing in this block they do with their own hands, and the wrap is the last thing
  they will remember.
- **Running short** (the mini-lab finishes early, or the demo lands in two minutes): tell a
  sixth failure story rather than expanding a segment. The one that always earns its time is
  the audit brief that was itself wrong and got confirmed by an agent that was trying to be
  agreeable, and what "source wins, and say so" did to it.
- **Somebody asks what tools or what codebase.** Answer the mechanism, never the name: "an
  open-source .NET framework of mine and the two production apps built on it". If they push,
  that is a hallway conversation. It stays out of the room.
- **Somebody asks for the cost numbers in dollars per month for their own team.** Decline the
  extrapolation and give them the method instead: the measurement script shape, resident
  context times turns, and "run it on your own workspace, because my expectation was wrong on
  my own data".
