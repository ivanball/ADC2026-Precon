# Lab 3 (11:10-12:05): CQRS by hand, and the decorator pipeline

**Type:** lecture (15 min) + live-code (12 min) + lab (23 min) + outbox mention (5 min).
**Goal:** attendees own a complete CQRS pipeline with zero frameworks (two handler interfaces,
three decorators, one registration class), then ship three vertical slices: the first driven by a
`/slice` Agent Skill, the second test-first at the API level, with the agent writing an
integration test against the SQL container BEFORE the code. Payoff line: "the close slice took
minutes, not an afternoon, and you read every line of the machinery forty minutes ago." Snapshot branch:
`lab3-end`.

**You need:** the persistence plumbing pre-written for pasting (DbContext, repository,
migration steps); the lab burns down if attendees hand-type EF configuration. Also the SQL
container up (`docker compose up -d`) before the 11:30 plumbing paste: `dotnet ef database
update`, the 3a curl and the 3b API tests all need it.

**This block runs straight into lunch at 12:05.** It is the last block of the morning, so
overrun costs the room its break, not a later session: the outbox mention is the part to cut.

## Minute-by-minute

| Time | Beat |
|------|------|
| 11:10 | Lecture: commands vs queries; why not a mediator library (8) |
| 11:18 | Live-code: the two interfaces, three decorators, registration extension, SOLID recap slide (12) |
| 11:30 | Together on screen: persistence plumbing + first endpoint wired (7) |
| 11:37 | Lab 3a solo: CreateTicket slice through the `/slice` skill (10) |
| 11:47 | Lab 3b solo: test-first at the API level, then CloseTicket + the GetTicketById read-back (10) |
| 11:57 | Debrief + payoff line (3) |
| 12:00 | Two event paths: the outbox in five minutes (5) |
| 12:05 | Lunch |

(Lecture 15 = the 8-minute CQRS lecture plus the 7-minute plumbing paste; the 3b block is 13
minutes with its debrief.)

## Files this session touches

`lab2-end` -> `lab3-end`. "Handout lab3" is `handouts/lab3.md`; its paste sections are lettered
A to D. Bold **manual path** citations mark content needed only by attendees not using an
agent (highlighted in red in the web version); on the AI path the agent writes those files
from the lab prompts.

| File | Change | Content |
|------|--------|---------|
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/Messaging.cs` | new file | below + handout lab3, paste section A |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/Decorators.cs` | new file | below + handout lab3, paste section A |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/HandlerRegistration.cs` | new file | below + handout lab3, paste section A |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/Persistence.cs` | new file | below + handout lab3, paste section A |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/TicketsApplication.cs` | new file, then edits | handout lab3, paste section A (placeholder) + **manual path** edits in Lab 3a and 3b Step 5 (all reprinted below) |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CreateTicket.cs` | new file | handout lab3, "Lab 3a, **manual path**" (reprinted below, "Lab 3a, manual path") |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CloseTicket.cs` | new file | handout lab3, "Step 5, **manual path**" (reprinted below, "Lab 3b Step 5, manual path") |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/GetTicketById.cs` | new file | handout lab3, "Step 5, **manual path**" (required in 3b: the API test reads back through it) (reprinted below, "Lab 3b Step 5, manual path") |
| `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/TicketsDbContext.cs` | new file | handout lab3, paste section B (reprinted below) |
| `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/TicketRepository.cs` | new file | handout lab3, paste section B (reprinted below) |
| `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/TicketsModule.cs` | new file | handout lab3, paste section B (reprinted below) |
| `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` | new file, then edits | handout lab3, paste section C (placeholder) + **manual path** edits in Lab 3a and 3b Step 5 (all reprinted below) |
| `src/Helpdesk.Host/Program.cs` | edit, then append | handout lab3, paste section C; the `public partial class Program { }` append is in Lab 3b below (section C edit reprinted below, plumbing beat) |
| `src/Helpdesk.Host/appsettings.json` | edit | handout lab3, paste section C (connection string block) (reprinted below) |
| `.claude/skills/slice/SKILL.md` | new file | below, Lab 3a (also in handout lab3, "Lab 3a, AI path") |
| `tests/Helpdesk.ApiTests/Helpdesk.ApiTests.csproj` | new file | below, Lab 3b + handout lab3 |
| `tests/Helpdesk.ApiTests/HelpdeskApiFactory.cs` | new file | below, Lab 3b + handout lab3 |
| `tests/Helpdesk.ApiTests/CloseTicketTests.cs` | new file | below, Lab 3b + handout lab3 (attendees ask the agent for it, or paste it) |
| `CLAUDE.md` and `AGENTS.md` | edit | one identical line each, Lab 3b below (the test command gains the container note) |
| `Helpdesk.slnx` | edit | generated: `dotnet sln add tests/Helpdesk.ApiTests` |
| `src/Modules/Tickets/Helpdesk.Tickets.Application/Helpdesk.Tickets.Application.csproj` | edit | created by `dotnet add package` (command block below) |
| `src/Helpdesk.Host/Helpdesk.Host.csproj` | edit | created by `dotnet add package` (command block below) |
| `dotnet-tools.json` | new file | generated: `dotnet new tool-manifest` + `dotnet tool install dotnet-ef` (only if they use the local tool instead of the global one) |
| `src/Helpdesk.Host/Properties/launchSettings.json` | edit | handout lab3, paste section C (whole file: one `http` profile pinned to port 5000, which Labs 6 and 7 hard-code) (reprinted below, plumbing beat) |
| `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/Migrations/*_Initial.cs` (+ Designer + model snapshot) | generated | generated: `dotnet ef migrations add Initial` (handout lab3, paste section D) |

That is the whole of `git diff --stat lab2-end lab3-end`: 28 files, 768 insertions, 14
deletions.

Test count on `lab3-end`: 7 green (Domain 4, Architecture 1, the Lab 1 placeholder that Lab 4
deletes, Api 2). Eight means the template's `UnitTest1.cs` survived 3b Step 1.

## Lecture: CQRS without the cargo cult (8 min)

Talking points:

- CQRS at this scale means one thing: a write path (commands mutate an aggregate through its
  factory/behavior methods) and a read path (queries return a response shape, never the
  aggregate; at scale they project straight from the database, and today's GetTicketById
  reuses the repository for brevity). Not event sourcing, not separate databases; just two
  shapes of request.
- Why a pipeline at all: validation, logging, and later caching/metrics are per-request
  concerns. Without a pipeline they get pasted into every handler and drift.
- Why not a mediator library: nothing wrong with them, but today's point is that the whole
  mechanism is about 110 lines you can own, read, and debug. When you understand these lines,
  every mediator library becomes obvious; the reverse is not true.

## Live-code: the machinery (12 min)

All of this goes in `Helpdesk.Tickets.Application` (Abstractions folder). Attendees paste from
the handout as you narrate.

FIRST, the packages, or the decorators will not compile (CS0234/CS0246 on
`Microsoft.Extensions.Logging`). Same block as the top of the handout's paste section A:

```bash
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Application package Microsoft.Extensions.DependencyInjection.Abstractions
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Application package Microsoft.Extensions.Logging.Abstractions
dotnet add src/Helpdesk.Host package Microsoft.EntityFrameworkCore.Design
```

The Application layer takes only the two `.Abstractions` packages (interfaces, no
implementations); say so out loud, since "Domain has zero packages, Application has only
abstractions" is the dependency story of the day.

The interfaces:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/Messaging.cs` (new file)**

```csharp
using Helpdesk.SharedKernel;

namespace Helpdesk.Tickets.Application.Abstractions;

public interface ICommand<TResponse> { }
public interface IQuery<TResponse> { }

public interface ICommandHandler<in TCommand, TResponse>
    where TCommand : ICommand<TResponse>
{
    Task<Result<TResponse>> Handle(TCommand command, CancellationToken ct);
}

public interface IQueryHandler<in TQuery, TResponse>
    where TQuery : IQuery<TResponse>
{
    Task<Result<TResponse>> Handle(TQuery query, CancellationToken ct);
}

public interface IValidator<in T>
{
    IReadOnlyList<Error> Validate(T instance);
}
```

The decorators (narrate: "a decorator implements the same interface it wraps; the endpoint
never knows"):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/Decorators.cs` (new file)**

```csharp
using System.Diagnostics;
using Helpdesk.SharedKernel;
using Microsoft.Extensions.Logging;

namespace Helpdesk.Tickets.Application.Abstractions;

internal sealed class ValidationCommandDecorator<TCommand, TResponse>(
    ICommandHandler<TCommand, TResponse> inner,
    IEnumerable<IValidator<TCommand>> validators)
    : ICommandHandler<TCommand, TResponse>
    where TCommand : ICommand<TResponse>
{
    public Task<Result<TResponse>> Handle(TCommand command, CancellationToken ct)
    {
        var errors = validators.SelectMany(v => v.Validate(command)).ToList();
        return errors.Count > 0
            ? Task.FromResult(Result.Failure<TResponse>(errors[0]))
            : inner.Handle(command, ct);
    }
}

internal sealed class LoggingCommandDecorator<TCommand, TResponse>(
    ICommandHandler<TCommand, TResponse> inner,
    ILogger<LoggingCommandDecorator<TCommand, TResponse>> logger)
    : ICommandHandler<TCommand, TResponse>
    where TCommand : ICommand<TResponse>
{
    public async Task<Result<TResponse>> Handle(TCommand command, CancellationToken ct)
    {
        var name = typeof(TCommand).Name;
        var stopwatch = Stopwatch.StartNew();
        var result = await inner.Handle(command, ct);
        if (result.IsSuccess)
            logger.LogInformation("{Command} handled in {Ms}ms", name, stopwatch.ElapsedMilliseconds);
        else
            logger.LogWarning("{Command} failed: {Error} ({Ms}ms)",
                name, result.Error.Code, stopwatch.ElapsedMilliseconds);
        return result;
    }
}

internal sealed class LoggingQueryDecorator<TQuery, TResponse>(
    IQueryHandler<TQuery, TResponse> inner,
    ILogger<LoggingQueryDecorator<TQuery, TResponse>> logger)
    : IQueryHandler<TQuery, TResponse>
    where TQuery : IQuery<TResponse>
{
    public async Task<Result<TResponse>> Handle(TQuery query, CancellationToken ct)
    {
        var stopwatch = Stopwatch.StartNew();
        var result = await inner.Handle(query, ct);
        logger.LogInformation("{Query} handled in {Ms}ms",
            typeof(TQuery).Name, stopwatch.ElapsedMilliseconds);
        return result;
    }
}
```

The registration extension (the promised "dozen lines of DI"; queries get a mirror method
without the validation wrap, and the third decorator above logs them):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/HandlerRegistration.cs` (new file)**

```csharp
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Helpdesk.Tickets.Application.Abstractions;

public static class HandlerRegistration
{
    public static IServiceCollection AddCommandHandler<TCommand, TResponse, THandler>(
        this IServiceCollection services)
        where TCommand : ICommand<TResponse>
        where THandler : class, ICommandHandler<TCommand, TResponse>
    {
        services.AddScoped<THandler>();
        services.AddScoped<ICommandHandler<TCommand, TResponse>>(sp =>
            new LoggingCommandDecorator<TCommand, TResponse>(
                new ValidationCommandDecorator<TCommand, TResponse>(
                    sp.GetRequiredService<THandler>(),
                    sp.GetServices<IValidator<TCommand>>()),
                sp.GetRequiredService<ILogger<LoggingCommandDecorator<TCommand, TResponse>>>()));
        return services;
    }

    public static IServiceCollection AddQueryHandler<TQuery, TResponse, THandler>(
        this IServiceCollection services)
        where TQuery : IQuery<TResponse>
        where THandler : class, IQueryHandler<TQuery, TResponse>
    {
        services.AddScoped<THandler>();
        services.AddScoped<IQueryHandler<TQuery, TResponse>>(sp =>
            new LoggingQueryDecorator<TQuery, TResponse>(
                sp.GetRequiredService<THandler>(),
                sp.GetRequiredService<ILogger<LoggingQueryDecorator<TQuery, TResponse>>>()));
        return services;
    }
}
```

Whiteboard the onion: endpoint -> Logging -> Validation -> Handler. "Caching, metrics,
authorization: each is one more ring, registered in one place." (Stretch topic pointer.)

Then one minute on the "SOLID, in the code you just wrote" slide: one row per principle, each
pointing at code already on screen. The payoff line: nobody set out to write SOLID, the shape
produced it, and that shape is what the agent copies on every slice. D (endpoints depend on
`ICommandHandler`) is the row Lab 5's red pull request breaks.

## Together: persistence plumbing (7 min, paste-heavy)

Narrate fast, paste from handout; understanding EF config is not today's goal.

Application abstractions:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Abstractions/Persistence.cs` (new file)**

```csharp
using Helpdesk.Tickets.Domain;

namespace Helpdesk.Tickets.Application.Abstractions;

public interface ITicketRepository
{
    void Add(Ticket ticket);
    Task<Ticket?> GetById(Guid id, CancellationToken ct);   // child tasks load automatically (owned collection)
}

public interface IUnitOfWork
{
    Task SaveChangesAsync(CancellationToken ct);
}
```

Moment: the empty section A placeholder; the Lab 3a and 3b Step 5 manual-path blocks below add
its registration lines. `.../TicketsApplication.cs` (handlers are internal, so they register inside
their own assembly; each slice adds one line here):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/TicketsApplication.cs` (new file)**

```csharp
using Helpdesk.Tickets.Application.Abstractions;
using Microsoft.Extensions.DependencyInjection;

namespace Helpdesk.Tickets.Application;

public static class TicketsApplication
{
    public static IServiceCollection AddTicketsApplication(this IServiceCollection services)
    {
        // Slices register here as they are added, e.g.:
        // services.AddCommandHandler<CreateTicket, Guid, CreateTicketHandler>();
        // services.AddScoped<IValidator<CreateTicket>, CreateTicketValidator>();
        return services;
    }
}
```

Infrastructure: `TicketsDbContext` (owns `Tickets` DbSet, maps `ChildTask` as an owned
collection, implements `IUnitOfWork`), `TicketRepository`, and a `TicketsModuleRegistration`
(file `TicketsModule.cs`, method `AddTicketsModule`) that registers context + repository +
handlers. Connection string database: `HelpdeskTickets`
(per-module database; say it out loud, it pays off in the extraction clip at the wrap).

The file contents are the handout's **paste sections B and C** (`handouts/lab3.md`), reprinted
below: B = `TicketsDbContext.cs` + `TicketRepository.cs` + `TicketsModule.cs`,
C = `TicketEndpoints.cs` + the `Program.cs` and `appsettings.json` edits. Paste them now, or
the migration below fails with "No DbContext was found in assembly".

Handout paste section B (infrastructure):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/TicketsDbContext.cs` (new file)**

```csharp
using Helpdesk.SharedKernel;
using Helpdesk.Tickets.Application.Abstractions;
using Helpdesk.Tickets.Domain;
using Microsoft.EntityFrameworkCore;

namespace Helpdesk.Tickets.Infrastructure;

public sealed class TicketsDbContext(DbContextOptions<TicketsDbContext> options)
    : DbContext(options), IUnitOfWork
{
    public DbSet<Ticket> Tickets => Set<Ticket>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Ticket>(builder =>
        {
            builder.HasKey(t => t.Id);
            builder.Property(t => t.Title).HasMaxLength(200);
            builder.Ignore(t => t.DomainEvents);
            builder.OwnsMany(t => t.ChildTasks, child =>
            {
                child.ToTable("ChildTasks");
                child.WithOwner().HasForeignKey("TicketId");
                child.HasKey(c => c.Id);
                child.Property(c => c.Description).HasMaxLength(500);
            });
        });
    }

    Task IUnitOfWork.SaveChangesAsync(CancellationToken ct) => SaveChangesAsync(ct);
}
```

**File: `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/TicketRepository.cs` (new file)**

```csharp
using Helpdesk.Tickets.Application.Abstractions;
using Helpdesk.Tickets.Domain;
using Microsoft.EntityFrameworkCore;

namespace Helpdesk.Tickets.Infrastructure;

internal sealed class TicketRepository(TicketsDbContext db) : ITicketRepository
{
    public void Add(Ticket ticket) => db.Tickets.Add(ticket);

    public Task<Ticket?> GetById(Guid id, CancellationToken ct) =>
        db.Tickets.FirstOrDefaultAsync(t => t.Id == id, ct);
}
```

`.../TicketsModule.cs` (module registration; the `main` branch evolves this into IModule for
the recorded extraction clip):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/TicketsModule.cs` (new file)**

```csharp
using Helpdesk.Tickets.Application;
using Helpdesk.Tickets.Application.Abstractions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Helpdesk.Tickets.Infrastructure;

public static class TicketsModuleRegistration
{
    public static IServiceCollection AddTicketsModule(
        this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<TicketsDbContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("Tickets")));
        services.AddScoped<IUnitOfWork>(sp => sp.GetRequiredService<TicketsDbContext>());
        services.AddScoped<ITicketRepository, TicketRepository>();
        services.AddTicketsApplication();
        return services;
    }
}
```

Handout paste section C (presentation + host):

Moment: the plumbing beat's empty placeholder; the Lab 3a and 3b Step 5 manual-path blocks
below add its endpoints.

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` (new file)**

```csharp
using Helpdesk.Tickets.Application.Abstractions;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace Helpdesk.Tickets.Presentation;

public static class TicketEndpoints
{
    public static IEndpointRouteBuilder MapTicketEndpoints(this IEndpointRouteBuilder app)
    {
        // Slices add endpoints here.
        return app;
    }
}
```

Moment: the plumbing beat's host wiring (module + endpoints); the Lab 3b `Program.cs` block
further down is a later append to this same file.

**File: `src/Helpdesk.Host/Program.cs` (edit)**

```csharp
using Helpdesk.Tickets.Infrastructure;
using Helpdesk.Tickets.Presentation;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddTicketsModule(builder.Configuration);

var app = builder.Build();
app.MapGet("/health", () => "OK");
app.MapTicketEndpoints();
app.Run();
```

Then the `appsettings.json` edit. The whole file after the edit (the new
part is the `ConnectionStrings` block; note the comma after `"AllowedHosts": "*"`):

**File: `src/Helpdesk.Host/appsettings.json` (edit)**

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "Tickets": "Server=localhost,14330;Database=HelpdeskTickets;User Id=sa;Password=Workshop!Passw0rd;TrustServerCertificate=True"
  }
}
```

Last, the launch profile, and say why out loud: the workshop pins the API to port 5000, so
every curl, `.http` file and MCP client config later in the day (Labs 6 and 7 hard-code 5000)
works as printed. Attendees replace the whole generated file (random port plus an `https`
profile) with this one:

**File: `src/Helpdesk.Host/Properties/launchSettings.json` (edit)**

```json
{
  "$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

Host `Program.cs` wires the module and maps endpoints; then together:

```bash
docker compose up -d
dotnet build Helpdesk.slnx
dotnet ef migrations add Initial -p src/Modules/Tickets/Helpdesk.Tickets.Infrastructure -s src/Helpdesk.Host
dotnet ef database update -p src/Modules/Tickets/Helpdesk.Tickets.Infrastructure -s src/Helpdesk.Host
```

The compose line is a no-op for anyone whose container has been up since Lab 1; `database
update` needs it. The build is for the catch-up attendee on a fresh `lab2-end` clone: `dotnet
ef` reads the restored project assets, and on a never-built clone it stops with `NETSDK1004`
(assets file `project.assets.json` not found).

At a table (the handout carries this line): `database update` failing with "...an error
occurred during the pre-login handshake" means SQL Server is still starting, up to about 20 s
after `docker compose up -d` and longest on Apple Silicon under emulation (the 2026-10-12 Mac
dry run hit it on a cold container). Wait and rerun only the update; rerunning
`migrations add` stops with "The name 'Initial' is used by an existing migration".

At a table (the handout carries this line): no `dotnet ef`? `dotnet tool install --global
dotnet-ef`. Still "command not found" on a Mac after the install: zsh lacks the tools folder
on its PATH, so `echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile` and a new
terminal; on Windows, a new Git Bash window. A warning that the Entity Framework tools version is older than the runtime is
harmless.

Commit the pasted machinery and the migration now, so each slice below lands as its own small
diff:

```bash
git add -A && git commit -m "Command pipeline and persistence"
```

## Lab 3a: first slice, through the `/slice` skill (10 min)

The slice: `POST /tickets` creating a ticket. Attendees do not paste a long prompt for this
one; they invoke a skill the repo ships.

### Lab 3a, AI path: the `/slice` skill

What attendees do (handout lab3, "Lab 3a, AI path: the `/slice` skill", then "Lab 3a, manual
path (no agent)" and "Lab 3a: diff review and verify (both paths)", word for word; the SKILL.md
file block, the `/slice` text, the fallback prompt, the manual-path blocks and the curls are each
printed once below, where they happen):

The repo ships a skill. The frontmatter `description` is the trigger the agent matches against
what you ask for; the body is the procedure, and it only loads once the skill fires. The same
SKILL.md format works in GitHub Copilot (which also reads `.claude/skills`) and OpenAI Codex
(which reads only `.agents/skills`, so copy the folder there for Codex), so the procedure is
written once for the team, reviewed in a pull request, and versioned like any other file.

[file block `.claude/skills/slice/SKILL.md`, printed next]

Invoke it (if `/slice` is not offered, check that `.claude/skills/slice/SKILL.md` is present in
the repo folder you opened; skills are discovered per repo):

[the `/slice add a CreateTicket command ...` text, printed below under "Then the attendee types"]

If the agent asks whether to create `tests/Helpdesk.ApiTests` for an API test, answer "not
yet, 3b creates it": that project does not exist until 3b.

If your agent does not support skills, or `/slice` does not fire, use the same instructions as
a prompt:

[the "Add a complete vertical slice for creating a ticket" prompt, printed below]

Lab 3a, manual path (no agent): [`CreateTicket.cs`, the two registration lines and the
`POST /tickets` endpoint, each with its `using` instruction first, printed below under "Lab 3a,
manual path"]

Lab 3a: diff review and verify (both paths):

**Diff review:** is the handler thin (create via domain, add, save)? Did business logic leak
into the endpoint or the validator? Validators check input shape; the domain owns the rules.

**Verify.** Start the host in its own terminal and leave it running:

[the `dotnet run --project src/Helpdesk.Host` block, printed below at the top of "Lab 3a verify (both paths)"]

Wait for `Now listening on: http://localhost:5000`, then send the two calls from a second
terminal:

[the two curls, printed below under "Lab 3a verify (both paths)"]

(`-i` prints the status line, such as `HTTP/1.1 201 Created`, above the body. No output, or
`curl: (7) Failed to connect`, means the host is not running on 5000; start it and retry.
Port: 5000, pinned by the `launchSettings.json` edit in paste section C; any other port in
the `Now listening on` line means that edit was skipped. macOS: `address already in use` for
port 5000 at startup, or a `403 Forbidden` from a server called `AirTunes`, is AirPlay Receiver
holding 5000; switch it off (System Settings > General > AirDrop & Handoff) and restart the
host. Windows: run these from Git Bash as printed; in cmd.exe escape the inner quotes,
`-d "{\"title\":\"Printer on fire\"}"`; in PowerShell call `curl.exe` explicitly. A
JsonException complaining that `'` is an invalid start of a value means the shell passed the
single quotes through; it is not a code bug.)

First call: 201 with `{"id":"..."}`. Second call: 400 with `Tickets.Validation.EmptyTitle`.
Console: the logging decorator line for both. Then stop the host with Ctrl+C: a running host
locks its build output on Windows, and the 3b build fails on it.

[the "CreateTicket slice" commit block, printed below at the end of "Lab 3a verify (both paths)"]

What the agent should produce: one new file `Application/Tickets/CreateTicket.cs` (command,
thin handler `Ticket.Create` -> `tickets.Add` -> `SaveChangesAsync`, shape-only validator), its
registration in `TicketsApplication.cs` and `POST /tickets` in `TicketEndpoints.cs`; nothing in
SharedKernel, Domain or the tests (rehearsed 2026-10-06: 39 s, the skill fired and quoted its
own steps, then asked whether to create `Helpdesk.ApiTests`; the error codes and the
`{ "id": ... }` body are pinned in the `/slice` text because an unpinned run invented
`Tickets.TitleRequired` and a bare-string body).

**File: `.claude/skills/slice/SKILL.md` (new file)**

```markdown
---
name: slice
description: Use when asked to add a new command or query slice to a module, wire up a new endpoint, or implement a new use case end to end through Application, Presentation and registration.
---

# Add a vertical slice

Add one command or query, its handler, its validator, its endpoint and its registration.
One use case per slice. Follow CLAUDE.md and AGENTS.md exactly; they are the contract.

## Steps

1. Read CLAUDE.md, then read the nearest existing slice in
   `src/Modules/<Module>/Helpdesk.<Module>.Application/<Aggregate>/` and copy its shape.
   The existing code is the specification; do not invent a second way of doing this.
2. Create the Application file `<UseCase>.cs` beside its siblings. It holds, in order:
   the command or query record implementing `ICommand<TResponse>` or `IQuery<TResponse>`,
   the handler (internal, sealed, thin: load or create through the domain, call the domain
   behavior, save through `IUnitOfWork`), and any response records the query returns.
3. Add a validator implementing `IValidator<T>` in the same file when the input has a
   shape to check. Validators check input shape only. Business rules belong in the domain
   entity and are returned as a `Result` failure, never thrown.
4. Add the minimal-API endpoint in
   `src/Modules/<Module>/Helpdesk.<Module>.Presentation/<Aggregate>Endpoints.cs`.
   Map the `Result` the handler returns: success to 201 Created for a create, 204 No Content
   for a state change, 200 OK for a query; failure to 404 when the error code ends in
   `NotFound`, and 400 Bad Request with the error code and message otherwise.
5. Register the handler in the module's existing registration extension
   (`TicketsApplication.cs` for the Tickets module). Do not add new infrastructure, a new
   DI container, or a new registration file.
6. Add a test. Domain rules go in `tests/Helpdesk.<Module>.Domain.Tests`. Status-code
   mapping goes in `tests/Helpdesk.ApiTests`, which drives the real host against the SQL
   Server container.
7. Verify: run `docker compose up -d`, then `dotnet build Helpdesk.slnx` and
   `dotnet test Helpdesk.slnx`. Show the output. Warnings are errors, so a build that
   reports any warning is a failure.

## Constraints

- Never modify SharedKernel, the Domain layer, or an existing test to make a slice pass.
- Never add a NuGet package. Never change the database schema without a migration.
- If a step conflicts with an existing convention, stop and ask rather than improvising.
```

Explain the format in three sentences, no more. The frontmatter `description` is the trigger:
the agent matches it against what the person asked for, so it is written as a situation ("when
asked to add a new command or query slice"), not as a summary of the mechanism. The body is the
procedure, and it only loads once the skill fires, so it costs nothing until it is needed. The
shape is portable: the same SKILL.md format is read by GitHub Copilot (which also scans
`.claude/skills`) and OpenAI Codex (which scans only `.agents/skills`), so a team writes the
procedure once instead of once per tool.

Then the attendee types, in the repo:

```text
/slice add a CreateTicket command: CreateTicket(string Title) returning the new Guid, with a
validator that rejects blank titles and titles over 200 characters, and POST /tickets taking
{ "title": "..." }. Use the error codes Tickets.Validation.EmptyTitle and
Tickets.Validation.TitleTooLong, and return 201 Created with the body { "id": "<new guid>" }.
```

The last sentence pins the response contract, so an AI-path repo answers exactly like the
manual path and the `CloseTicketTests.cs` paste in 3b works on either. If an agent asks
whether to create `tests/Helpdesk.ApiTests` (SKILL.md step 6 points there), the answer is "not
yet, 3b creates it"; the handout says the same.

The point to land while they run it: the long prompt from the old version of this lab is now a
file in the repo, under review, in version control, shared by the whole team. A prompt somebody
retypes from memory drifts; a skill does not.

Manual path (and the fallback if the skill does not fire): the same instructions as a prompt,
verbatim on the handout.

> Add a complete vertical slice for creating a ticket, following CLAUDE.md conventions:
> 1. In Helpdesk.Tickets.Application, one new file Tickets/CreateTicket.cs (namespace
>    Helpdesk.Tickets.Application.Tickets) holding all three types: a CreateTicket(string
>    Title) command implementing `ICommand<Guid>`, a CreateTicketHandler that uses
>    Ticket.Create, ITicketRepository, and IUnitOfWork, and a CreateTicketValidator
>    implementing `IValidator<CreateTicket>` that rejects blank titles
>    (Tickets.Validation.EmptyTitle) and titles over 200 characters
>    (Tickets.Validation.TitleTooLong).
> 2. In Helpdesk.Tickets.Presentation: a POST /tickets minimal-API endpoint taking
>    { "title": "..." }, calling the handler, returning 201 with `{ "id": "<new guid>" }` on
>    success and 400 with the error code and message on failure.
> 3. Register the handler and validator in TicketsApplication.AddTicketsApplication using
>    the existing AddCommandHandler extension only.
> Do not modify SharedKernel, the Domain project, or the tests.

While they run it, float and coach diff review: is the handler thin (load/create, call
domain, save)? Did business logic leak into the endpoint or validator?

### Lab 3a, manual path (no Claude Code)

What manual-path attendees do (handout lab3, "Lab 3a, manual path (no agent)", word for word):
the three blocks below, in this order. The two by-hand steps attendees miss are the two `using`
lines (each a CS0246 when skipped, rehearsed), so the handout puts each one BEFORE the block that
needs it; point at them from the front.

No agent, or neither the skill nor the prompt works: create the slice by hand, mirroring the
section A-C patterns.

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CreateTicket.cs` (new file)**

```csharp
using Helpdesk.SharedKernel;
using Helpdesk.Tickets.Application.Abstractions;
using Helpdesk.Tickets.Domain;

namespace Helpdesk.Tickets.Application.Tickets;

public sealed record CreateTicket(string Title) : ICommand<Guid>;

internal sealed class CreateTicketHandler(ITicketRepository tickets, IUnitOfWork unitOfWork)
    : ICommandHandler<CreateTicket, Guid>
{
    public async Task<Result<Guid>> Handle(CreateTicket command, CancellationToken ct)
    {
        var ticketResult = Ticket.Create(command.Title);
        if (ticketResult.IsFailure)
            return Result.Failure<Guid>(ticketResult.Error);

        tickets.Add(ticketResult.Value);
        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success(ticketResult.Value.Id);
    }
}

internal sealed class CreateTicketValidator : IValidator<CreateTicket>
{
    public IReadOnlyList<Error> Validate(CreateTicket instance)
    {
        var errors = new List<Error>();
        if (string.IsNullOrWhiteSpace(instance.Title))
            errors.Add(new Error("Tickets.Validation.EmptyTitle", "Title is required."));
        else if (instance.Title.Length > 200)
            errors.Add(new Error("Tickets.Validation.TitleTooLong", "Title must be 200 characters or fewer."));
        return errors;
    }
}
```

Registration lines in `TicketsApplication.AddTicketsApplication`. First add
`using Helpdesk.Tickets.Application.Tickets;` at the top of the file, or `CreateTicket` does not
resolve (CS0246):

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/TicketsApplication.cs` (edit)**

```csharp
services.AddCommandHandler<CreateTicket, Guid, CreateTicketHandler>();
services.AddScoped<IValidator<CreateTicket>, CreateTicketValidator>();
```

Endpoint in `TicketEndpoints.MapTicketEndpoints`. First add the same
`using Helpdesk.Tickets.Application.Tickets;` at the top of `TicketEndpoints.cs` (CS0246
without it), and `public sealed record CreateTicketRequest(string Title);` in that file above
the `TicketEndpoints` class:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` (edit)**

```csharp
app.MapPost("/tickets", async (CreateTicketRequest request,
    ICommandHandler<CreateTicket, Guid> handler, CancellationToken ct) =>
{
    var result = await handler.Handle(new CreateTicket(request.Title), ct);
    return result.IsSuccess
        ? Results.Created($"/tickets/{result.Value}", new { id = result.Value })
        : Results.BadRequest(new { result.Error.Code, result.Error.Message });
});
```

The 3b registrations and endpoints reuse both `using` lines.

Then the same diff review and verify as the AI path, and commit.

### Lab 3a verify (both paths)

Start the host in its own terminal and leave it running (every table, both paths; the
2026-10-08 rehearsal skipped this and got two blank lines from the curls):

```bash
dotnet run --project src/Helpdesk.Host
```

Wait for `Now listening on: http://localhost:5000`, then from a second terminal:

```bash
curl -sS -i -X POST localhost:5000/tickets -H "content-type: application/json" -d '{"title":"Printer on fire"}'
curl -sS -i -X POST localhost:5000/tickets -H "content-type: application/json" -d '{"title":""}'
```

`-i` prints the status line (`HTTP/1.1 201 Created`, `HTTP/1.1 400 Bad Request`) above the
body; `-S` keeps curl's error visible under `-s`. The second call returns 400 with
`Tickets.Validation.EmptyTitle`: the validator answers first.

Three traps to call out from the front. No output at all, or `curl: (7) Failed to connect`,
means nothing is listening on 5000: the host is not running (or is on another port), not a
code bug (found in the 2026-10-08 rehearsal, where plain `-s` printed two blank lines). The port is 5000 only if the attendee pasted the
`launchSettings.json` edit in the plumbing beat; a host that prints another port (whatever
`dotnet new web` chose, for example 5139) means that file was skipped, and it has to be fixed
now, because Labs 6 and 7 hard-code 5000. On a Mac, a host that dies with `address already in
use` on 5000, or curls answered `403 Forbidden` by `Server: AirTunes`, is AirPlay Receiver:
System Settings > General > AirDrop & Handoff > AirPlay Receiver off, then restart the host. And on Windows these curls
are bash-quoted, so Git Bash runs them as printed but cmd.exe needs the inner quotes escaped
(`-d "{\"title\":\"Printer on fire\"}"`) and PowerShell needs `curl.exe` spelled out (bare
`curl` aliases to Invoke-WebRequest on Windows PowerShell). A body that reaches the endpoint
starting with `'` means the shell passed the single quotes through: JsonException, not a code
bug.

Watch the console: the logging decorator's line appears for both. "Nobody wrote logging in the
handler. That is the pipeline paying rent."

Then the commit (handout lab3, end of "Lab 3a: diff review and verify", word for word):

Commit the slice once both calls answer as above, so 3b's test starts from a known-good tree:

```bash
git add -A && git commit -m "CreateTicket slice"
```

## Lab 3b: test-first at the API level (13 min, incl. the debrief)

The slice: `POST /tickets/{id}/close` calling `Ticket.Close`, returning 204 / 400 / 404. The
difference from 3a is the ORDER. In Lab 2 the test came first at the domain level, where the
test needed nothing. Now the test comes first at the API level, where it needs the real host,
the real pipeline and a real database, and the room finds out that this is still cheap.

Say the framing out loud before they start: **the agent writes the test first, you read it,
you watch it fail, and only then does the agent write the code.** A test written after the code
describes the code. A test written before it describes the requirement.

Say the container line too: this is the first test in the day that needs infrastructure, so
the container comes up before anything else, and the test database is its own
(`Helpdesk_ApiTests`), never the development one. Attendees run (handout lab3, Lab 3b intro):

```bash
docker compose up -d
```

### Lab 3b Step 1: the test project (both paths)

Step 1, the test project. Attendees add it and wire it into the solution:

```bash
dotnet new xunit -o tests/Helpdesk.ApiTests
dotnet sln add tests/Helpdesk.ApiTests
dotnet add tests/Helpdesk.ApiTests package Microsoft.AspNetCore.Mvc.Testing
dotnet add tests/Helpdesk.ApiTests reference src/Helpdesk.Host
```

Then delete the template's `tests/Helpdesk.ApiTests/UnitTest1.cs` (the handout says so; left in
place it adds a third API test and the Lab 4 count of 11 becomes 12).

**File: `tests/Helpdesk.ApiTests/Helpdesk.ApiTests.csproj` (new file)**

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="coverlet.collector" Version="6.0.4" />
    <PackageReference Include="Microsoft.AspNetCore.Mvc.Testing" Version="10.0.10" />
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.14.1" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.1.4" />
  </ItemGroup>

  <ItemGroup>
    <Using Include="Xunit" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\..\src\Helpdesk.Host\Helpdesk.Host.csproj" />
  </ItemGroup>

</Project>
```

### Lab 3b Step 2: the factory (both paths)

Step 2, the factory. `WebApplicationFactory<Program>` boots the real host in memory, overrides
one configuration key so the tests get their own database, and drops and re-migrates it once
per run:

**File: `tests/Helpdesk.ApiTests/HelpdeskApiFactory.cs` (new file)**

```csharp
using Helpdesk.Tickets.Infrastructure;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Helpdesk.ApiTests;

/// <summary>
/// Boots the real Host in memory and points it at the workshop SQL Server container,
/// using a database of its own so a test run never touches development data.
/// </summary>
public sealed class HelpdeskApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private const string TestConnectionString =
        "Server=localhost,14330;Database=Helpdesk_ApiTests;User Id=sa;Password=Workshop!Passw0rd;TrustServerCertificate=True";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
        => builder.UseSetting("ConnectionStrings:Tickets", TestConnectionString);

    /// <summary>Drops and re-creates the test database from the migrations, once per run.</summary>
    public async Task InitializeAsync()
    {
        using var scope = Services.CreateScope();
        var database = scope.ServiceProvider.GetRequiredService<TicketsDbContext>().Database;
        await database.EnsureDeletedAsync();
        await database.MigrateAsync();
    }

    // WebApplicationFactory already owns teardown; this satisfies xUnit's async lifetime.
    Task IAsyncLifetime.DisposeAsync() => Task.CompletedTask;
}
```

Moment: Lab 3b, an append below the plumbing-beat `Program.cs` edit shown earlier.

`WebApplicationFactory<Program>` needs to SEE `Program`. On the .NET 10 SDK the class
generated from top-level statements is already accessible, so the factory builds without help
(confirmed on SDK 10.0.401); older SDKs (.NET 8 and 9) failed here with CS0122, "Program is
inaccessible due to its protection level". The two lines at the bottom of the host stay
anyway: harmless, and explicit about what the tests rely on. Mention CS0122 only for anyone on
an older SDK:

**File: `src/Helpdesk.Host/Program.cs` (append)**

```csharp
// Top-level statements hide the generated entry point class, and
// WebApplicationFactory<Program> in the API tests needs to see it.
public partial class Program { }
```

### Lab 3b Step 3, AI path: ask for the test and nothing else

Step 3, the test, written BEFORE the CloseTicket slice exists. On the AI path the attendee asks
for it; on the manual path they paste it from the handout. Either way they read it before
running it:

What attendees do (handout lab3, "Step 3: the test, BEFORE the slice", "AI path, ask for the
test and nothing else:", word for word):

> Write `tests/Helpdesk.ApiTests/CloseTicketTests.cs` with two facts, and do not write the
> CloseTicket slice yet. Fact one: POST /tickets creates a ticket, POST /tickets/{id}/close
> returns 204, and GET /tickets/{id} then reports the status as Closed. Fact two: closing the
> same ticket twice returns 400 with the error code Tickets.AlreadyClosed. Use
> HelpdeskApiFactory as an IClassFixture. Do not change any file outside tests/Helpdesk.ApiTests.

What the agent should produce: exactly one new file, `tests/Helpdesk.ApiTests/CloseTicketTests.cs`,
with the two facts and no slice code (rehearsed 2026-10-06: 17 s, `git status` showed only that
file; its version read the 201 body as a bare `Guid` and the GET body through `JsonDocument`,
which is fine as long as it matches the 3a response shape).

### Lab 3b Step 3, manual path: paste it

What manual-path attendees do (handout lab3, "Step 3: the test, BEFORE the slice", word for
word): "Manual path, paste it:" the file below. AI-path attendees compare their agent's version
against it.

**File: `tests/Helpdesk.ApiTests/CloseTicketTests.cs` (new file)**

```csharp
using System.Net;
using System.Net.Http.Json;

namespace Helpdesk.ApiTests;

public class CloseTicketTests(HelpdeskApiFactory factory) : IClassFixture<HelpdeskApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Closing_an_open_ticket_succeeds_and_the_ticket_reads_back_as_closed()
    {
        var id = await CreateTicket("Printer on fire");

        var close = await _client.PostAsync($"/tickets/{id}/close", null);

        Assert.Equal(HttpStatusCode.NoContent, close.StatusCode);
        var ticket = await _client.GetFromJsonAsync<TicketView>($"/tickets/{id}");
        Assert.Equal("Closed", ticket!.Status);
    }

    [Fact]
    public async Task Closing_the_same_ticket_twice_is_rejected_as_a_bad_request()
    {
        var id = await CreateTicket("Monitor flickering");
        await _client.PostAsync($"/tickets/{id}/close", null);

        var secondClose = await _client.PostAsync($"/tickets/{id}/close", null);

        Assert.Equal(HttpStatusCode.BadRequest, secondClose.StatusCode);
        var error = await secondClose.Content.ReadFromJsonAsync<ErrorView>();
        Assert.Equal("Tickets.AlreadyClosed", error!.Code);
    }

    private async Task<Guid> CreateTicket(string title)
    {
        var response = await _client.PostAsJsonAsync("/tickets", new { title });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var created = await response.Content.ReadFromJsonAsync<CreatedTicketView>();
        return created!.Id;
    }

    private sealed record CreatedTicketView(Guid Id);

    private sealed record TicketView(Guid Id, string Title, string Status);

    private sealed record ErrorView(string Code, string Message);
}
```

### Lab 3b Step 4: run it RED (both paths)

Step 4, run it RED (the container is already up from the 3b intro).

Moment: Step 4, the RED run (Step 6 runs the same command GREEN).

```bash
dotnet test Helpdesk.slnx
```

It fails at `/tickets/{id}/close` with a 404, because the route does not exist. That 404 is the
goalposts.

Fact one also reads the ticket back through `GET /tickets/{id}`, which does not exist yet
either, so Step 5 is TWO slices. This used to be a fast-finisher extra; the 2026-09-28 attendee
rehearsal showed that anyone treating it as optional ends 3b with fact one still red, so the
handout now makes it required. Its code is under "Lab 3b Step 5, manual path" below.

Then they commit the red test (handout lab3, end of "Step 4: run it RED", word for word):

Commit the red test now, so `git diff HEAD -- tests` after Step 5 shows at a glance whether a
slice edited it:

```bash
git add -A && git commit -m "Close and read-back API test (red)"
```

### Lab 3b Step 5, AI path: `/slice` twice

What attendees do (handout lab3, "Step 5: now the two slices", word for word): "The command
first:" the first `/slice` text below; "Then the query the test reads back through (your first
read path; no validator):" the second; then: "That last clause is the Lab 2 guardrail one level
up. "Make the test pass" is the instruction; "make the test green" is an invitation to edit the
test."

Step 5, `/slice` twice. CloseTicket first:

```text
/slice add a CloseTicket command: CloseTicket(Guid TicketId) returning bool, calling
Ticket.Close, with POST /tickets/{id}/close mapping success to 204, Tickets.NotFound to 404 and
other failures to 400. The API test for it already exists; do not modify it.
```

Then the read-back query (the day's first read path, no validator):

```text
/slice add a GetTicketById query: GetTicketById(Guid TicketId) returning
TicketResponse(Guid Id, string Title, string Status, IReadOnlyList<ChildTaskResponse> ChildTasks)
with ChildTaskResponse(Guid Id, string Description, bool IsDone), loading through
ITicketRepository.GetById, with GET /tickets/{id} mapping success to 200 and Tickets.NotFound to
404. The API test that reads it back already exists; do not modify it.
```

Timing: the second `/slice` is a few minutes of agent time inside the same 10-minute solo
block. If the room is behind, hand out the Step 5 manual-path GetTicketById code instead of running it.

Note the last clause out loud. It is the same guardrail phrase as Lab 2, one level up: the
agent's objective is the gate you named, so name the gate as "make this pass", never "make the
test green".

What the agent should produce: first `CloseTicket.cs` + its `AddCommandHandler` registration +
`POST /tickets/{id:guid}/close` (fact one still red on the missing GET, which proves the second
slice is required), then `GetTicketById.cs` + `AddQueryHandler` + `MapGet("/tickets/{id:guid}")`;
the test file untouched both times (rehearsed 2026-10-06: 25 s and 29 s; the agent declined to
add the GET inside the first slice, "one use case per slice").

### Lab 3b Step 5, manual path (no Claude Code)

What manual-path attendees do (handout lab3, "Step 5, manual path: paste the two slices", word
for word): the blocks below, in this order, AFTER the red run; the test stays first on both
paths. The 3a `using` lines already cover both files. The reference solution in `lab3-end`
reuses `ITicketRepository` for the GetTicketById load rather than projecting straight off the
DbContext; a pure read-path projection is the refinement worth naming out loud if anyone asks.

No agent: create both slices by hand. The command first, `Application/Tickets/CloseTicket.cs`:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CloseTicket.cs` (new file)**

```csharp
using Helpdesk.SharedKernel;
using Helpdesk.Tickets.Application.Abstractions;
using Helpdesk.Tickets.Domain;

namespace Helpdesk.Tickets.Application.Tickets;

public sealed record CloseTicket(Guid TicketId) : ICommand<bool>;

internal sealed class CloseTicketHandler(ITicketRepository tickets, IUnitOfWork unitOfWork)
    : ICommandHandler<CloseTicket, bool>
{
    public async Task<Result<bool>> Handle(CloseTicket command, CancellationToken ct)
    {
        var ticket = await tickets.GetById(command.TicketId, ct);
        if (ticket is null)
            return Result.Failure<bool>(TicketErrors.NotFound);

        var closeResult = ticket.Close();
        if (closeResult.IsFailure)
            return Result.Failure<bool>(closeResult.Error);

        await unitOfWork.SaveChangesAsync(ct);
        return Result.Success(true);
    }
}
```

Registration, in `TicketsApplication.AddTicketsApplication` below the 3a lines:
`services.AddCommandHandler<CloseTicket, bool, CloseTicketHandler>();`

Endpoint, in `TicketEndpoints.MapTicketEndpoints` below the 3a POST:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` (edit)**

```csharp
app.MapPost("/tickets/{id:guid}/close", async (Guid id,
    ICommandHandler<CloseTicket, bool> handler, CancellationToken ct) =>
{
    var result = await handler.Handle(new CloseTicket(id), ct);
    if (result.IsSuccess) return Results.NoContent();
    return result.Error.Code == "Tickets.NotFound"
        ? Results.NotFound()
        : Results.BadRequest(new { result.Error.Code, result.Error.Message });
});
```

Then the read-back query, `Application/Tickets/GetTicketById.cs`, through `IQueryHandler` with no
validator. (Real read paths often bypass the domain with a thin read abstraction; today reuse
the repository and keep moving.)

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/GetTicketById.cs` (new file)**

```csharp
using Helpdesk.SharedKernel;
using Helpdesk.Tickets.Application.Abstractions;
using Helpdesk.Tickets.Domain;

namespace Helpdesk.Tickets.Application.Tickets;

public sealed record GetTicketById(Guid TicketId) : IQuery<TicketResponse>;

public sealed record TicketResponse(
    Guid Id,
    string Title,
    string Status,
    IReadOnlyList<ChildTaskResponse> ChildTasks);

public sealed record ChildTaskResponse(Guid Id, string Description, bool IsDone);

internal sealed class GetTicketByIdHandler(ITicketRepository tickets)
    : IQueryHandler<GetTicketById, TicketResponse>
{
    public async Task<Result<TicketResponse>> Handle(GetTicketById query, CancellationToken ct)
    {
        var ticket = await tickets.GetById(query.TicketId, ct);
        if (ticket is null)
            return Result.Failure<TicketResponse>(TicketErrors.NotFound);

        var response = new TicketResponse(
            ticket.Id,
            ticket.Title,
            ticket.Status.ToString(),
            ticket.ChildTasks
                .Select(c => new ChildTaskResponse(c.Id, c.Description, c.IsDone))
                .ToList());

        return Result.Success(response);
    }
}
```

Registration, in `TicketsApplication.AddTicketsApplication` beside the two command registrations:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/TicketsApplication.cs` (edit)**

```csharp
services.AddQueryHandler<GetTicketById, TicketResponse, GetTicketByIdHandler>();
```

Endpoint, in `TicketEndpoints.MapTicketEndpoints` beside the two POSTs:

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/TicketEndpoints.cs` (edit)**

```csharp
app.MapGet("/tickets/{id:guid}", async (Guid id,
    IQueryHandler<GetTicketById, TicketResponse> handler, CancellationToken ct) =>
{
    var result = await handler.Handle(new GetTicketById(id), ct);
    if (result.IsSuccess) return Results.Ok(result.Value);
    return result.Error.Code == "Tickets.NotFound"
        ? Results.NotFound()
        : Results.BadRequest(new { result.Error.Code, result.Error.Message });
});
```

### Lab 3b Step 6: green, then tell the context files (both paths)

Step 6, run it GREEN:

Moment: Step 6, the GREEN run (the same command as the Step 4 RED run).

```bash
dotnet test Helpdesk.slnx
```

Expect 7 green (Domain 4, Architecture 1, Api 2). Then note the one-line change the test project
forced on the context files, identical in both:

**File: `CLAUDE.md` (edit)**

```text
- Test: dotnet test Helpdesk.slnx (API tests need the SQL container: docker compose up -d)
```

The same line goes in `AGENTS.md`. "The agent just learned a prerequisite it had no way to
guess. That is what these files are for, and both tools read one of them."

Then the commit (handout lab3, end of Step 6, word for word):

Commit the two slices and the context-file line together, so Lab 4 starts from a green tree:

```bash
git add -A && git commit -m "CloseTicket and GetTicketById slices"
```

## Debrief (3 min, inside the 3b block)

- Poll: hands up if the CloseTicket slice took under ten minutes once the test was red. Deliver
  the payoff line.
- The deeper point: **the pipeline is a convention the agent can follow.** Slice two was fast
  because the machinery is boring and uniform. Boring and uniform is what both new hires and
  agents need. The skill and the failing test are how that convention gets delivered.

## Two event paths: the outbox in five minutes (5 min)

Whiteboard only, no code, hard stop at 12:05. Draw two arrows out of the Ticket aggregate:

1. **Domain events, in-process**: "something happened, and other code in THIS module reacts
   before or at save time." Same transaction, same process, can stay simple. That is the
   `TicketClosed` event Lab 2 raised and nobody has consumed yet.
2. **Integration events, cross-module**: "something happened that OTHER modules, or one day
   other services, care about." These must survive a crash, so they go through an outbox.

Rule of thumb to give them: domain events are a design pattern; integration events are a
reliability contract. A `TicketClosed` domain event becomes a `TicketClosedIntegrationEvent`
only because you decided other modules may depend on it, and the mapping is explicit, never
automatic; you do not want internal domain vocabulary leaking into a public contract.

Then the one-line version of why the outbox exists: save the ticket and publish the event are
two writes to two systems that do not share a transaction, so a crash between them either
loses the notification or announces something that never happened. The fix is to make the
publish BE a database write, in the same transaction, and let a background relay do the actual
publishing from that table.

Close it honestly: "That is a 45-minute session on its own, and it is not on today's agenda.
The full version and the relay are on the `main` branch, the take-home branch: it builds and
runs. To see the replay, close a ticket and stop the host inside the relay's ten-second poll
window, then restart it." Nothing in the rest of the day depends on it.

Hand off to lunch at 12:05 on the dot: "Lunch until 12:50. Come back and we make every rule we
have talked about this morning executable, so the build refuses the violation instead of a
reviewer catching it."

## If things go wrong

- EF migration failures (SQL container down or still starting, connection string typos) are
  THE risk here. A "pre-login handshake" error right after `docker compose up -d` is a
  container still starting: wait, rerun only the update.
  Fallback: `docker compose up -d` check first; worst case attendees check out `lab3-end` and
  fix their own copy over lunch.
- "Login failed for user 'sa'" with the container up: something else answered the port. The
  compose file maps host port 14330 precisely so a locally installed SQL Server (which owns
  1433) cannot shadow the container; this bites anyone who hand-rolled a `"1433:1433"`
  mapping (Docker can bind only IPv6 there and still look healthy in `docker ps`). Fix: use
  the kit's `"14330:1433"` mapping and `Server=localhost,14330` in the connection string,
  then `docker compose up -d --force-recreate` and rerun the update.
- macOS, `dotnet ef: command not found` right after the global install: zsh does not put
  `~/.dotnet/tools` on PATH. `echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile`,
  new terminal.
- macOS, port 5000 `address already in use` or `403` from `AirTunes`: AirPlay Receiver. Off in
  System Settings > General > AirDrop & Handoff; never move the API off 5000, Labs 6 and 7
  hard-code it.
- Apple Silicon, the SQL container exits seconds after `docker compose up -d`: Docker Desktop's
  Rosetta setting is off (the image is amd64 only). Settings > General > "Use Rosetta for
  x86_64/amd64 emulation on Apple Silicon", restart Docker, `docker compose up -d`.
- Agent invents a mediator/generic dispatcher in 3a: reject the plan, point at the SKILL.md
  constraint "do not invent a second way of doing this" and tighten to "use the existing
  AddCommandHandler extension only."
- `/slice` does not fire for somebody: their agent did not match the description, or the skill
  folder is not in the repo they opened. Do not debug it in the room; hand them the manual-path
  prompt, which is the same instructions, and move on.
- CS0122 "Program is inaccessible" in the API tests (older SDKs only; .NET 10 does not raise
  it): the `public partial class Program { }` append is missing from the host.
- CS0246 on `CreateTicket` in `TicketsApplication.cs` or `TicketEndpoints.cs` (manual path):
  the `using Helpdesk.Tickets.Application.Tickets;` line is missing; the handout's 3a step
  names it.
- Behind schedule: cut the outbox mention first (it is the only part with no dependent), then
  make 3b's two `/slice` steps homework and stop after the red test; never skip the red run itself,
  since watching the test fail is the whole point of the block.
- Lab 4's fitness tests need the solution building; a working POST /tickets is nice but not
  required.
