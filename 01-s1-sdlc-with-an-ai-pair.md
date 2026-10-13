# Session 1 (9:00-9:15): The SDLC with an AI pair

**Type:** lecture, no code. **Goal:** by 9:15 the room can name the shape of the day - the
software lifecycle, one block per phase - and carries one mental model for the agent: a very
fast new hire that onboards off the same rules humans do. Everything after this is proof of
that model. Fifteen minutes, then hands on keyboards.

**You need:** the ten S1 slides (title, show-of-hands poll, lifecycle map, the day, the new
hire, the honest thing, agent failure bingo, "not today", what moved this year, how today
works), whiteboard/marker, and a small prize for the bingo winner (awarded in S9). Nothing
running on your side: the room's only terminal moment is the `claude --version` / `docker ps`
check on the last slide; the first real terminal work of the day opens in Lab 1.

## Minute-by-minute

| Time | Beat |
|------|------|
| 9:00 | Welcome, who you are, the one-sentence thesis, then the show-of-hands poll (30 s) |
| 9:02 | The day's map: the lifecycle slide (ten blocks: a map, then nine lifecycle phases), then the day by the clock |
| 9:06 | The agent is a very fast new hire (the load-bearing beat) |
| 9:10 | The honest thing: it will be confidently wrong today, and that is why we build gates |
| 9:12 | Agent failure bingo (45 s), then "Not today": building agents INTO software, and where to go for that |
| 9:13 | What moved this year, and where it shows up today (90 s) |
| 9:14 | How today works: hands-on rules, Manual mode, the thumbs-up check; hand off to Lab 1 |

## Talking points

### The day's map is the lifecycle (4 min)

One-sentence thesis to open with: "Today we run one whole software lifecycle with an AI pair,
and every block on the agenda is labeled by the phase it covers."

Then the show of hands, BEFORE the map, while late arrivals sit down (30 s): A, not on my real
code yet; B, chat and autocomplete; C, an agent edits files in my repo most weeks; D, agents run
in my CI or open my pull requests. Count out loud and remember the split: it tells you who needs
the manual path and who will race ahead. Land the line: "Wherever your hand went up, today ends
at D, with the gates that make D safe."

Put the map on screen and walk it once, top to bottom. Ten blocks, this one included: a map,
then nine lifecycle phases.

- **Map** - S1, 9:00. This slide.
- **Plan** - Lab 1, 9:15. Spec-driven development: requirements and design captured in a spec,
  plan mode, approve, implement, verify.
- **Design + build** - Lab 2, 10:20. Domain layer, the Result pattern, aggregates, test-first.
- **Build + test** - Lab 3, 11:10. CQRS by hand, the decorator pipeline, slices driven by a
  reusable Agent Skill, and an integration test written before the code.
- **Verify** - Lab 4, 12:50. Fitness tests and guardrails: rules that bind humans and the agent.
- **Review + integrate + release** - Lab 5, 1:30. Public repo, agent-authored CI, branch
  protection, a red PR you fix to green, then a tagged release.
- **Deploy + operate** - Lab 6, 2:15. An Aspire AppHost, the dashboard, health gates, and the
  agent reading live telemetry to find and fix a planted fault.
- **Extend** - Lab 7, 3:00. The module exposed as an MCP server hosted in the app.
- **Govern** - Lab 8, 3:55. Evals for architecture, the agent as judge.
- **Maintain + improve** - S9, 4:20. The field report: how this actually runs in production.

Breaks at 10:05 and 2:45, lunch at 12:05, wrap at 4:55 with a three-minute recorded clip of a
module being extracted into its own service. Questions any time.

Land the point: "Nobody ships by writing code. You plan, design, build, verify, review,
release, operate, extend, govern and maintain. An AI pair either helps across all of that or it
is an autocomplete with good marketing. Today is the whole loop."

### The app's shape (1 min, one paragraph)

The thing we build is a modular monolith: one deployable, with module boundaries the compiler
enforces, a database per module, and contracts rather than shared internals between them. That
is the professional default in 2026 because it keeps extraction later a move rather than a
rewrite, and the wrap clip shows exactly that move happening. It also happens to be the codebase
shape an agent performs best in, which is the next beat. Do not defend it here; Labs 1, 2 and 4
make it concrete.

### The agent is a very fast new hire (4 min)

This is the beat that has to survive if everything else gets cut.

- Autocomplete guesses your next line. An **agent** is a model with tools in a loop: it reads
  files, searches, edits, runs your build, runs your tests, and reacts to what it sees. The
  unit of work is not a keystroke, it is a task.
- The mental model that changes everything: **the agent is a very fast new hire.** Unlimited
  enthusiasm, zero context, no memory of your team's scars. What do you give a new hire?
  Conventions doc, build instructions, code review, and rules that are enforced rather than
  hoped for (CI, analyzers, protected branches). The agent needs exactly the same four things.
- This is why the two threads are one workshop. A codebase with clear layers, explicit
  conventions, and executable rules is precisely the codebase an agent performs best in, and
  precisely the codebase where you can verify its work cheaply. Architecture discipline is not
  slowed down by AI; it is what makes AI delegation safe.
- Every phase on the map is therefore an onboarding artifact for the new hire: the context file
  in Lab 1, the tests in Lab 2 and 3, the fitness rules in Lab 4, the required checks in Lab 5,
  the telemetry in Lab 6.

### The honest thing (2 min)

Say it before they see it: **the agent will be confidently wrong at least once today, in front
of everyone.** It will claim a test passed that never ran, invent a package name, or scaffold
something nobody asked for. That is not a demo failure, it is the curriculum. Agents are
confidently wrong in ways juniors are not, so the answer is not trust, it is verification you
can afford: small diffs, a green build, a fitness test, a required check. Every gate we add
today exists because the claim and the artifact are different things. S9 collects the ones that
bit me in production.

### Agent failure bingo (45 s)

Bridge from the honest thing: "So let us make a game of it." Phones up, photo of the slide:
eight real failure modes (phantom fix, the test that changed, confident wrong API, helpful
bulldozer, invented config key, scope creep with a reason, vacuous test, quiet drift) plus the
free square. Spot one in your own session, note the square and the time; a full row with the
evidence still on screen wins at the 4:50 debrief in S9. When one happens on the projector
today, call it: "That is a square."

### Not today: building agents INTO software (1 min)

One slide, deliberately. Two different jobs share the word "agent":

- **Using an agent to build software** - today, all day.
- **Building agents into your software** - agent frameworks in your own app, agent-to-agent
  protocols, multi-agent orchestration. That is a different day and a different workshop.

Name the pointer out loud: if that is what you came for, the Microsoft Agent Framework 1.0 docs
and the A2A protocol spec are where to start (Workshop B territory, not this room). Lab 7 is the
one place the two touch: we host an MCP server inside the app, which is how you make your
software legible to somebody else's agent. That is an adapter, not an orchestration story.

### What moved this year (90 s)

One line per key press, one sentence each, and do not teach any of it here: each line names the
lab that does. MCP 2026-07-28 and the stateless core (Lab 7); open formats at the Linux
Foundation's Agentic AI Foundation, and SKILL.md as an open standard (Labs 1, 3); Claude Code
reading AGENTS.md natively and starting new sessions in auto mode (the next slide acts on that
one); Aspire 13.6 and `aspire agent mcp` (Lab 6); C# 15 unions in .NET 11 RC1 (Lab 2 sidebar);
Agent Framework 1.0 and A2A 1.0 (still not today). Close on: every lab is pinned to .NET 10 LTS;
the tools move again by spring, the habits do not. Re-check the slide the week of the conference.

### How today works: the hands-on rules (1 min)

- **Every lab has a manual path.** A Claude subscription is nice to have, not required. Each
  handout has a manual path (no AI) section and the end state is identical.
- **Snapshot branches.** Every handout names its end-state branch. Stuck for more than five
  minutes? Check out the branch named on that handout (`git checkout lab3-end`, say) and rejoin.
  Nobody falls behind for more than one block.
- **Start the agent in Manual mode: `claude --permission-mode default`.** New installs start in
  auto mode, and the prompts would never appear; VS Code users pick Manual in the mode indicator.
  From Lab 4 on, once the repo carries `.claude/settings.json`, they start plain `claude` so the
  repo's `acceptEdits` default applies.
- **Permission prompts are part of the teaching, not friction.** When the agent asks, read what
  it is asking for. Half of today's lessons are in those prompts.
- Interrupt me. A question during a lab is worth more than a question in the hallway.
- Close with the check: thumbs up when `claude --version` and `docker ps` both answer; thumbs
  sideways pair with a neighbor until the 10:05 break, and a TA goes to each. Docker failing does
  not block Lab 1.

## Transitions

- **Into S1:** you are the first thing after the setup clinic, so open with energy and the
  one-sentence thesis before the map.
- **Out of S1, into Lab 1 at 9:15:** "The first thing you give a new hire is the conventions
  doc, not a ticket. So the first thing we write is not code. Open a terminal." Do not summarize
  the map again; Lab 1's frame re-lands it in three minutes.

## If things go wrong

- **Running late past 9:08:** cut the app's-shape paragraph and the "not today" slide to one
  sentence each (past 9:14, "What moved this year" too). The new-hire beat and the honest thing
  are the two that must survive, and the Manual-mode line on the last slide is never cut; Lab 1
  starts on time regardless.
- **Room is quiet / no energy:** skip the show of hands, keep the map short, get to the
  keyboard early.
- **Setup clinic overran and people are still installing:** start anyway, say helpers stay on
  it through this block, and remind them Lab 1's first ten minutes need only a terminal, Git
  and a text editor.
- **Somebody wants the agent-frameworks conversation now:** name the pointer, offer the break,
  move on. It is the one derail that can eat the whole block.
