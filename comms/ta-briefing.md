# TA / room helper briefing (one page)

Thanks for helping. Your job in one sentence: **keep every attendee moving during labs so
the instructor never has to stop the room for one machine.**

## The day at a glance

Eight labs: 9:15 (spec-driven skeleton), 10:20 (aggregate, test-first), 11:10 (three vertical
slices + an API integration test), 12:50 (fitness tests and guardrails), 1:30 (ship it: CI,
branch protection, the deliberate-violation demo, release), 2:15 (run it on Aspire), 3:00
(the MCP server), 3:55 (evals). Two instructor-only demos you do not need to support: the
Azure Container Apps deploy inside the 2:15 block, and the advisory agent code review on
the pull request inside the 1:30 block. Those are your time to rest. In the 3:55 block the
instructor scores a branch called `lab8-demo` on the projector; that is the instructor's
branch, and attendees score their own repo on the branch they are on.

## Your three tools, in order

1. **Nudge, never type.** Point at the handout line, ask what the diff shows, suggest the
   next command. If you take the keyboard, the attendee stops learning; the one exception is
   a broken environment (see 3).
2. **The snapshot branches.** Every lab handout names its rescue branch (`lab1-end`,
   `lab2-end`, `lab3-end`, `lab4-end`, `lab5-end`, `lab6-end`, `lab7-end`, and `main` for
   the finished state); the branches live in the workshop reference repo, not in the
   attendee's own repo. If someone is more than ~5 minutes behind and frustrated: in their
   repo, `git stash -u && git remote add workshop https://github.com/ivanball/adc2026-helpdesk.git && git fetch workshop && git checkout -B rescue workshop/<branch>`
   (from Lab 6 on most attendees already have the `workshop` remote, so `remote add` says it
   exists: drop that part; or, if they cloned the reference repo before the day, `git checkout <branch>` there and
   continue in that folder), and they rejoin the current step. This is a normal move, not a
   failure; say so.
3. **Escalate environment breakage immediately.** Docker that will not start, a broken SDK
   install, wifi-dead restore: move them to the snapshot branch on THEIR machine if
   possible, to pairing with a neighbor if not. USB sticks at the front have the NuGet
   package cache and the SQL image tar for offline restore.

## Pacing the manual path

Attendees without Claude Code follow the manual-path column of each handout. They set the
real floor of the room's pace, so check on them FIRST each lab. Lab 3 manual is the longest
(three slices by hand); if one is buried at 11:50, the CloseTicket and GetTicketById slices
are copy-adapt from CreateTicket: say exactly that.

## Failure modes to recognize fast

- **Agent modified the tests to make them pass** (Lab 2): tell the instructor, quietly.
  They WANT this one surfaced in the debrief; it pairs with the S9 field-report story about
  the test that passes because it changed.
- **Agent scaffolds extra stuff** (Lab 1): have the attendee reject the plan and re-prompt,
  do not hand-delete the extras.
- **SQL container not running** (first hits in Lab 3): `docker compose up -d`, then rerun
  the migration. The compose file maps host port 14330 so a local SQL Server on 1433 cannot
  shadow the container; sa-login failures usually mean someone hand-rolled a `1433:1433`
  mapping. Point them back to `"14330:1433"` and `Server=localhost,14330`.
- **`dotnet ef` not found**: `dotnet tool install --global dotnet-ef`, restart the shell. On a
  Mac it can stay "not found" after the install because zsh lacks `~/.dotnet/tools` on PATH:
  `echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile`, new terminal.
- **A file survives the Lab 4 FLIP revert**: `git checkout -- .` restores tracked files but
  leaves the new, untracked class file (`TicketQueries.cs`, or whatever name the agent chose).
  The handout's revert block has the `git clean -f src/` line; point at it.
- **`src refspec lab5-violation does not match any`** (Lab 5 push): they edited and committed
  on `main` without creating the branch. `git switch -c lab5-violation`, then
  `git branch -f main origin/main`, then push the branch. The handout has the same recovery.
- **The Lab 5 container answers a POST with a 500 and an empty body after ~15 s**: expected.
  It runs without a database; `/health` should still answer 200. The SQL error is only in the
  container log, because Production shows no exception page.
- **Aspire dashboard: `sql` Unhealthy, `api` stuck Waiting** (Lab 6): a data volume left over
  from an earlier run still holds an old `sa` password. Handout lab6, Troubleshooting, has the
  `docker rm -f` + `docker volume rm` fix.
- **`MSB3027` / file locked on `dotnet test`** (Lab 6): the AppHost is still running and the
  API locks its own `bin` folder. Ctrl+C the AppHost, rerun.
- **PowerShell curl with a JSON body returns 400** (Labs 6 and 7): `\"` is not an escape there.
  Single-quote the body; on Windows PowerShell 5.1 type `curl.exe`.
- **`The syntax of the command is incorrect.`** (Lab 8 copy step): they are in Command Prompt,
  not Git Bash. The handout prints a cmd.exe block right under the bash one; check they are in
  their repository folder, not its parent.
- **"My scorer says rule 4 is a 2 because of CLAUDE.md"** (Lab 8): a sentence in a document is
  not the gate, and the handout tells them to mark that row. Do not settle it for them; it is
  step 5's call.
- **Claude Code permission spiral** (attendee denied something and it re-asks): they can
  say "stop", edit the prompt, and re-run; permission fatigue is a teaching point, not a
  bug to fix for them.

### Mac-only failures (the commands are printed for bash; Windows runs them in Git Bash)

- **`no such service: #`, `MSB1008: Only one project can be specified`, `zsh: command not
  found: #`**, or a `git status --short` that prints nothing when it should: zsh is passing
  the trailing `# comment` to the command as arguments. `echo 'setopt interactivecomments' >>
  ~/.zshrc`, new terminal window, rerun the block. (Oh My Zsh users already have it.)
- **Port 5000 `address already in use`, or `403 Forbidden` with `Server: AirTunes`** (Lab 3
  onward): AirPlay Receiver. System Settings > General > AirDrop & Handoff > AirPlay Receiver
  off, restart the host. Never move the API off 5000; Labs 6 and 7 hard-code it.
- **SQL container exits right after starting, or the Aspire `sql` resource keeps restarting**
  (Apple Silicon): Docker Desktop's Rosetta setting is off. Settings > General > "Use Rosetta
  for x86_64/amd64 emulation on Apple Silicon", restart Docker.
- **`no matching manifest for linux/arm64/v8`** (Lab 5 `docker pull`): the `--platform
  linux/amd64` flag was dropped from the handout command; add it to the pull and the run.
- **Lab 4 hooks fail with "permission denied"**: the executable bit is missing on the working
  copy. The handout's `chmod +x` line fixes it.
- **A heredoc paste sits at a `heredoc>` prompt** (Lab 5 branch protection): the closing
  `JSON` line was not pasted. Ctrl+C (Control, not Command) and paste the whole block again.
- **Keychain password prompt during `aspire run` or `dotnet dev-certs https --trust`**:
  expected; it is the HTTPS development certificate. Their Mac login password.

## Timing signals to the instructor

At each lab's midpoint the instructor will ask you for a hand signal: thumbs up (most of
the room done or close), flat hand (half the room), thumbs down (most still working). Count
screens, not vibes.

## What NOT to do

- Do not debug one machine for 15 minutes while three hands are up: snapshot branch and move.
- Do not answer architecture questions with your own opinions mid-lab; park them for the
  debrief ("great question, raise it in three minutes").
- Do not install anything global on an attendee's machine without them driving.
