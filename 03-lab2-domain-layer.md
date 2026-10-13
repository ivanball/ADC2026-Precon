# Lab 2 (10:20-11:10): The domain layer: making illegal states unrepresentable

**Type:** lecture (20 min) + sidebar (3 min) + lab (27 min). **Goal:** attendees implement a Ticket aggregate
with a real business rule, test-first, with the agent writing implementation to their failing
test. They see that the domain project needs no packages and the tests need no infrastructure.
Snapshot branch: `lab2-end`. Prerequisite (as on the handout): `lab1-end` state.

**Teaching beats:** factory methods returning `Result<T>`, invariants inside the aggregate,
domain events raised where the fact happens, and "the agent is dramatically better when the
test comes first."

## Minute-by-minute

| Time | Beat |
|------|------|
| 10:20 | Lecture: exceptions vs results, the Result type on one slide (8) |
| 10:28 | Sidebar: ".NET 11 is coming": C# union types vs our `Result<T>` (3) |
| 10:31 | Lecture: aggregates and invariants; live-code the Entity base + Ticket.Create (12) |
| 10:43 | Lab framing: the test-first loop with an agent (3) |
| 10:46 | Lab 2 solo: child tasks + the Close rule, test-first (17) |
| 11:03 | Debrief: diff review on screen + the zero-packages moment (7) |
| 11:10 | Hand off to Lab 3 |

## Files this session touches

Everything `lab1-end` -> `lab2-end` changes. "Content" says where the exact text lives. Bold
**manual path** citations mark content needed only by attendees not using an agent
(highlighted in red in the web version).

| File | Change | Content |
|------|--------|---------|
| `src/Helpdesk.SharedKernel/Result.cs` | new | below, lecture part 1 (same block in handout lab2, "The lecture code") |
| `src/Helpdesk.SharedKernel/Entity.cs` | new | below, lecture part 2 (same block in handout lab2, "The lecture code") |
| `src/Modules/Tickets/Helpdesk.Tickets.Domain/Ticket.cs` | new | below, lecture part 2, down to `Create` (includes `TicketErrors.NotFound`, which Lab 3 uses); the three lab methods are in handout lab2, **"Manual path / reference implementation"** (reprinted below, "Manual path reference"); the handout's "The lecture code" block is identical to this one and byte-exact with `lab2-end` before the three methods |
| `tests/Helpdesk.Tickets.Domain.Tests/TicketCloseTests.cs` | new | handout lab2, Step 1 (attendees write, model inline below); the other three tests reprinted below, Lab 2 Step 1 |
| `tests/Helpdesk.Tickets.Domain.Tests/PlaceholderTests.cs` | deleted | no content needed; `TicketCloseTests.cs` replaces it. Leaving it in place still compiles and passes, since `ModuleInfo` survives |

No project, solution, or package changes this session: the Domain project stays at zero
`PackageReference` entries, which is the debrief's whole point.

## Lecture part 1: errors are values (8 min)

Talking points:

- A business rule failing is not exceptional; it is Tuesday. Exceptions for control flow hide
  the rule from the signature, cost a stack unwind, and invite catch-all handlers.
- A `Result<T>` makes failure part of the contract: callers must look at it, and the compiler
  makes ignoring it awkward. The whole type is ~40 lines. Show it, then paste it into
  SharedKernel live (attendees copy from the handout):

**File: `src/Helpdesk.SharedKernel/Result.cs` (new file)**

```csharp
namespace Helpdesk.SharedKernel;

public sealed record Error(string Code, string Message)
{
    public static readonly Error None = new(string.Empty, string.Empty);
}

public class Result
{
    protected Result(bool isSuccess, Error error)
    {
        if (isSuccess && error != Error.None) throw new InvalidOperationException();
        if (!isSuccess && error == Error.None) throw new InvalidOperationException();
        IsSuccess = isSuccess;
        Error = error;
    }

    public bool IsSuccess { get; }
    public bool IsFailure => !IsSuccess;
    public Error Error { get; }

    public static Result Success() => new(true, Error.None);
    public static Result Failure(Error error) => new(false, error);
    public static Result<TValue> Success<TValue>(TValue value) => new(value, true, Error.None);
    public static Result<TValue> Failure<TValue>(Error error) => new(default, false, error);
}

public class Result<TValue> : Result
{
    private readonly TValue? _value;

    internal Result(TValue? value, bool isSuccess, Error error) : base(isSuccess, error)
        => _value = value;

    public TValue Value => IsSuccess
        ? _value!
        : throw new InvalidOperationException("Accessed Value on a failed result.");
}
```

- Point out the one deliberate exception left: accessing `Value` on a failure is a bug in the
  caller, and bugs SHOULD throw.

## Sidebar: ".NET 11 is coming" (3 min)

Slide only. Say the framing first: **shown, not built. Every lab today stays on .NET 10 LTS,
and nothing in this workshop depends on a preview.**

The one language feature worth naming is C# union types. A method that can return a ticket or
an error says so in the type system itself, and the compiler checks that the caller handled
both arms:

*Instructor only (not in the handout).*

**Slide excerpt (not a file in the repo; C# 15 syntax as shipped in .NET 11 Preview 2 and stable
in RC1, GA at .NET Conf, November 10-12, 2026):**

```csharp
// A closed set of case types, declared once.
public union TicketOutcome(Ticket, Error);

// Imagine Create returned TicketOutcome instead of Result<Ticket>.
// The caller cannot forget an arm: no default branch, the compiler checks every case.
var message = Ticket.Create(title) switch
{
    Ticket t => $"Created {t.Id}",
    Error e  => e.Message,
};
```

Three talking points, then move on:

- This is the same idea we just pasted. `Result<T>` is what "a ticket or an error" looks like
  when you express it with today's language: a class with a flag, a payload, and an error.
- What changes when unions ship: less ceremony, an exhaustive `switch` the compiler enforces,
  and no way to write the one bug we left in (reading `Value` off a failure).
- What does NOT change: failure stays a value in the signature, invariants stay inside the
  aggregate, and the pipeline still decides which status code a failure maps to. A language
  feature moves the ceremony, not the design decision.

What attendees read (handout lab2, "The lecture code", sidebar between `Result.cs` and
`Entity.cs`, word for word):

> **Sidebar: C# 15 unions.** In .NET 11 (RC1 now, GA at .NET Conf in November),
> `public union TicketOutcome(Ticket, Error);` lets a method say "a ticket or an error"
> in the type system itself, which is exactly what `Result<T>` expresses with today's language;
> the lecture puts the shape on a slide. Shown, not built: we stay on .NET 10 LTS all day, so
> nothing in this lab changes.

## Lecture part 2: aggregates and invariants (12 min)

Talking points while live-coding the base class and the start of `Ticket`:

- An aggregate is a consistency boundary: a cluster of objects that change together under one
  root, which is the only thing the outside may hold a reference to.
- Invariants live INSIDE the aggregate. If "a ticket with open child tasks cannot close" is
  checked in a service, it is checked in some services. If it is checked in `Ticket.Close`,
  it is checked, period.
- Private constructor + static factory returning `Result<Ticket>`: you cannot construct an
  invalid ticket, which is what "making illegal states unrepresentable" means in practice.
- Domain events are raised where the fact happens, collected on the entity, dispatched later
  (Lab 3 mentions the outbox; the take-home `main` branch has the full version).

SharedKernel additions:

**File: `src/Helpdesk.SharedKernel/Entity.cs` (new file)**

```csharp
namespace Helpdesk.SharedKernel;

public interface IDomainEvent
{
    DateTime OccurredOnUtc { get; }
}

public abstract class Entity
{
    private readonly List<IDomainEvent> _domainEvents = [];

    public IReadOnlyList<IDomainEvent> DomainEvents => _domainEvents;

    protected void Raise(IDomainEvent domainEvent) => _domainEvents.Add(domainEvent);

    public void ClearDomainEvents() => _domainEvents.Clear();
}
```

Moment: end of lecture part 2; the three lab methods are the manual path reference at the end of
this sheet.

Domain project, live-coded down to `Create` (the lab adds `AddChildTask`, `CompleteChildTask`
and `Close` after it):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Domain/Ticket.cs` (new file)** (as of end of lecture)

```csharp
using Helpdesk.SharedKernel;
using static Helpdesk.SharedKernel.Result;

namespace Helpdesk.Tickets.Domain;

public enum TicketStatus { Open, Closed }

public static class TicketErrors
{
    public static readonly Error EmptyTitle =
        new("Tickets.EmptyTitle", "A ticket needs a non-empty title.");
    public static readonly Error AlreadyClosed =
        new("Tickets.AlreadyClosed", "The ticket is already closed.");
    public static readonly Error OpenChildTasks =
        new("Tickets.OpenChildTasks", "Close all child tasks before closing the ticket.");
    public static readonly Error UnknownChildTask =
        new("Tickets.UnknownChildTask", "No such child task on this ticket.");
    public static readonly Error NotFound =
        new("Tickets.NotFound", "Ticket not found.");
}

public sealed record TicketCreated(Guid TicketId, DateTime OccurredOnUtc) : IDomainEvent;
public sealed record TicketClosed(Guid TicketId, DateTime OccurredOnUtc) : IDomainEvent;

public sealed class Ticket : Entity
{
    private readonly List<ChildTask> _childTasks = [];

    private Ticket() { }   // EF Core + nobody else

    public Guid Id { get; private set; }
    public string Title { get; private set; } = null!;
    public TicketStatus Status { get; private set; }
    public IReadOnlyList<ChildTask> ChildTasks => _childTasks;

    public static Result<Ticket> Create(string title)
    {
        if (string.IsNullOrWhiteSpace(title))
            return Failure<Ticket>(TicketErrors.EmptyTitle);

        var ticket = new Ticket
        {
            Id = Guid.NewGuid(),
            Title = title.Trim(),
            Status = TicketStatus.Open,
        };
        ticket.Raise(new TicketCreated(ticket.Id, DateTime.UtcNow));
        return Success(ticket);
    }
}

public sealed class ChildTask
{
    private ChildTask() { }

    internal ChildTask(Guid id, string description)
    {
        Id = id;
        Description = description;
    }

    public Guid Id { get; private set; }
    public string Description { get; private set; } = null!;
    public bool IsDone { get; private set; }

    internal void MarkDone() => IsDone = true;
}
```

(The `using static Helpdesk.SharedKernel.Result;` line is what lets `Create` call bare
`Failure<Ticket>(...)` / `Success(...)`; without it the build fails with CS0103. Fully
qualifying `Result.Failure<Ticket>` works too; pick one and say so.)

## Lab framing: the test-first loop with an agent (3 min)

The loop, on a slide, referenced all day:

1. **You** write a failing test that states the rule.
2. **Agent** makes it pass (and only that).
3. **You** review the diff like a reviewer, not a spectator.
4. Build + full test run verifies. Commit.

Why this ordering: the test pins the goalposts. An agent asked to "implement Close" invents
behavior; an agent asked to "make this failing test pass without changing the test" cannot.
Say the guardrail phrase out loud; it goes in every prompt: **"do not modify the tests."**

## Lab 2 (17 min, solo)

Task on the handout: finish the aggregate with three behaviors and this rule: **a ticket
cannot close while any child task is not done.**

### Step 1: write the tests yourself

Moment: Lab 2 Step 1, the model test the handout gives first; the other three follow it below.

Step 1: attendees first delete the Lab 1 `PlaceholderTests.cs` (the real tests replace it),
then write these tests THEMSELVES in `Helpdesk.Tickets.Domain.Tests`, file `TicketCloseTests.cs` (handout
shows the first as a model, they write the rest: the other three are
`Close_with_all_child_tasks_done_succeeds_and_raises_TicketClosed`, `Close_when_already_closed_fails`
and `Create_with_blank_title_fails`):

**File: `tests/Helpdesk.Tickets.Domain.Tests/TicketCloseTests.cs` (new file)**

```csharp
using Helpdesk.Tickets.Domain;

namespace Helpdesk.Tickets.Domain.Tests;

public class TicketCloseTests
{
    [Fact]
    public void Close_with_open_child_tasks_fails()
    {
        var ticket = Ticket.Create("Printer on fire").Value;
        ticket.AddChildTask("Extinguish printer");

        var result = ticket.Close();

        Assert.True(result.IsFailure);
        Assert.Equal(TicketErrors.OpenChildTasks, result.Error);
        Assert.Equal(TicketStatus.Open, ticket.Status);
    }
}
```

Moment: Lab 2 Step 1, the three attendee-written tests (compare after writing), added inside the
model file's class above.

The other three (write first, then compare). They go INSIDE the `TicketCloseTests` class,
before its closing `}`; pasted after the last `}` the file fails to compile for the wrong
reason (CS1519) and hides the red you want to see:

**File: `tests/Helpdesk.Tickets.Domain.Tests/TicketCloseTests.cs` (edit)**

```csharp
    [Fact]
    public void Close_with_all_child_tasks_done_succeeds_and_raises_TicketClosed()
    {
        var ticket = Ticket.Create("Printer on fire").Value;
        ticket.AddChildTask("Extinguish printer");
        ticket.CompleteChildTask(ticket.ChildTasks[0].Id);

        var result = ticket.Close();

        Assert.True(result.IsSuccess);
        Assert.Equal(TicketStatus.Closed, ticket.Status);
        Assert.Contains(ticket.DomainEvents, e => e is TicketClosed);
    }

    [Fact]
    public void Close_when_already_closed_fails()
    {
        var ticket = Ticket.Create("Printer on fire").Value;
        ticket.Close();

        var result = ticket.Close();

        Assert.True(result.IsFailure);
        Assert.Equal(TicketErrors.AlreadyClosed, result.Error);
    }

    [Fact]
    public void Create_with_blank_title_fails()
    {
        var result = Ticket.Create("   ");

        Assert.True(result.IsFailure);
        Assert.Equal(TicketErrors.EmptyTitle, result.Error);
    }
```

Then the red run (handout, end of Step 1): `dotnet test Helpdesk.slnx` must FAIL with
`error CS1061: 'Ticket' does not contain a definition for 'AddChildTask'` (and for
`CompleteChildTask` and `Close`). The `Passed!` line for Helpdesk.ArchitectureTests is the
other test project, not theirs. The fourth test guards the lecture's `Create` and goes green as
soon as the file compiles; the other three are the red ones.

Once they have seen the red run, they commit (handout lab2, end of Step 1, word for word):

Commit the red tests (and the lecture code) now, so Step 3 can check with `git diff --stat HEAD`
that the agent touched only `Ticket.cs`:

```bash
git add -A && git commit -m "Close-rule tests (red)"
```

### Step 2, AI path: the prompt

What attendees do (handout lab2, "Step 2, AI path: the prompt", word for word):

> Run the tests in Helpdesk.Tickets.Domain.Tests and make the failing ones pass by
> implementing AddChildTask, CompleteChildTask, and Close on the Ticket aggregate, following
> the conventions in CLAUDE.md. Keep exactly these signatures and rules: public Result
> AddChildTask(string description) fails with TicketErrors.AlreadyClosed on a closed ticket;
> public Result CompleteChildTask(Guid taskId) fails with TicketErrors.UnknownChildTask for an
> id the ticket does not have; public Result Close() fails with TicketErrors.AlreadyClosed or
> TicketErrors.OpenChildTasks. Use only the errors already defined in TicketErrors and add no
> other rule. Do not modify the tests. Do not touch any project other than
> Helpdesk.Tickets.Domain.

What attendees read next (handout lab2, word for word):

Your agent's code will not be character-for-character the reference at the end of this page,
and that is fine: `Find` instead of `FirstOrDefault`, or `Exists` instead of `Any`, is style.
What must match is the contract the prompt pins: the three signatures, the existing
`TicketErrors`, and no extra rules. If your agent returns `Result<ChildTask>`, adds a new error
code, or invents a rule (say, rejecting an empty description), reject the diff and point it at
the prompt's "Keep exactly these signatures and rules" sentence.

What the agent should produce: one changed file, `Helpdesk.Tickets.Domain/Ticket.cs` (about 30
added lines: `AddChildTask`, `CompleteChildTask`, `Close`), tests untouched, `Passed: 4`. Proven
2026-10-07 with this pinned prompt: two headless runs matched the reference's signatures, error
codes and rules exactly; the only differences were `Find`/`Exists` for `FirstOrDefault`/`Any`.

Why the prompt pins the contract (say it if someone asks why it is so long): with the shorter
prompt ("implement ... do not modify the tests"), rehearsals came back with `Result<ChildTask>`
from `AddChildTask`, a new `EmptyChildTaskDescription` error, a closed-ticket guard on
`CompleteChildTask`, and description trimming. All of that compiled and passed the four tests,
which is the lesson: a test pins what it asserts and nothing more, so anything you care about
that no test asserts has to be in the spec. Same reason Lab 3a's prompt pins its error codes and
response body.

### Step 2, manual path (no agent)

What attendees do (handout lab2, "Step 2, manual path (no agent)", word for word):

Write `AddChildTask`, `CompleteChildTask` and `Close` yourself, inside `Ticket` after `Create`,
and run `dotnet test Helpdesk.slnx` until all four tests in Helpdesk.Tickets.Domain.Tests pass.
Try it from the tests first; if you are stuck, the reference implementation is the last section
of this page, after Step 4:
[Manual path / reference implementation](#reference-implementation). Step 3's review questions
apply to your own diff too.

Coach: the reference block is printed at the end of this run sheet under "Manual path
reference" (the link above jumps there too). Say out loud where it is: an attendee on the
2026-10-07 run read Step 2 and missed it, because it sits after Step 4; `Failure` / `Success` come from the `using static Helpdesk.SharedKernel.Result;` line
the lecture code already has. Before this step existed, a literal manual-path attendee committed
code that did not compile (re-run 2026-10-07): make sure nobody reaches Step 4 red.

### Step 3: review the diff

Checklist on the handout:

- Did every method return `Result`/`Result<T>` (no thrown business exceptions)?
- Is `TicketClosed` raised inside `Close`, only on success?
- Did it leak anything public that should be internal (`ChildTask.MarkDone`)?
- Did it touch only the Domain project?

The handout's fifth item, word for word: "Did it touch the tests? (`git diff --stat HEAD` should
list only `Ticket.cs`. If a test file shows up: revert, tighten the prompt, rerun. Tell the
instructor; you just met, in person, the S9 field-report story about the test that passes
because it changed.)" The Step 1 commit is what makes that one command enough.

### Step 4: verify, commit (both paths)

`dotnet test Helpdesk.slnx`, commit.

```bash
dotnet test Helpdesk.slnx
git add -A && git commit -m "Ticket aggregate with close rule"
```

## Debrief (7 min, on screen)

- Show a good diff and, if you saw one while floating, an over-eager diff (extra helper class,
  modified test). Naming the failure modes now sets up the candor material in S9.
- The zero-packages moment, on screen (it prints `0`):
  *Instructor only (not in the handout).*

```bash
grep -c PackageReference src/Modules/Tickets/Helpdesk.Tickets.Domain/*.csproj
```

  In PowerShell: `(Select-String PackageReference src/Modules/Tickets/Helpdesk.Tickets.Domain/*.csproj).Count   # 0`

  "The most important project in the system has no package dependencies and one project
  reference, the shared kernel, and its tests run in milliseconds with no database. That is not an accident; this afternoon we make it a rule the
  build enforces."
- Hand off to Lab 3 at 11:10, straight on: "Next these domain calls get an entrance: commands,
  queries, and a pipeline that gives every one of them validation and logging for free. Then we
  break for lunch."

## If things go wrong

- Attendees stuck writing tests: the handout's model test is copy-adaptable; floating TA
  nudges, never types.
- Agent modifies the test to make it pass: celebrate loudly (best possible teachable moment),
  revert, tighten the prompt, re-run. This exact story returns in the S9 field report.
- Behind schedule: cut the fourth test (blank title) and the bad-diff show-and-tell; never cut
  the zero-packages moment.

<a id="reference-implementation"></a>

## Manual path reference (what attendees without an agent paste)

The handout's "Manual path / reference implementation" section: the manual path's fallback at
Step 2, and for AI-path attendees a peek after committing.

Moment: Lab 2 manual path, the three methods added to the lecture-part-2 `Ticket.cs` above.

Add inside `Ticket`, after `Create`:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Domain/Ticket.cs` (edit)**

```csharp
    public Result AddChildTask(string description)
    {
        if (Status == TicketStatus.Closed)
            return Failure(TicketErrors.AlreadyClosed);

        _childTasks.Add(new ChildTask(Guid.NewGuid(), description));
        return Success();
    }

    public Result CompleteChildTask(Guid taskId)
    {
        var task = _childTasks.FirstOrDefault(t => t.Id == taskId);
        if (task is null)
            return Failure(TicketErrors.UnknownChildTask);

        task.MarkDone();
        return Success();
    }

    public Result Close()
    {
        if (Status == TicketStatus.Closed)
            return Failure(TicketErrors.AlreadyClosed);

        if (_childTasks.Any(t => !t.IsDone))
            return Failure(TicketErrors.OpenChildTasks);

        Status = TicketStatus.Closed;
        Raise(new TicketClosed(Id, DateTime.UtcNow));
        return Success();
    }
```

(`Failure` / `Success` via `using static Helpdesk.SharedKernel.Result;` at the top of the
file, matching the lecture code.)
