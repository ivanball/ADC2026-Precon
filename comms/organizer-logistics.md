# Organizer logistics sheet: ADC 2026 precon

Workshop: "Build an AI-Ready .NET App with an AI Pair: Clean Architecture, MCP, and
Agentic Workflows" (full day, 9:00-5:00, plus 8:15 setup clinic).
Instructor: Ivan Ball-llovera. One TA/room helper preferred (can be a volunteer; a briefing sheet
exists).

## Room requirements

- **Classroom seating with tables** (attendees code all day on laptops); not theater style.
- **Power at every seat.** This is the hard requirement: 7 hours of compiling drains any
  battery. Power strips per table row.
- **Projector/screen** with HDMI or USB-C input, readable code from the back row (1080p
  minimum). Instructor presents terminal + IDE, not just slides.
- **Whiteboard or flip chart with markers**: two core demos are drawn live.
- **Wifi** sized for the room doing simultaneous NuGet restores and one ~700 MB container
  image pull for stragglers who skipped the homework (the pre-email pushes both to home
  wifi, but plan for 30 percent not doing it). Instructor brings offline fallbacks (USB
  package cache + container image) so a wifi brownout degrades, not cancels.
- Lapel or handheld mic for rooms over ~40.
- Room access from **8:00** (setup clinic at 8:15), teardown by 5:30.

## Catering / schedule interaction

Breaks at 10:05 and 2:45, lunch 12:05-12:50. If catering is shared with other precons,
nothing special is needed; if this room schedules its own, keep lunch to 45 minutes, the
afternoon depends on it.

## Attendee cap and prerequisites

- Recommended cap: **40** with one TA (every attendee codes; support load scales with
  heads, not seats). 25 is the comfort zone.
- The listing MUST state (this is the number one support issue if omitted):
  - Bring a laptop you can install software on (.NET 10 SDK, Docker Desktop, Git, an IDE,
    the GitHub CLI (signed in), the EF Core tools, the Aspire CLI 13.6 or newer and its
    templates, Node.js 22.19 or newer).
  - A GitHub account is needed; the repo attendees push that day is PUBLIC, because branch
    protection with required checks is only free on public repositories.
  - Claude Code is nice to have, not a prerequisite: a no-AI manual path exists for every
    lab, the MCP lab works with the free MCP Inspector or VS Code, and the evals lab has a
    follow-along path.
  - Intermediate .NET assumed (comfortable with C#, DI, and basic EF Core).
- A pre-conference setup email goes out before the event, with the setup portion resent 3
  days before; the instructor supplies it. Please confirm the registration system can send attachments or links to registrants.

## Listing copy (short form)

One day, the whole software lifecycle with an AI pair. You start from a spec-driven plan
and context files, build a domain layer and CQRS slices test-first on .NET 10, then pin the
rules down with architecture fitness tests and agent guardrails so the tests catch the AI
breaking a rule, live. After that you ship: a public GitHub repo, a CI workflow the agent
writes, branch protection with required checks, and a tagged release that publishes a
container image. The afternoon runs the app on an Aspire AppHost and lets the agent read
live telemetry to find and fix a planted fault, exposes the module as a Model Context
Protocol server so other agents can call it, and closes with evals for architecture where
the agent is the judge. Bring a laptop; Claude Code is nice to have, not a prerequisite
(every lab has a manual path).

(Long-form abstract, audience, format: see the proposal document.)

## A/V and recording

- No special A/V beyond the projector; the instructor's machine drives everything.
- If ADC records precons: fine to record. One short pre-recorded clip plays at the close of
  the day (about 3 minutes); everything else is live. The cloud deploy segment is talked
  through, or shown finishing if it was started before the lab, so it needs no recording.

## Open questions for ADC

1. Can the conference negotiate Claude workshop credits or day passes with Anthropic? The
   day does not depend on them, but credits would be a nice accelerator for attendees
   without a subscription. (Asked every year at AI workshops; worth one email.)
2. Confirm room wifi capacity and whether a wired drop is available for the instructor
   machine. Nice to have, not required: it helps the multi-process demo and the optional live
   cloud deploy, which runs for about 16 minutes and never over the shared room wifi (without
   a wired drop it runs on the instructor's phone hotspot).
3. Confirm attendee-cap enforcement in registration and that the listing carries the
   laptop and tooling prerequisites.
