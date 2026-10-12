# Lab 1 Handout: Zero to walking skeleton (9:15-10:05)

Snapshot branch if you get stuck: `lab1-end`

**Goal:** a solution that builds green with zero warnings: four Tickets layer projects plus
SharedKernel, Host, and two test projects, wired so the compiler enforces the dependency rule.
No business logic yet.

## Target structure

```
helpdesk/
  Helpdesk.slnx
  CLAUDE.md
  AGENTS.md
  Directory.Build.props
  docker-compose.yml
  src/
    Helpdesk.SharedKernel/                  (Result, Error, Entity, IDomainEvent arrive in Lab 2)
    Helpdesk.Host/                          (ASP.NET Core host, composition root)
    Modules/Tickets/
      Helpdesk.Tickets.Domain/
      Helpdesk.Tickets.Application/
      Helpdesk.Tickets.Infrastructure/
      Helpdesk.Tickets.Presentation/
  tests/
    Helpdesk.Tickets.Domain.Tests/
    Helpdesk.ArchitectureTests/
```

Dependency rule (only these references are allowed):

```
Domain -> SharedKernel                (nothing else; zero packages)
Application -> Domain
Infrastructure -> Application         (implements its interfaces; EF Core lives here)
Presentation -> Application
Host -> Presentation, Infrastructure  (composition root only)
```

## Step 1 (together): repo + context file FIRST

**Windows: run every terminal command today in Git Bash** (it comes with Git for Windows; open
it from the Start menu, or as a Windows Terminal or VS Code terminal profile). The commands are
printed for Bash: PowerShell runs most of them, Command Prompt (cmd.exe) does not, and Lab 5's
branch-protection call runs only in Bash.

**macOS: the stock Terminal (zsh) runs every command as printed, after one setting.** Some
commands end in a `# comment`, and zsh passes those words to the command as arguments unless
interactive comments are on. Run this once, then open a new terminal window:
`echo 'setopt interactivecomments' >> ~/.zshrc`. Also switch off **AirPlay Receiver**
(System Settings > General > AirDrop & Handoff): on a Mac it listens on port 5000, the port
your API uses from Lab 3 on. The setup check script flags both.

**Both: Ctrl+C stops a running host or AppHost.** On a Mac it is Control, not Command.

**Windows: paste file contents into VS Code, not Notepad.** Notepad's Markdown formatting
escapes what you paste (`\#`, `\-`, `\---`) and saves the escapes, which breaks CLAUDE.md
headings and the Lab 3 skill's frontmatter. If you must use Notepad, turn formatting off first.

```bash
mkdir helpdesk && cd helpdesk && git init -b main
```

Create `.gitignore` before anything builds, so the Step 4 commit never picks up `bin/` or
`obj/`:

**File: `.gitignore` (new file)**

```
bin/
obj/
.vs/
*.user
TestResults/
```

Create `docker-compose.yml`:

**File: `docker-compose.yml` (new file)**

```yaml
services:
  sql:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "Workshop!Passw0rd"
    ports:
      - "14330:1433"   # host port 14330: a locally installed SQL Server cannot shadow the container
```

Then start it (if this fails, do not panic: flag a helper at the break):

```bash
docker compose up -d   # SQL Server 2022; nothing uses it until Lab 3, so a failure here does not block Lab 1
```

Create `CLAUDE.md`:

**File: `CLAUDE.md` (new file)**

```markdown
# Helpdesk

Modular monolith on .NET 10. Modules live under src/Modules/<Name> with four projects:
Domain, Application, Infrastructure, Presentation. Composition root is Helpdesk.Host.

## Commands
- Build: dotnet build Helpdesk.slnx
- Test: dotnet test Helpdesk.slnx
- Run: dotnet run --project src/Helpdesk.Host

## Layer rules (enforced by tests in Helpdesk.ArchitectureTests)
- Domain references only Helpdesk.SharedKernel. No NuGet packages in Domain.
- Application references Domain. Infrastructure and Presentation reference Application.
- Only Host references Infrastructure. Modules never reference other modules' internals.

## Conventions
- Errors: return Result / Result<T> from SharedKernel. Never throw for business rule
  failures. Exceptions are for bugs and infrastructure faults only.
- Entities: private constructors, static factory methods returning Result<T>.
- Handlers: one command or query per file, handler beside it, internal visibility.
- Nullable enabled, warnings as errors, file-scoped namespaces.
- Never: add a NuGet package without asking; touch the database schema without a migration.

## Git
- Stay on the checked-out branch (main, unless the developer switched it). Do not create,
  switch, merge or delete branches.
- Do not commit or push. The developer commits after dotnet build and dotnet test pass.
- These Git rules win over any branch or pull-request workflow in a CLAUDE.md or AGENTS.md
  from a parent folder or from user settings.
```

Create `AGENTS.md` - the same rules under the name other tools look for. Codex, the GitHub
Copilot coding agent and Cursor read AGENTS.md (Gemini CLI when configured to); Claude Code
reads CLAUDE.md, and reads AGENTS.md itself only when there is no CLAUDE.md. One contract,
every agent. (In your own repo, the drift-proof version is one line in CLAUDE.md: `@AGENTS.md`.) Copy the body of CLAUDE.md below the preamble and keep the two in sync:

**File: `AGENTS.md` (new file)**

```markdown
# Helpdesk (agent instructions)

Kept identical to CLAUDE.md, rule for rule. Tools that read AGENTS.md (Codex, GitHub Copilot
coding agent, Cursor, and Gemini CLI when configured to) onboard from this file; Claude Code
reads CLAUDE.md. One set of rules, two file names, so every agent and every human starts from
the same contract.

Modular monolith on .NET 10. Modules live under src/Modules/<Name> with four projects:
Domain, Application, Infrastructure, Presentation. Composition root is Helpdesk.Host.

## Commands
- Build: dotnet build Helpdesk.slnx
- Test: dotnet test Helpdesk.slnx
- Run: dotnet run --project src/Helpdesk.Host

## Layer rules (enforced by tests in Helpdesk.ArchitectureTests)
- Domain references only Helpdesk.SharedKernel. No NuGet packages in Domain.
- Application references Domain. Infrastructure and Presentation reference Application.
- Only Host references Infrastructure. Modules never reference other modules' internals.

## Conventions
- Errors: return Result / Result<T> from SharedKernel. Never throw for business rule
  failures. Exceptions are for bugs and infrastructure faults only.
- Entities: private constructors, static factory methods returning Result<T>.
- Handlers: one command or query per file, handler beside it, internal visibility.
- Nullable enabled, warnings as errors, file-scoped namespaces.
- Never: add a NuGet package without asking; touch the database schema without a migration.

## Git
- Stay on the checked-out branch (main, unless the developer switched it). Do not create,
  switch, merge or delete branches.
- Do not commit or push. The developer commits after dotnet build and dotnet test pass.
- These Git rules win over any branch or pull-request workflow in a CLAUDE.md or AGENTS.md
  from a parent folder or from user settings.
```

Create `Directory.Build.props`:

**File: `Directory.Build.props` (new file)**

```xml
<Project>
  <PropertyGroup>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
```

## Step 2 (solo): the spec

This step is **spec-driven development**: requirements and design written down first, the agent
executes the spec, and the spec is what you review when the output looks wrong (GitHub Spec Kit
and AWS Kiro are the tools that formalise it; we do the lightweight version by hand).

Create `docs/lab1-spec.md`:

**File: `docs/lab1-spec.md` (new file)**

```markdown
Create the solution skeleton described in CLAUDE.md:
- Helpdesk.slnx at the root. Projects: src/Helpdesk.SharedKernel, src/Helpdesk.Host,
  src/Modules/Tickets/Helpdesk.Tickets.{Domain,Application,Infrastructure,Presentation},
  tests/Helpdesk.Tickets.Domain.Tests, tests/Helpdesk.ArchitectureTests.
- SharedKernel, Domain, Application: classlib. Infrastructure: classlib with
  Microsoft.EntityFrameworkCore.SqlServer. Presentation: classlib with a
  Microsoft.AspNetCore.App framework reference. Host: web project.
- Test projects use xUnit; ArchitectureTests also gets NetArchTest.Rules and references
  SharedKernel plus all four Tickets projects.
- Wire ONLY these project references: Domain -> SharedKernel; Application -> Domain;
  Infrastructure -> Application; Presentation -> Application; Host -> Presentation,
  Infrastructure; Domain.Tests -> Domain; ArchitectureTests as above.
- Each classlib gets one placeholder file ModuleInfo.cs in its root namespace:
  public static class ModuleInfo { public const string Name = "Tickets"; } (Name is
  "SharedKernel" in Helpdesk.SharedKernel). Each test project gets one PlaceholderTests.cs
  with a single xUnit fact asserting ModuleInfo.Name: Domain.Tests against
  Helpdesk.Tickets.Domain, ArchitectureTests against Helpdesk.SharedKernel. Delete each
  template's Class1.cs / UnitTest1.cs.
- Host: minimal API with a /health endpoint returning "OK".
- Everything must build with zero warnings (Directory.Build.props already sets
  TreatWarningsAsErrors).
```

Commit the context files and the spec now, so Step 3's scaffold shows up as its own diff to
review:

```bash
git add -A && git commit -m "Context files and spec"
```

## Step 3, AI path: plan-mode scaffold

Run `claude --permission-mode default` (new installs otherwise start in auto mode, and today
you want to see every permission prompt; in VS Code, pick Manual in the mode indicator), press
**Shift+Tab** until you are in plan mode, then type:

> Read CLAUDE.md and docs/lab1-spec.md, then scaffold the solution exactly as specified.

**Read the plan before approving it.** Reject anything you did not ask for (extra packages,
Dockerfiles, CI files) and say why. The spec names every project path and every allowed
reference, so check the plan's project paths and references against the spec (and the Target
structure and Dependency rule at the top of this page); if they differ, say so and let it
revise. Approve with **Yes, manually approve edits** (NOT the first option, "Yes,
and use auto mode", which switches the session to auto mode and the prompts stop). Then watch
the permission prompts: each one is a chance to catch a step you did not intend.

When it finishes, it may offer to commit or to create a branch (for example `lab1-scaffold`).
Say no: Lab 1 stays on `main`, and the commit is yours, in Step 4,
after the build and tests pass.

## Step 3, manual path (no Claude Code)

```bash
dotnet new sln -n Helpdesk     # the .NET 10 SDK writes Helpdesk.slnx (the XML format)

dotnet new classlib -n Helpdesk.SharedKernel -o src/Helpdesk.SharedKernel
dotnet new web      -n Helpdesk.Host         -o src/Helpdesk.Host
dotnet new classlib -n Helpdesk.Tickets.Domain         -o src/Modules/Tickets/Helpdesk.Tickets.Domain
dotnet new classlib -n Helpdesk.Tickets.Application    -o src/Modules/Tickets/Helpdesk.Tickets.Application
dotnet new classlib -n Helpdesk.Tickets.Infrastructure -o src/Modules/Tickets/Helpdesk.Tickets.Infrastructure
dotnet new classlib -n Helpdesk.Tickets.Presentation   -o src/Modules/Tickets/Helpdesk.Tickets.Presentation
dotnet new xunit    -n Helpdesk.Tickets.Domain.Tests   -o tests/Helpdesk.Tickets.Domain.Tests
dotnet new xunit    -n Helpdesk.ArchitectureTests      -o tests/Helpdesk.ArchitectureTests

dotnet sln add src/Helpdesk.SharedKernel src/Helpdesk.Host
dotnet sln add src/Modules/Tickets/Helpdesk.Tickets.Domain src/Modules/Tickets/Helpdesk.Tickets.Application
dotnet sln add src/Modules/Tickets/Helpdesk.Tickets.Infrastructure src/Modules/Tickets/Helpdesk.Tickets.Presentation
dotnet sln add tests/Helpdesk.Tickets.Domain.Tests tests/Helpdesk.ArchitectureTests

dotnet add src/Modules/Tickets/Helpdesk.Tickets.Domain         reference src/Helpdesk.SharedKernel
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Application    reference src/Modules/Tickets/Helpdesk.Tickets.Domain
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Infrastructure reference src/Modules/Tickets/Helpdesk.Tickets.Application
dotnet add src/Modules/Tickets/Helpdesk.Tickets.Presentation   reference src/Modules/Tickets/Helpdesk.Tickets.Application
dotnet add src/Helpdesk.Host reference src/Modules/Tickets/Helpdesk.Tickets.Presentation src/Modules/Tickets/Helpdesk.Tickets.Infrastructure
dotnet add tests/Helpdesk.Tickets.Domain.Tests reference src/Modules/Tickets/Helpdesk.Tickets.Domain
dotnet add tests/Helpdesk.ArchitectureTests reference src/Helpdesk.SharedKernel src/Modules/Tickets/Helpdesk.Tickets.Domain src/Modules/Tickets/Helpdesk.Tickets.Application src/Modules/Tickets/Helpdesk.Tickets.Infrastructure src/Modules/Tickets/Helpdesk.Tickets.Presentation

dotnet add src/Modules/Tickets/Helpdesk.Tickets.Infrastructure package Microsoft.EntityFrameworkCore.SqlServer
dotnet add tests/Helpdesk.ArchitectureTests package NetArchTest.Rules
```

Then by hand:

1. In `Helpdesk.Tickets.Presentation.csproj`, add inside an `<ItemGroup>`:
   `<FrameworkReference Include="Microsoft.AspNetCore.App" />`
2. Delete each template's `Class1.cs`/`UnitTest1.cs`. In each of the five class libraries add
   `ModuleInfo.cs` in its root namespace (Name is `"SharedKernel"` in Helpdesk.SharedKernel,
   `"Tickets"` in the four Tickets projects):

**File: `src/Helpdesk.SharedKernel/ModuleInfo.cs` (new file)**

```csharp
namespace Helpdesk.SharedKernel;

public static class ModuleInfo
{
    public const string Name = "SharedKernel";
}
```

**File: `src/Modules/Tickets/Helpdesk.Tickets.Domain/ModuleInfo.cs` (new file)**

```csharp
namespace Helpdesk.Tickets.Domain;

public static class ModuleInfo
{
    public const string Name = "Tickets";
}
```

**File: `src/Modules/Tickets/Helpdesk.Tickets.Application/ModuleInfo.cs` (new file)**

```csharp
namespace Helpdesk.Tickets.Application;

public static class ModuleInfo
{
    public const string Name = "Tickets";
}
```

**File: `src/Modules/Tickets/Helpdesk.Tickets.Infrastructure/ModuleInfo.cs` (new file)**

```csharp
namespace Helpdesk.Tickets.Infrastructure;

public static class ModuleInfo
{
    public const string Name = "Tickets";
}
```

**File: `src/Modules/Tickets/Helpdesk.Tickets.Presentation/ModuleInfo.cs` (new file)**

```csharp
namespace Helpdesk.Tickets.Presentation;

public static class ModuleInfo
{
    public const string Name = "Tickets";
}
```

Then in each test project add a `PlaceholderTests.cs` with one fact, so Step 4's `dotnet test`
runs two tests, not zero:

**File: `tests/Helpdesk.Tickets.Domain.Tests/PlaceholderTests.cs` (new file)**

```csharp
using Helpdesk.Tickets.Domain;

namespace Helpdesk.Tickets.Domain.Tests;

public class PlaceholderTests
{
    [Fact]
    public void Domain_module_is_named_Tickets()
    {
        Assert.Equal("Tickets", ModuleInfo.Name);
    }
}
```

**File: `tests/Helpdesk.ArchitectureTests/PlaceholderTests.cs` (new file)**

```csharp
using Helpdesk.SharedKernel;

namespace Helpdesk.ArchitectureTests;

public class PlaceholderTests
{
    [Fact]
    public void SharedKernel_is_reachable()
    {
        Assert.Equal("SharedKernel", ModuleInfo.Name);
    }
}
```

3. In `src/Helpdesk.Host/Program.cs`:

**File: `src/Helpdesk.Host/Program.cs` (edit)**

```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.MapGet("/health", () => "OK");
app.Run();
```

## Step 4: verify, then commit

```bash
dotnet build Helpdesk.slnx     # green, zero warnings, or you are not done
dotnet test Helpdesk.slnx      # placeholder tests pass
git add -A && git commit -m "Walking skeleton"
```

**The agent's claim is not the verification; the build is.**
