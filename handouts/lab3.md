# Lab 3 Handout: Vertical slices through the pipeline (11:10-12:05)

Snapshot branch if you get stuck: `lab3-end`
Prerequisite: `lab2-end` plus everything pasted during the Lab 3 lecture. ALL paste
material is in this handout so you can catch up standalone. Paste sections A-D first if you
have not already; they are lecture material, not the lab.

**Goal:** ship three vertical slices, all driven by the `/slice` Agent Skill the repo ships
(the old supplied prompt is still here as the manual path, and it is the fallback if the skill
does not fire). 3a is `POST /tickets`. 3b is `POST /tickets/{id}/close`, written test-first at
the API level together with the required `GET /tickets/{id}` read-back its test needs: the
integration test comes before the slices.

---

## Paste section A: the pipeline machinery

New packages (Application layer only needs abstractions):

```bash
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Application package Microsoft.Extensions.DependencyInjection.Abstractions
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Application package Microsoft.Extensions.Logging.Abstractions
dotnet add src/Helpdesk.Host package Microsoft.EntityFrameworkCore.Design
```

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

`.../TicketsApplication.cs` (handlers are internal, so they register inside their own
assembly; each slice adds one line here):

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

## Paste section B: infrastructure

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

## Paste section C: presentation + host

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

The whole file after the edit (the new part is the `ConnectionStrings` block; note the comma
after `"AllowedHosts": "*"`):

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

Last, the launch profile. The workshop pins the API to port 5000, so every curl, `.http` file
and MCP client config later in the day works as printed. Replace the whole generated file (it
has a random port and an `https` profile) with this one:

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

## Paste section D: migration (together)

```bash
docker compose up -d
dotnet build Helpdesk.slnx
dotnet ef migrations add Initial -p src/Modules/Tickets/Helpdesk.Tickets.Infrastructure -s src/Helpdesk.Host
dotnet ef database update -p src/Modules/Tickets/Helpdesk.Tickets.Infrastructure -s src/Helpdesk.Host
```

The container is already up if you started it in Lab 1 (the command is then a no-op), and
`database update` needs it. The build comes before the migration because `dotnet ef` reads the
restored project assets: on a fresh `lab2-end` clone that was never built it stops with
`NETSDK1004` (assets file `project.assets.json` not found).

(No `dotnet ef`? `dotnet tool install --global dotnet-ef`. Still "command not found" on a Mac
after installing it: zsh is missing the tools folder on its PATH, so run
`echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile` and open a new terminal; on
Windows, open a new Git Bash window. A warning that the Entity Framework tools version is older
than the runtime is harmless.)

("Login failed for user 'sa'" with the container running? Something else answered the port.
The compose file maps host port 14330 exactly so a locally installed SQL Server on 1433
cannot shadow the container; check your `docker-compose.yml` says `"14330:1433"` and your
connection string says `Server=localhost,14330`, then
`docker compose up -d --force-recreate` and rerun both `dotnet ef` commands.)

Commit the pasted machinery and the migration now, so each slice below lands as its own small
diff:

```bash
git add -A && git commit -m "Command pipeline and persistence"
```

---

## Lab 3a, AI path: the `/slice` skill

The repo ships a skill. The frontmatter `description` is the trigger the agent matches against
what you ask for; the body is the procedure, and it only loads once the skill fires. The same
SKILL.md format works in GitHub Copilot (which also reads `.claude/skills`) and OpenAI Codex
(which reads only `.agents/skills`, so copy the folder there for Codex), so the procedure is
written once for the team, reviewed in a pull request, and versioned like any other file.

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

Invoke it (if `/slice` is not offered, check that `.claude/skills/slice/SKILL.md` is present in
the repo folder you opened; skills are discovered per repo):

```text
/slice add a CreateTicket command: CreateTicket(string Title) returning the new Guid, with a
validator that rejects blank titles and titles over 200 characters, and POST /tickets taking
{ "title": "..." }. Use the error codes Tickets.Validation.EmptyTitle and
Tickets.Validation.TitleTooLong, and return 201 Created with the body { "id": "<new guid>" }.
```

If the agent asks whether to create `tests/Helpdesk.ApiTests` for an API test, answer "not
yet, 3b creates it": that project does not exist until 3b.

If your agent does not support skills, or `/slice` does not fire, use the same instructions as
a prompt:

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

## Lab 3a, manual path (no agent)

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

## Lab 3a: diff review and verify (both paths)

**Diff review:** is the handler thin (create via domain, add, save)? Did business logic leak
into the endpoint or the validator? Validators check input shape; the domain owns the rules.

**Verify.** Start the host in its own terminal and leave it running:

```bash
dotnet run --project src/Helpdesk.Host
```

Wait for `Now listening on: http://localhost:5000`, then send the two calls from a second
terminal:

```bash
curl -sS -i -X POST localhost:5000/tickets -H "content-type: application/json" -d '{"title":"Printer on fire"}'
curl -sS -i -X POST localhost:5000/tickets -H "content-type: application/json" -d '{"title":""}'
```

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

Commit the slice once both calls answer as above, so 3b's test starts from a known-good tree:

```bash
git add -A && git commit -m "CreateTicket slice"
```

## Lab 3b: test-first at the API level

The slice: `POST /tickets/{id}/close` calling `Ticket.Close`. 204 on success, 404 when the
ticket does not exist, 400 on a business rule failure. Command shape:
`CloseTicket(Guid TicketId) : ICommand<bool>`.

The difference from 3a is the ORDER: the test comes FIRST, and this time it is an integration
test that drives the real host against the real database. The SQL container has to be up:

```bash
docker compose up -d
```

### Step 1: the test project

```bash
dotnet new xunit -o tests/Helpdesk.ApiTests
dotnet sln add tests/Helpdesk.ApiTests
dotnet add tests/Helpdesk.ApiTests package Microsoft.AspNetCore.Mvc.Testing
dotnet add tests/Helpdesk.ApiTests reference src/Helpdesk.Host
```

Delete the template's `tests/Helpdesk.ApiTests/UnitTest1.cs`; `CloseTicketTests.cs` in Step 3
replaces it.

The commands above already generated the project file. Check it against this one; it should
match apart from version numbers:

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

### Step 2: the factory (paste)

`WebApplicationFactory<Program>` boots the real host in memory, overrides one configuration key
so the tests get a database of their own, and drops and re-migrates it once per run.

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

`WebApplicationFactory<Program>` has to see the host's `Program` class. On the .NET 10 SDK the
class generated from top-level statements is already accessible, so this builds as is; older
SDKs (.NET 8 and 9) failed here with CS0122 ("Program is inaccessible due to its protection
level"). Add the two lines at the BOTTOM of the host file anyway: they are harmless and state
explicitly what the tests rely on.

**File: `src/Helpdesk.Host/Program.cs` (append)**

```csharp
// Top-level statements hide the generated entry point class, and
// WebApplicationFactory<Program> in the API tests needs to see it.
public partial class Program { }
```

### Step 3: the test, BEFORE the slice

AI path, ask for the test and nothing else:

> Write `tests/Helpdesk.ApiTests/CloseTicketTests.cs` with two facts, and do not write the
> CloseTicket slice yet. Fact one: POST /tickets creates a ticket, POST /tickets/{id}/close
> returns 204, and GET /tickets/{id} then reports the status as Closed. Fact two: closing the
> same ticket twice returns 400 with the error code Tickets.AlreadyClosed. Use
> HelpdeskApiFactory as an IClassFixture. Do not change any file outside tests/Helpdesk.ApiTests.

Manual path, paste it:

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

### Step 4: run it RED

Moment: Step 4, the RED run (Step 6 runs the same command GREEN).

```bash
dotnet test Helpdesk.slnx
```

It fails on `/tickets/{id}/close`: the route does not exist yet. A test you have never seen
fail proves nothing. Fact one also reads the ticket back with `GET /tickets/{id}`, which does
not exist yet either, so Step 5 adds two slices: the close command, then the read-back query.

Commit the red test now, so `git diff HEAD -- tests` after Step 5 shows at a glance whether a
slice edited it:

```bash
git add -A && git commit -m "Close and read-back API test (red)"
```

### Step 5: now the two slices

The command first:

```text
/slice add a CloseTicket command: CloseTicket(Guid TicketId) returning bool, calling
Ticket.Close, with POST /tickets/{id}/close mapping success to 204, Tickets.NotFound to 404 and
other failures to 400. The API test for it already exists; do not modify it.
```

Then the query the test reads back through (your first read path; no validator):

```text
/slice add a GetTicketById query: GetTicketById(Guid TicketId) returning
TicketResponse(Guid Id, string Title, string Status, IReadOnlyList<ChildTaskResponse> ChildTasks)
with ChildTaskResponse(Guid Id, string Description, bool IsDone), loading through
ITicketRepository.GetById, with GET /tickets/{id} mapping success to 200 and Tickets.NotFound to
404. The API test that reads it back already exists; do not modify it.
```

That last clause is the Lab 2 guardrail one level up. "Make the test pass" is the instruction;
"make the test green" is an invitation to edit the test.

### Step 5, manual path: paste the two slices

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

### Step 6: green, then tell the context files

Moment: Step 6, the GREEN run (the same command as the Step 4 RED run).

```bash
dotnet test Helpdesk.slnx
```

Expect 7 green: Domain 4, Architecture 1 (the Lab 1 placeholder, which Lab 4 replaces), Api 2.
Eight means `UnitTest1.cs` survived Step 1.

Add the same line to BOTH `CLAUDE.md` and `AGENTS.md`, replacing the plain test line:

**File: `CLAUDE.md` (edit)**

```text
- Test: dotnet test Helpdesk.slnx (API tests need the SQL container: docker compose up -d)
```

Commit the two slices and the context-file line together, so Lab 4 starts from a green tree:

```bash
git add -A && git commit -m "CloseTicket and GetTicketById slices"
```
