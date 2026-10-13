# Lab 2 Handout: The Ticket aggregate, test-first (10:20-11:10)

Snapshot branch if you get stuck: `lab2-end`
Prerequisite: `lab1-end` state.

**Starting from the snapshot instead of your own work?** Clone it into a new folder and make
it your `main` (a plain `git checkout lab1-end` leaves your next commits on a branch named
`lab1-end`):

```sh
git clone --branch lab1-end https://github.com/ivanball/adc2026-helpdesk.git helpdesk-lab2
cd helpdesk-lab2
git switch -c main --track origin/lab1-end
```

## The lecture code (paste along during the lecture)

The lecture pastes these three files. Paste each one when the lecture does; if you fell
behind, create the missing ones before Step 1, because the tests need them to compile.

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

> **Sidebar: C# 15 unions.** In .NET 11 (RC1 now, GA at .NET Conf in November),
> `public union TicketOutcome(Ticket, Error);` lets a method say "a ticket or an error"
> in the type system itself, which is exactly what `Result<T>` expresses with today's language;
> the lecture puts the shape on a slide. Shown, not built: we stay on .NET 10 LTS all day, so
> nothing in this lab changes.

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

## The lab

**Goal:** finish the aggregate with three behaviors and this rule: **a ticket cannot close
while any child task is not done.** You write the failing tests; the agent makes them pass;
you review the diff.

## The loop

1. YOU write a failing test that states the rule.
2. AGENT makes it pass (and only that).
3. YOU review the diff like a reviewer, not a spectator.
4. Build + full test run verifies. Commit.

## Step 1: write the tests yourself

In `tests/Helpdesk.Tickets.Domain.Tests`, delete the Lab 1 `PlaceholderTests.cs` (the real
tests replace it) and create `TicketCloseTests.cs`. The first test is given as a model; write
the other three yourself before peeking at the versions below.

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

Run `dotnet test Helpdesk.slnx` and confirm it FAILS: you should see `error CS1061: 'Ticket'
does not contain a definition for 'AddChildTask'` (and for `CompleteChildTask` and `Close`).
The `Passed!` line for Helpdesk.ArchitectureTests is the other test project, not yours. A test
you have never seen fail proves nothing. (The fourth test guards the lecture's `Create`; it goes
green as soon as the file compiles. The other three are the red ones.)

Commit the red tests (and the lecture code) now, so Step 3 can check with `git diff --stat HEAD`
that the agent touched only `Ticket.cs`:

```bash
git add -A && git commit -m "Close-rule tests (red)"
```

## Step 2, AI path: the prompt

> Run the tests in Helpdesk.Tickets.Domain.Tests and make the failing ones pass by
> implementing AddChildTask, CompleteChildTask, and Close on the Ticket aggregate, following
> the conventions in CLAUDE.md. Keep exactly these signatures and rules: public Result
> AddChildTask(string description) fails with TicketErrors.AlreadyClosed on a closed ticket;
> public Result CompleteChildTask(Guid taskId) fails with TicketErrors.UnknownChildTask for an
> id the ticket does not have; public Result Close() fails with TicketErrors.AlreadyClosed or
> TicketErrors.OpenChildTasks. Use only the errors already defined in TicketErrors and add no
> other rule. Do not modify the tests. Do not touch any project other than
> Helpdesk.Tickets.Domain.

Your agent's code will not be character-for-character the reference at the end of this page,
and that is fine: `Find` instead of `FirstOrDefault`, or `Exists` instead of `Any`, is style.
What must match is the contract the prompt pins: the three signatures, the existing
`TicketErrors`, and no extra rules. If your agent returns `Result<ChildTask>`, adds a new error
code, or invents a rule (say, rejecting an empty description), reject the diff and point it at
the prompt's "Keep exactly these signatures and rules" sentence.

## Step 2, manual path (no agent)

Write `AddChildTask`, `CompleteChildTask` and `Close` yourself, inside `Ticket` after `Create`,
and run `dotnet test Helpdesk.slnx` until all four tests in Helpdesk.Tickets.Domain.Tests pass.
Try it from the tests first; if you are stuck, the reference implementation is the last section
of this page, after Step 4:
[Manual path / reference implementation](#reference-implementation). Step 3's review questions
apply to your own diff too.

## Step 3: review the diff

- Does every method return `Result` / `Result<T>` (no thrown business exceptions)?
- Is `TicketClosed` raised inside `Close`, only on success?
- Did anything become public that should be internal (`ChildTask.MarkDone`)?
- Did it touch only the Domain project?
- Did it touch the tests? (`git diff --stat HEAD` should list only `Ticket.cs`. If a test file
  shows up: revert, tighten the prompt, rerun. Tell the instructor; you just met, in person,
  the S9 field-report story about the test that passes because it changed.)

## Step 4: verify, commit

```bash
dotnet test Helpdesk.slnx
git add -A && git commit -m "Ticket aggregate with close rule"
```

<a id="reference-implementation"></a>

## Manual path / reference implementation (manual path: your fallback at Step 2; AI path: peek AFTER committing)

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
