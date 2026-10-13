# Lab 6 Handout: Run it (2:15-2:45)

Snapshot branch if you get stuck: `lab6-end`
Prerequisite: `lab5-end` plus your Lab 5 work. You also need the **Aspire CLI 13.6 or newer**
(check with `aspire --version`; 13.6 is the current release, the version this lab was
rehearsed on and the one the AppHost pins; anything before 13.2 has no `agent` command, which step 4 depends on), the
**Aspire 13.6 templates** (`dotnet new install Aspire.ProjectTemplates::13.6.0`; older
templates write a 13.0 AppHost that the 13.6 CLI and its MCP server cannot see), and
**Docker running**. The `docker compose`
container from the earlier labs can stay up: the AppHost starts a second SQL container on a
different port by design.

**Goal:** one command starts the database, the API and a dashboard that shows you what they
did; then your agent reads that dashboard over MCP and finds a bug the API response hides.

The snapshot branch `lab6-end` carries `docs/running.md`, which is this procedure as a repo
file. Copy it into your own repo tonight: a procedure in the repo is one the agent can read.

Run everything below from the repository root, in a real terminal. The AppHost does not work
from a background shell.

---

## Step 1: add the AppHost

### AI path

```text
Add an Aspire AppHost to this solution, plus a shared ServiceDefaults project.

1. src/Helpdesk.ServiceDefaults: OpenTelemetry traces, metrics and logs with OTLP export,
   ASP.NET Core, HttpClient, runtime and SQL client instrumentation, standard HTTP
   resilience, service discovery, a "self" health check tagged "live", and a
   MapDefaultEndpoints that maps /alive (only checks tagged "live") and /health (all
   checks) in EVERY environment, not just Development.
2. src/Helpdesk.AppHost: a SQL Server resource named "sql" with a persistent container
   lifetime, a data volume and container name helpdesk-aspire-sql. Do NOT bind host port
   14330; the docker compose container from the earlier labs owns it and must keep running.
   Add a database resource named "Tickets" whose physical database is HelpdeskTickets.
   Add Helpdesk.Host as a project resource named "api", with WithReference on the database,
   WaitFor on the database, and WithEnvironment Migrations__ApplyOnStartup = true.
   Use Aspire 13.6.0: Aspire.AppHost.Sdk/13.6.0, Aspire.Hosting.SqlServer 13.6.0, and
   AspireUseCliBundle set to true.
   Set RestorePackagesWithLockFile to false in the AppHost project file and delete its
   packages.lock.json: the AppHost SDK adds a dashboard package for the restoring machine's
   own platform, so its lock file can never match the Linux CI runner.
3. In Helpdesk.Host: call AddServiceDefaults, add AddDbContextCheck<TicketsDbContext> named
   "tickets-db", replace the hand-written /health stub with MapDefaultEndpoints, and migrate
   on startup only when Migrations:ApplyOnStartup is true. It defaults to off.

Create both projects from the templates (dotnet new aspire-apphost, dotnet new
aspire-servicedefaults) and do not suppress any warning.
Do not change any Domain, Application, Infrastructure or Presentation file.
Stay on the current branch: do not create a branch, commit, or push.
```

### Manual path

Create both projects from the templates and add them to the solution first. Every project
file, reference and code block below points at them:

```sh
dotnet new aspire-apphost -o src/Helpdesk.AppHost
dotnet new aspire-servicedefaults -o src/Helpdesk.ServiceDefaults
dotnet sln add src/Helpdesk.AppHost src/Helpdesk.ServiceDefaults
```

The AppHost project file goes in before `AppHost.cs`, because the code needs what it adds:
`AddSqlServer` comes from the `Aspire.Hosting.SqlServer` package and `Projects.Helpdesk_Host`
from the Host project reference.

First check the version on the generated project file. The 13.6 template writes
`<Project Sdk="Aspire.AppHost.Sdk/13.6.0">` and `<AspireUseCliBundle>true</AspireUseCliBundle>`.
If yours says `13.0.0`, your templates are old; the file below sets both either way. A 13.0
AppHost still runs under the 13.6 CLI, but `aspire ps` and the MCP server then find no running
AppHost, and step 4 has nothing to read.

The project file also needs a lock-file property, two package references and one project
reference. The property first: Lab 5 turned lock files on for every project, but the AppHost
SDK adds a dashboard package for the machine doing the restore (`Aspire.Dashboard.Sdk.win-x64`
on a Windows laptop, `Aspire.Dashboard.Sdk.osx-arm64` on an Apple Silicon Mac), so an AppHost lock file made on your laptop can never match the Linux CI
runner, and CI's locked-mode restore fails with `NU1004`. The AppHost never ships, so it opts
out. Replace the generated project file with this one, then delete
`src/Helpdesk.AppHost/packages.lock.json` if a restore already wrote one:

**File: `src/Helpdesk.AppHost/Helpdesk.AppHost.csproj` (new file)**

```xml
<Project Sdk="Aspire.AppHost.Sdk/13.6.0">

  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <UserSecretsId>fa654e4e-cef4-41a0-9f4b-8a6f8f30bdbe</UserSecretsId>
    <!-- The AppHost SDK adds a dashboard package for the restoring machine's own
         platform (Aspire.Dashboard.Sdk.win-x64 on a Windows laptop), so its lock file
         can never match the Linux CI runner and locked mode fails with NU1004.
         The AppHost never ships (the image is published from Helpdesk.Host), so it
         opts out of the lock files Lab 5 turned on everywhere else. -->
    <RestorePackagesWithLockFile>false</RestorePackagesWithLockFile>
    <AspireUseCliBundle>true</AspireUseCliBundle>
  </PropertyGroup>

  <ItemGroup>
    <!-- Match the Aspire.AppHost.Sdk version on the Project line. -->
    <PackageReference Include="Aspire.Hosting.SqlServer" Version="13.6.0" />
    <!-- Aspire 13.0 pulled MessagePack 2.5.192 transitively, a version with published
         advisories, and NuGetAudit refused the build. 13.6 pulls a clean 2.5.302; naming
         the package directly keeps a fixed floor whatever the SDK pulls. Bump, never suppress. -->
    <PackageReference Include="MessagePack" Version="2.5.303" />
  </ItemGroup>

  <ItemGroup>
    <!-- Gives the AppHost a typed Projects.Helpdesk_Host handle. It is a build time
         reference only: the host does not reference the AppHost back. -->
    <ProjectReference Include="..\Helpdesk.Host\Helpdesk.Host.csproj" />
  </ItemGroup>

</Project>
```

The `MessagePack` pin is a supply-chain story: on Aspire 13.0 the AppHost pulled `MessagePack`
2.5.192 transitively, that version carries published advisories, and the audit mode you turned
on in Lab 5 refused the build until it was pinned forward. Aspire 13.6 pulls 2.5.302, which is
clean, so the pin is now a harmless floor. Keep it. Bump, never suppress.

Now replace the generated `AppHost.cs` with this:

**File: `src/Helpdesk.AppHost/AppHost.cs` (new file)**

```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Aspire runs its own SQL Server container. It gets its own container name and whatever host
// port Aspire assigns, so the docker compose container on 14330 that labs 1 to 5 use keeps
// running beside it and neither one can take the other's port.
var sql = builder.AddSqlServer("sql")
    .WithContainerName("helpdesk-aspire-sql")
    .WithLifetime(ContainerLifetime.Persistent)   // survives a stop, so a restart is seconds
    .WithDataVolume("helpdesk-aspire-sql-data");  // and the data survives with it

// The resource name is the connection string name that WithReference injects. Calling this
// database "Tickets" is what lands it on ConnectionStrings:Tickets, which is the key the
// Tickets module already reads. The physical database is still HelpdeskTickets.
var tickets = sql.AddDatabase("Tickets", "HelpdeskTickets");

builder.AddProject<Projects.Helpdesk_Host>("api")
    .WithReference(tickets)

    // WaitFor gates startup on the SQL resource reporting healthy: that is liveness of a
    // dependency, and it is the right thing to wait on. A service must never gate its own
    // startup on its own readiness endpoint (/health), because /health only goes green after
    // the schema is in place, and the schema only arrives after the service starts. Wait on
    // what you depend on, report your own readiness, and never wait on yourself.
    .WaitFor(tickets)

    // Only the orchestrated run migrates on startup. Labs 1 to 5 keep using
    // dotnet ef database update against the compose container, so the default stays off.
    .WithEnvironment("Migrations__ApplyOnStartup", "true");

builder.Build().Run();
```

The generated `ServiceDefaults/Extensions.cs` is almost right out of the box. Change two
things. First, the template maps the health endpoints in Development only, and you want them
mapped everywhere, because a container probe reads them from outside the process where the
environment name is whatever the platform set.

**File: `src/Helpdesk.ServiceDefaults/Extensions.cs` (excerpt: the health endpoints, mapped in every environment)**

```csharp
    public static WebApplication MapDefaultEndpoints(this WebApplication app)
    {
        // The template maps these in Development only. We map them in every environment
        // because a container probe reads them from outside the app, where the environment
        // name is whatever the platform set. Both endpoints are unauthenticated, so do not
        // put secrets in a check description.

        // Readiness: every check, including the database. "Can this instance take traffic?"
        app.MapHealthChecks(HealthEndpointPath);

        // Liveness: only checks tagged "live". "Is this process worth keeping alive?"
        app.MapHealthChecks(AlivenessEndpointPath, new HealthCheckOptions
        {
            Predicate = registration => registration.Tags.Contains("live"),
        });

        return app;
    }
```

Second, the template has no SQL client tracing. Add the package first, because the call below
does not compile without it:

```sh
dotnet add src/Helpdesk.ServiceDefaults package OpenTelemetry.Instrumentation.SqlClient --version 1.19.0
```

Then append `.AddSqlClientInstrumentation()` after `.AddHttpClientInstrumentation()` in the
`WithTracing` block. It is the line that makes the `INSERT` show up inside your request trace
in step 2. The `options.Filter` above it keeps the health probes out of the trace list:

**File: `src/Helpdesk.ServiceDefaults/Extensions.cs` (excerpt: the tracing configuration)**

```csharp
            .WithTracing(tracing => tracing
                .AddSource(builder.Environment.ApplicationName)
                .AddAspNetCoreInstrumentation(options =>
                    // Health probes run every few seconds. Keep them out of the trace list.
                    options.Filter = context =>
                        !context.Request.Path.StartsWithSegments(HealthEndpointPath)
                        && !context.Request.Path.StartsWithSegments(AlivenessEndpointPath))
                .AddHttpClientInstrumentation()
                // This is the span that makes a create-ticket trace worth looking at:
                // the INSERT shows up as a child of the HTTP request.
                .AddSqlClientInstrumentation());
```

Finally, the composition root. Its project gains the ServiceDefaults project reference and
`Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore`, which is what
`AddDbContextCheck` comes from. Add both first, because the new code calls into both:

```sh
dotnet add src/Helpdesk.Host reference src/Helpdesk.ServiceDefaults
dotnet add src/Helpdesk.Host package Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore --version 10.0.10
```

Then the code. About ten lines of real change, and the `/health` string stub from Lab 3 goes
away. Replace the whole file with this one: everything outside the new lines is what Lab 3
left there, including `app.MapTicketEndpoints();`, `app.Run();` and the
`public partial class Program { }` tail that the API tests need.

**File: `src/Helpdesk.Host/Program.cs` (edit)**

```csharp
using Helpdesk.Tickets.Infrastructure;
using Helpdesk.Tickets.Presentation;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// Telemetry, resilience, service discovery and the "self" liveness check.
builder.AddServiceDefaults();

builder.Services.AddTicketsModule(builder.Configuration);

// Readiness only: this check is untagged, so /health waits on the database and /alive does not.
builder.Services.AddHealthChecks()
    .AddDbContextCheck<TicketsDbContext>("tickets-db");

var app = builder.Build();

// Maps /alive (liveness) and /health (readiness). Replaces the hand written /health stub.
app.MapDefaultEndpoints();

// Migrations:ApplyOnStartup is off by default, and only the AppHost turns it on. An explicit
// switch beats sniffing the environment: you can read it in one line, the labs that run the
// host on its own keep migrating by hand with dotnet ef database update, and the API tests,
// which drop and re-create their own database in the factory, never migrate twice.
if (app.Configuration.GetValue<bool>("Migrations:ApplyOnStartup"))
{
    using var scope = app.Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<TicketsDbContext>().Database.MigrateAsync();
}

app.MapTicketEndpoints();
app.Run();

// Top-level statements hide the generated entry point class, and
// WebApplicationFactory<Program> in the API tests needs to see it.
public partial class Program { }
```

The new third `using`, `Microsoft.EntityFrameworkCore`, is what makes `MigrateAsync` resolve: it
is an extension method, and without the `using` the build fails with `CS1061` on
`DatabaseFacade`.

Last, both paths: tell the context files the AppHost exists. One identical line in each, directly
under `- Run:` in the `## Commands` list:

**File: `CLAUDE.md` (edit)**

```text
- Run (orchestrated): aspire run --apphost src/Helpdesk.AppHost (dashboard URL is printed)
```

Add the same line to `AGENTS.md`, in the same place.

What will differ from `lab6-end`, all of it harmless (both paths). The 13.6 templates write a
few things the snapshot branch does not have; build 0/0 and 13 green either way, and Lab 7 does
not touch these files:

- `src/Helpdesk.AppHost/aspire.config.json` exists only in yours. It tells the Aspire CLI which
  project is the AppHost; every command in this lab passes `--apphost` explicitly anyway.
- Your AppHost `Properties/launchSettings.json` has its own random ports and no
  `ASPIRE_DASHBOARD_MCP_ENDPOINT_URL`. Aspire.Hosting 13.4 and later (the AppHost pins 13.6.0)
  no longer reads that variable, and step 4 reaches the dashboard through `aspire agent mcp`.
- `Helpdesk.ServiceDefaults.csproj` keeps the template's `OpenTelemetry.*` 1.17.0 and
  `Microsoft.Extensions.Http.Resilience` / `ServiceDiscovery` 10.10.0, where `lab6-end` has
  1.19.0 and 10.0.0. The 1.19.0 SQL client package you added on top restores and builds clean.
  The `packages.lock.json` files differ to match.
- `Extensions.cs` keeps the template's comments and layout outside the two excerpts you replaced.

## Step 2: run it and read the dashboard

```sh
aspire run --apphost src/Helpdesk.AppHost
```

The console prints a dashboard URL with a login token in it, like
`https://localhost:17288/login?t=...`. **Open the printed link.** Typing the host name by hand
lands you on a login page you cannot get past. Leave the command running; stopping it stops
everything it started.
If the browser warns that the dashboard's certificate is not trusted, stop the run (Ctrl+C),
trust the development certificate with `dotnet dev-certs https --trust` (Windows: answer Yes
in the security dialog; macOS: enter your login password), and start it again.

What to click, in order:

1. **Resources.** Two rows, `sql` and `api`. Note that `api` only went green after `sql` did.
   That is `WaitFor`, visible.
2. Create something worth tracing, using the port the dashboard shows for `api`:

   ```sh
   curl -i -X POST http://localhost:5000/tickets -H "content-type: application/json" -d "{\"title\":\"Printer on fire\"}"
   ```

   In PowerShell, `\"` is not an escape, so this body arrives broken (a 400 saying
   `'\' is an invalid start of a property name`). Single-quote the body instead,
   `-d '{"title":"Printer on fire"}'`, and type `curl.exe` on Windows PowerShell 5.1, where
   `curl` means `Invoke-WebRequest`.

3. **Traces**, newest first. Click it. Two levels: the `POST /tickets` ASP.NET Core span
   (what the caller waited for) and, directly under it, an `INSERT` span from the SQL client.
   Without SQL instrumentation that database time is not missing, it is
   worse: it shows up as unexplained empty space inside the HTTP span and you go hunting in
   your own code for it.
4. **Structured logs.** The dashboard joins them to the trace by trace id, so you can go from
   a slow span to the exact log lines written during that request without grepping anything.

## Step 3: the two health endpoints, and the rule

```sh
curl -i http://localhost:5000/alive
curl -i http://localhost:5000/health
```

- `/alive` is **liveness**: it runs only checks tagged `live`, and the only one is `self`,
  which answers healthy and checks nothing else on purpose. "Is this process worth keeping
  alive?"
- `/health` is **readiness**: it runs everything, including the `tickets-db` check. "Can this
  instance take traffic right now?" A database outage turns this red and leaves `/alive`
  green, which is correct, because restarting the process would not help.

The rule that follows, and it is the sentence to take home: **startup gates on liveness,
never on readiness.** `WaitFor(tickets)` holds the API until SQL reports healthy, which is a
dependency's liveness. Nothing waits on the API's own `/health`, because readiness only goes
green after the schema is in place and the schema only arrives after the API starts. Wait on
what you depend on, report your own readiness, never wait on yourself.

### Prove it headless: two tests (both paths paste these)

The dashboard is the demo; these are the proof CI can run. A second test class now shares the
API factory, and the factory drops and re-creates the test database, so first give the whole
test assembly ONE factory instead of one per class:

**File: `tests/Helpdesk.ApiTests/ApiCollection.cs` (new file)**

```csharp
namespace Helpdesk.ApiTests;

/// <summary>
/// One factory for the whole assembly. The factory drops and re-creates the test database,
/// so two test classes must not each own a copy of it and reset it under one another.
/// </summary>
[CollectionDefinition(Name)]
public sealed class ApiCollection : ICollectionFixture<HelpdeskApiFactory>
{
    public const string Name = "Api";
}
```

Move the Lab 3 tests onto it: in `CloseTicketTests.cs`, add one attribute line above the class
declaration and delete `: IClassFixture<HelpdeskApiFactory>` from the end of it. Nothing else
in the file changes: the `using` lines, the namespace, the opening brace and every test method
stay as they are.

**File: `tests/Helpdesk.ApiTests/CloseTicketTests.cs` (edit: the top of the file)**

Before:

```csharp
using System.Net;
using System.Net.Http.Json;

namespace Helpdesk.ApiTests;

public class CloseTicketTests(HelpdeskApiFactory factory) : IClassFixture<HelpdeskApiFactory>
{
    private readonly HttpClient _client = factory.CreateClient();
```

After:

```csharp
using System.Net;
using System.Net.Http.Json;

namespace Helpdesk.ApiTests;

[Collection(ApiCollection.Name)]
public class CloseTicketTests(HelpdeskApiFactory factory)
{
    private readonly HttpClient _client = factory.CreateClient();
```

The `: IClassFixture<HelpdeskApiFactory>` part goes because the collection now supplies the
factory: xUnit still fills the `factory` constructor parameter, from the one shared instance.
With a class fixture each test class would get its own factory, and two of them would drop and
re-create the same test database under each other.

Then the two health tests:

**File: `tests/Helpdesk.ApiTests/HealthEndpointsTests.cs` (new file)**

```csharp
using System.Net;

namespace Helpdesk.ApiTests;

/// <summary>
/// The health endpoints are mapped in every environment, so they are reachable from a probe
/// outside the process. These two tests are the headless proof; the dashboard is the demo.
/// </summary>
[Collection(ApiCollection.Name)]
public class HealthEndpointsTests(HelpdeskApiFactory factory)
{
    private readonly HttpClient _client = factory.CreateClient();

    [Fact]
    public async Task Liveness_answers_healthy()
    {
        var response = await _client.GetAsync("/alive");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task Readiness_answers_healthy_when_the_database_is_reachable()
    {
        var response = await _client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Healthy", await response.Content.ReadAsStringAsync());
    }
}
```

Run the whole suite before you commit. Stop the AppHost first (Ctrl+C in its terminal): while
it runs, the API process locks its own `bin` folder and the test build fails with `MSB3027`.
The API tests use the morning's compose SQL container on 14330, not the Aspire one, so it must
still be up (`docker compose up -d` if not):

```bash
dotnet test Helpdesk.slnx
```

13 green: Domain 4, Architecture 5, Api 4 (the two Lab 3 close tests, now on the shared
collection, plus the two health tests). Leave the AppHost stopped; Step 4 starts it again.

Commit your Lab 6 work now, so Step 4's branch switch leaves from a clean tree:

```bash
git add -A && git commit -m "AppHost and health endpoints"
```

## Step 4: the closed loop (optional follow-along)

The instructor runs this on the projector. Do it with them if your machine is keeping up, or
over the break, or tonight. Either way, read it now.

1. Stop the run and confirm `git status` is clean (your Lab 6 work was committed at the end of
   Step 3; checkout refuses to switch over uncommitted changes), check out the branch with the
   planted fault, run the API tests while the run is still stopped (a running AppHost locks the
   API's `bin` folder and the test build fails with `MSB3027`), then start it again. Expect two
   red: both `CloseTicketTests` fail, the two health tests pass. That is the fault proved
   before you look for it, and the red that step 6 turns green. Your own repository
   has no `lab6-fault` branch; it lives in the workshop repository, so add that as a second
   remote named `workshop` and fetch it first (it is public at
   <https://github.com/ivanball/adc2026-helpdesk>). Skip the `remote add` line if you already
   have the remote:

   ```sh
   git status
   git remote add workshop https://github.com/ivanball/adc2026-helpdesk.git
   git fetch workshop
   git checkout -b lab6-fault workshop/lab6-fault
   dotnet test tests/Helpdesk.ApiTests
   aspire run --apphost src/Helpdesk.AppHost
   ```

   The `dotnet test` run shows 2 red, the two close tests: the fault is real.

2. Create a ticket, close it, read it back:

   ```sh
   curl -s -X POST http://localhost:5000/tickets -H "content-type: application/json" -d "{\"title\":\"Badge reader dead\"}"
   curl -i -X POST http://localhost:5000/tickets/<id>/close
   curl -s http://localhost:5000/tickets/<id>
   ```

   The close returns `204`. The read back says `"status":"Open"`. Close it a second time and
   you get `204` again, where Lab 3 said it must be `400 Tickets.AlreadyClosed`.

3. Connect your agent to the running application. The repository already ships the MCP server
   entry (it is on `lab6-fault` and `lab6-end`; step 6 copies it onto your own `main`);
   `aspire agent init --mcp` writes the same thing for whichever agent you pick (without
   `--mcp` it installs skills only and leaves MCP unconfigured).

   **File: `.mcp.json` (new file)**

   ```json
   {
     "mcpServers": {
       "aspire": {
         "command": "aspire",
         "args": ["agent", "mcp"]
       }
     }
   }
   ```

   VS Code reads `.vscode/mcp.json` in a different shape: a top-level `servers` key and
   `"type": "stdio"` on the entry; `aspire agent init --mcp` writes it if you pick VS Code.
   Restart your agent after the file
   appears, and confirm the `aspire` server is listed and connected (`/mcp` in Claude Code)
   before asking anything. A disconnected server gives you an agent reasoning from source
   code, which sounds exactly as confident and is not the exercise.

4. Ask it, without telling it where the bug is:

   > Tickets do not close. The close endpoint returns 204 but the ticket reads back as open.
   > Use the aspire MCP server to read the logs and traces from the running app, find out
   > why from the running application rather than by reading the code first, and fix it.

   **What a good run looks like:** it lists the resources, pulls the structured logs, filters
   to Error, finds `Background close for ticket ... did not persist` with an
   `ObjectDisposedException`, follows the stack trace to `CloseTicket.cs`, and only then opens
   the file. It may then restart the `api` resource through the MCP server and re-run the
   curls to check its own fix; that is allowed.

   **What a good fix looks like:** the save is awaited inside the request, and the `catch`
   that swallowed the failure is deleted. A fix that keeps the background task and captures a
   fresh scope makes the symptom go away and keeps the original sin, which is that the caller
   gets a 204 for a write that has not happened yet. Reject that one.

5. **Manual path** (no agent, or the MCP server will not connect): do the same investigation
   yourself, and in the same order. In the dashboard, open **Structured logs** and filter to
   **Error**. One entry, with the exception and a stack trace pointing at `CloseTicket.cs`
   line 37. Then open **Traces**: the close request is there, green, answered `204`, with a
   `SELECT` under it and no `UPDATE`. The Error log sits on that same trace, written after the
   request's span had already ended. **An Error log on a request whose trace already ended
   green is the tell: the work ran after the caller had its answer.** Now open the file and put
   the save back where it belongs. The handler you are aiming at is the one on `lab6-end`:

   **File: `src/Modules/Tickets/Helpdesk.Tickets.Application/Tickets/CloseTicket.cs` (excerpt: the reference handler on `lab6-end`)**

   ```csharp
           var closeResult = ticket.Close();
           if (closeResult.IsFailure)
               return Result.Failure<bool>(closeResult.Error);

           await unitOfWork.SaveChangesAsync(ct);
           return Result.Success(true);
   ```

   Then delete what only the background write used: the `logger` constructor parameter, the
   `WriteDelay` field and `using Microsoft.Extensions.Logging;`. A leftover `logger` parameter
   fails the build with `CS9113` (parameter is unread), because warnings are errors here.

6. Verify, then go back. Stop the run first (Ctrl+C): while the AppHost runs, the API process
   locks its own `bin` folder and `dotnet test` cannot build (`MSB3027`). Test, then start the
   run again (seconds, the SQL container is persistent):

   ```sh
   dotnet test tests/Helpdesk.ApiTests
   aspire run --apphost src/Helpdesk.AppHost
   ```

   Close a ticket: the close trace now carries an `UPDATE` span. Stop the run, drop the fix
   (it lives on the planted fault's branch) and go back to your own work on `main`, where
   step 3 committed it:

   ```sh
   git restore .
   git checkout main
   git checkout lab6-fault -- .mcp.json
   git status --short
   ```

   Go back to `main`, not to the workshop's `lab6-end`. `main` is the history you pushed in
   Lab 5, the one your required check guards, and Labs 7 and 8 build on it; `lab6-end` shares
   no commits with your repository and is only for a rescue (see Troubleshooting).

   The third line brings the `aspire` MCP entry along: `.mcp.json` is committed on
   `lab6-fault`, not on your `main`. And `git restore .` drops only changes to tracked files, so
   whatever `aspire agent init` wrote in step 3 is untracked and comes along too: the agent
   skills (`.claude/skills/aspire*/` for Claude Code and Copilot, `.agents/skills/` for Codex),
   `.vscode/mcp.json` if you picked VS Code, and an `aspire.config.json` at the repository root
   if the CLI wrote one. All of that is Lab 6 work, so commit it now, as Lab 6. Left alone,
   Lab 7's first `git add -A` sweeps it into "MCP server with three tools": about 90 files,
   where the Lab 7 change is 7.

   ```sh
   git add -A && git commit -m "Aspire MCP config and agent skills"
   ```

## Step 5: watch the deploy

Demo only, and not on workshop wifi. Per-attendee Azure is not part of this workshop.

The same graph you wrote in step 1 is the deployment description: one container app per
project resource, SQL Server as one more container app (`AddSqlServer` is a container;
`AddAzureSqlServer` is the managed Azure SQL option), and the connection strings wired the way
`WithReference` wired them on your laptop. No folder of YAML maintained by hand that drifts
from the code by Thursday.

```sh
aspire deploy --apphost src/Helpdesk.AppHost
```

It reads the deployment targets the AppHost declares, so an Azure Container Apps run needs
that environment added to `AppHost.cs` first. `azd init` then `azd up` does the same job from
the same AppHost and is the fallback.

### Optional: validate `aspire deploy` (your own Azure subscription; it costs money while it exists)

Work on a scratch branch: the deploy target is demo code, and Labs 7 and 8 build on `main`.

1. Add the integration. Pin it to the AppHost's own Aspire version (13.6.0); without
   `--version` the CLI picks the newest patch and the AppHost ends up on two versions:

   ```sh
   git switch -c lab6-deploy
   aspire add azure-appcontainers --version 13.6.0 --apphost src/Helpdesk.AppHost
   ```

2. Declare the target in `AppHost.cs`. The package alone declares nothing: it only makes
   `AddAzureContainerAppEnvironment` available, and until the AppHost calls it there is still
   nothing to deploy. Replace the whole file with this one: it is the step 1 file plus three
   added lines, marked `// NEW`:

   **File: `src/Helpdesk.AppHost/AppHost.cs` (whole file after the edit)**

   ```csharp
   var builder = DistributedApplication.CreateBuilder(args);

   // The deployment target: aspire deploy provisions an Azure Container Apps environment.  // NEW
   builder.AddAzureContainerAppEnvironment("env");                                          // NEW

   // Aspire runs its own SQL Server container. It gets its own container name and whatever host
   // port Aspire assigns, so the docker compose container on 14330 that labs 1 to 5 use keeps
   // running beside it and neither one can take the other's port.
   var sql = builder.AddSqlServer("sql")
       .WithContainerName("helpdesk-aspire-sql")
       .WithLifetime(ContainerLifetime.Persistent)   // survives a stop, so a restart is seconds
       .WithDataVolume("helpdesk-aspire-sql-data");  // and the data survives with it

   // The resource name is the connection string name that WithReference injects. Calling this
   // database "Tickets" is what lands it on ConnectionStrings:Tickets, which is the key the
   // Tickets module already reads. The physical database is still HelpdeskTickets.
   var tickets = sql.AddDatabase("Tickets", "HelpdeskTickets");

   builder.AddProject<Projects.Helpdesk_Host>("api")
       .WithExternalHttpEndpoints()                                                         // NEW
       .WithReference(tickets)

       // WaitFor gates startup on the SQL resource reporting healthy: that is liveness of a
       // dependency, and it is the right thing to wait on. A service must never gate its own
       // startup on its own readiness endpoint (/health), because /health only goes green after
       // the schema is in place, and the schema only arrives after the service starts. Wait on
       // what you depend on, report your own readiness, and never wait on yourself.
       .WaitFor(tickets)

       // Only the orchestrated run migrates on startup. Labs 1 to 5 keep using
       // dotnet ef database update against the compose container, so the default stays off.
       .WithEnvironment("Migrations__ApplyOnStartup", "true");

   builder.Build().Run();
   ```

   The `// NEW` markers are only there to show you what changed; leave them out or keep them,
   the build does not care. On the AI path your step 1 file reads differently, so do not paste
   over it: add the same three lines in the same two places (the environment right after
   `CreateBuilder`, `.WithExternalHttpEndpoints()` as the first call on `api`). Either way,
   `git diff src/Helpdesk.AppHost/AppHost.cs` should show only additions (the three marked
   lines and one blank line) and nothing removed.

3. Check the pipeline before spending anything, now that step 2 is saved. This is offline and
   touches no cloud resource:

   ```sh
   aspire deploy --apphost src/Helpdesk.AppHost --list-steps
   ```

   Expect 12 steps, among them `build-api`, `validate-azure-login`, `provision-env-acr`,
   `provision-env` and `provision-azure-bicep-resources`, ending in `deploy`. **One step only
   (`1. deploy`, "No dependencies") means step 2 is missing**: the AppHost declares no target,
   which is also why a plain `aspire deploy` on the Lab 6 AppHost does nothing. Go back and
   make the two edits; do not deploy until you see the 12.

4. Deploy, in your own terminal (it prompts for subscription, location and resource group, so
   it cannot run headless). Run `az login` first:

   ```sh
   aspire deploy --apphost src/Helpdesk.AppHost
   ```

   **At "Select your Azure resource group or enter a new name", type a NEW name** (for example
   `helpdesk-demo-rg`). The prompt suggests the resource groups that already exist in your
   subscription, and accepting one deploys the demo into it: step 6 then cannot delete the
   group without deleting everything else in it. The deploy remembers your answers, so if you
   picked the wrong group, re-run with `--clear-cache` to be asked again.

   Expect about 16 minutes, most of it creating the Container Apps environment
   (`provision-env`, about 14 of them, with no output while it waits). It is not hung. It ends
   with `Pipeline succeeded` and prints the `api` URL and an Aspire dashboard URL.

5. Verify the deployed app, using the `api` URL the deploy printed:

   ```sh
   curl -i https://<api-url>/health
   curl -s -X POST https://<api-url>/tickets -H "content-type: application/json" -d '{"title":"Printer on fire"}'
   ```

   `/health` answering `Healthy` means the API reached SQL and `Migrations__ApplyOnStartup`
   built the schema in the cloud. Then close the ticket and read it back, as in Lab 3: the close
   answers `204`, the read back says `"status":"Closed"`, and a second close is `400`.

6. Tear it down the same day. The environment, its container registry, its Log Analytics
   workspace and its storage account cost money while they exist. With the demo in its own
   group, one command removes all of it:

   ```sh
   az group delete -n helpdesk-demo-rg --yes --no-wait
   git switch main
   ```

   Run that only against the new group from step 4, never against a group that held anything
   before the deploy.

## Verify

With the AppHost stopped (a running AppHost locks the API's `bin` and the test build fails
with `MSB3027`):

```sh
dotnet test tests/Helpdesk.ApiTests
```

Four green: the two `CloseTicketTests` from Lab 3 and two new health-endpoint tests. On
`lab6-fault` the two close tests fail; once the fault is gone they pass.

Whole solution: 13 green (Domain 4, Architecture 5, Api 4).

And in the dashboard after the fix and a restart of the run: the Error log is gone, and the close request's trace now
carries an `UPDATE` span it did not have before. Two kinds of evidence, and the telemetry one
is the one that would have caught this in production, where nobody had written the test.

Worth noticing: the five architecture tests pass on **both** branches. A swallowed exception
in a background task is a behavior bug and no layer rule can see it. Tests catch what rules
cannot; telemetry catches what nobody wrote a test for.

## Troubleshooting

- **macOS: the `api` resource fails with `address already in use` on 5000, or the curls get
  `403 Forbidden` from `AirTunes`.** AirPlay Receiver owns port 5000 on a Mac. Switch it off
  (System Settings > General > AirDrop & Handoff > AirPlay Receiver) and run the AppHost again.
- **Apple Silicon: the `sql` resource keeps restarting or exits.** Docker Desktop's Rosetta
  setting is off and the amd64-only SQL Server image cannot run. Settings > General > "Use
  Rosetta for x86_64/amd64 emulation on Apple Silicon", restart Docker, run the AppHost again.
- **`Unrecognized command or argument 'agent'`.** Your Aspire CLI predates 13.2. These
  commands moved from `aspire mcp` to `aspire agent` in 13.2, so an older CLI has
  one spelling, the other, or neither. Update the CLI; there is no workaround for step 4.
- **The app runs, but `aspire ps` says "No running AppHost found" and the MCP server lists no
  AppHost.** Your AppHost project still says `Aspire.AppHost.Sdk/13.0.0`. Make it `13.6.0`,
  set `Aspire.Hosting.SqlServer` to `13.6.0`, add `<AspireUseCliBundle>true</AspireUseCliBundle>`
  and restart the run. The CLI gives no warning; it just cannot see the older AppHost.
- **`api` never leaves Waiting.** Docker is not running, or SQL is still starting. Start
  Docker Desktop and re-run; the persistent container lifetime makes the second start seconds.
- **`sql` and `Tickets` stay Running (Unhealthy) and `api` stays Waiting.** Run
  `docker logs --tail 5 helpdesk-aspire-sql`. If it repeats `Login failed for user 'sa'.
  Reason: Password did not match`, the data volume is left over from an earlier run (a rehearsal
  at home, or an AppHost you rebuilt or recloned). Aspire generated a new `sa` password, stored in
  this AppHost's user secrets, but SQL Server only reads it when it first creates `master`, so the
  old volume keeps the old password. Stop the AppHost (Ctrl+C; the persistent container keeps
  running), then delete the container and its volume. The volume is `helpdesk-aspire-sql-data`
  with the code above; an unnamed `.WithDataVolume()` gets `helpdesk.apphost-<hash>-sql-data`.
  Run the first line before the second to see which name yours has:

  ```sh
  docker inspect helpdesk-aspire-sql --format "{{range .Mounts}}{{.Name}}{{end}}"
  docker rm -f helpdesk-aspire-sql
  docker volume rm helpdesk-aspire-sql-data
  ```

  Start the AppHost again. You lose only the old rehearsal tickets; `Migrations__ApplyOnStartup`
  rebuilds the schema, and `sql` goes Healthy in about 30 seconds.
- **Login page with no way in.** You typed the dashboard host name instead of opening the link
  the console printed. The token is in the query string; scroll the terminal up.
- **Port clash with the morning's container.** There should not be one: nothing here binds a
  host port. If you added `.WithHostPort(14330)`, remove it. The compose container owns 14330
  and your Lab 3 connection strings depend on it. Read the port off the dashboard instead.
- **500s about a missing table.** The migration did not run. Check the `api` resource's
  environment in the dashboard for `Migrations__ApplyOnStartup`. Note the double underscore:
  the key is `Migrations:ApplyOnStartup`, and a single underscore silently does nothing.
- **The agent does not see the `aspire` server.** Is `.mcp.json` at the repository root, did
  you restart the agent after creating it, and does the agent list the server as connected? If
  it is listed but failing, run `aspire agent mcp` in a terminal and read the error (if it
  starts cleanly it just waits on input; Ctrl+C to stop).
- **API tests fail with a database error.** They use their own database through
  `HelpdeskApiFactory` and need the compose container (`docker compose up -d`), not the
  Aspire one.
- **Completely stuck.** Add and fetch the `workshop` remote as in step 4.1, then
  `git checkout -b lab6-end workshop/lab6-end` and read `docs/running.md`. Labs 7 and 8 work
  on that branch too, with one difference: it shares no commits with the repository you pushed
  in Lab 5, so your required check does not guard it, and Lab 8 rule 4 says so.
- **`git status` still lists `.agents/`, `.claude/skills/aspire*/`, `.vscode/` or
  `aspire.config.json` after you went back to `main`.** That is `aspire agent init`'s output
  from step 3, untracked, so neither `git restore .` nor the checkout touched it. Commit it as
  the end of step 4.6 shows, before Lab 7 starts.
