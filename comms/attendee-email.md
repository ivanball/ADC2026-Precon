# Attendee pre-conference email

Send now (the two-week mark before Friday 2026-10-16 passed on 2026-10-02), resend the setup
portion on Tuesday 2026-10-13. Subject line and body below;
attach or link `check-setup.ps1` / `check-setup.sh` (in this folder).

---

**Subject:** Get ready for "Build an AI-Ready .NET App with an AI Pair" (30 minutes of setup now saves your morning)

Hi,

You are registered for the full-day precon workshop at Atlanta Developers Conference 2026.

**When and where:** Friday, October 16, 2026, at Improving, 11675 Rainwater Dr #100,
Alpharetta, GA 30009. Setup clinic 8:15 AM, sessions 9:00 AM to 5:00 PM.

It is hands-on from 9:15 onward: everything below needs to be installed and verified BEFORE
you arrive. Hotel and conference wifi are not the place to download SDKs and container
images.

## Install (about 30 minutes)

1. **.NET 10 SDK**: https://dotnet.microsoft.com/download
2. **Docker Desktop** (SQL Server runs as a container; you will not install SQL itself):
   https://www.docker.com/products/docker-desktop/
   If your company does not license Docker Desktop, another engine that provides the `docker`
   and `docker compose` commands may work (we have not tested every one): the check script
   below must report OK. On an Apple Silicon Mac, install Rosetta 2
   (`softwareupdate --install-rosetta`) and turn on Docker Desktop's Rosetta x86/amd64
   emulation setting: the SQL Server image is amd64 only.
3. **EF Core tools**: `dotnet tool install --global dotnet-ef`
4. **Git**, plus the **GitHub CLI** signed in (`gh auth login`): https://cli.github.com
   On Windows that means **Git for Windows**, which includes **Git Bash**: run the day's
   terminal commands there (Command Prompt cannot run them, PowerShell runs most of them).
5. A **GitHub account**. The repo you push in the afternoon will be PUBLIC, because
   branch protection with required checks is only free on public repositories.
6. **Aspire CLI 13.6 or newer and the Aspire templates**: install the CLI per https://aspire.dev
   (`irm https://aspire.dev/install.ps1 | iex` on Windows, `curl -sSL https://aspire.dev/install.sh | bash`
   on macOS/Linux), then `dotnet new install Aspire.ProjectTemplates`
7. **Node.js 22.19 or newer (Node 24 LTS recommended)**: https://nodejs.org (we run the MCP
   Inspector with `npx @modelcontextprotocol/inspector@latest`, which requires 22.19)
8. An IDE you like (Visual Studio, Rider, or VS Code)
9. **Claude Code** (CLI, or the VS Code / JetBrains extension), signed in - nice to have,
   see the next section: https://claude.com/claude-code (install: `irm https://claude.ai/install.ps1 | iex`
   on Windows, `curl -fsSL https://claude.ai/install.sh | bash` on macOS/Linux)
10. Optional, only for an extra you can try after the day: an **Azure subscription** and the
    **Azure CLI** (https://aka.ms/azcli). The Lab 6 handout has optional steps to deploy the
    app to Azure Container Apps with `aspire deploy`. No lab needs it, the instructor shows
    the deploy rather than the room running it, and the resources cost money while they
    exist. Do not try it on the conference wifi: one deploy takes about 16 minutes.

## Claude Code access: nice to have, not a prerequisite

The AI-pair portions of the labs move faster with a **Claude Pro, Max, Team or Enterprise
plan, or an Anthropic Console (API) account** (the free claude.ai plan does not include
Claude Code). Arrange one if you can. If you cannot, you lose nothing
from the day, so please do not skip the workshop over it.

Every lab handout includes a manual path with the same end state. The MCP lab works with
the free MCP Inspector or VS Code, and the evals lab has a follow-along path. The
architecture content is the curriculum, the AI is the accelerator.

## One-time settings for your OS (2 minutes)

The day's terminal commands are printed once, for bash, and run as printed on both a Mac and
a Windows laptop with these settings:

- **Both:** trust the HTTPS development certificate, `dotnet dev-certs https --trust`
  (Windows shows a security dialog: answer Yes; macOS asks for your login password). The
  Lab 6 dashboard runs on `https://localhost`.
- **Windows:** run the day's commands in **Git Bash** (it comes with Git for Windows; open it
  from the Start menu, or pick it as a Windows Terminal or VS Code terminal profile).
- **macOS:** the stock Terminal (zsh) is fine, with two settings. Some commands end in a
  `# comment`, which zsh passes to the command as arguments unless you run
  `echo 'setopt interactivecomments' >> ~/.zshrc` once and open a new terminal. And port
  5000, the port the workshop API uses, belongs to AirPlay Receiver on a Mac: turn it off in
  System Settings > General > AirDrop & Handoff > AirPlay Receiver. If `dotnet ef` says
  "command not found" after you installed it, run
  `echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile` and open a new terminal.

## Pre-pull the database image (5 minutes, saves the room's wifi)

```
docker pull mcr.microsoft.com/mssql/server:2022-latest
```

## Verify your setup (2 minutes)

Run the attached check script and make sure every line says OK:

- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .\check-setup.ps1`
- macOS/Linux: `bash check-setup.sh`

If anything fails and you cannot fix it, come to the **setup clinic at 8:15** (the workshop
starts at 9:00 sharp) and we will sort it out together.

## What to bring

- Your laptop and charger (there is power at every seat).
- Nothing else to install: we build the day's system from an empty folder, and there is no
  required reading.
- Two clones before you arrive, both into the folder you will build the day's repository in,
  so they sit side by side with it:
  - The workshop reference repo, https://github.com/ivanball/adc2026-helpdesk (public), holds
    the snapshot (rescue) branch for every lab (`lab1-end` to `lab7-end`, plus `main`), so if
    you fall behind you can continue from the current lab's branch without the room's wifi.

    ```
    git clone https://github.com/ivanball/adc2026-helpdesk.git
    ```
  - The starter kit, https://github.com/ivanball/agentic-dotnet-starter-kit (public, MIT): the
    take-home templates, and the source of three files Lab 8 copies into your repository.

    ```
    git clone https://github.com/ivanball/agentic-dotnet-starter-kit.git
    ```

See you there,
Ivan

---

## check-setup.ps1 (attach as file)

**File: `comms/check-setup.ps1` (new file)**

```powershell
$ErrorActionPreference = "SilentlyContinue"
function Check($name, $ok, $hint) {
  if ($ok) { Write-Host "OK      $name" -ForegroundColor Green }
  else     { Write-Host "MISSING $name  -> $hint" -ForegroundColor Red }
}
function Soft($name, $ok, $hint) {
  if ($ok) { Write-Host "OK      $name" -ForegroundColor Green }
  else     { Write-Host "WARN    $name  -> $hint" -ForegroundColor Yellow }
}

$dotnet = (dotnet --list-sdks | Where-Object { $_ -match '^10\.' } | Select-Object -Last 1)
if ($null -ne $dotnet) { $dotnet = ($dotnet -split ' ')[0] }
Check ".NET SDK 10.x         (found: $dotnet)" ($null -ne $dotnet) "install the .NET 10 SDK"

$docker = (docker --version)
$dockerUp = $false
if ($null -ne $docker) { docker info 2>&1 | Out-Null; $dockerUp = ($LASTEXITCODE -eq 0) }
Check "Docker running        ($docker)" $dockerUp "install Docker Desktop and start it (docker info must succeed)"

$sqlimg = (docker images --format "{{.Repository}}:{{.Tag}}" 2>$null | Select-String "mssql/server:2022-latest")
Check "SQL Server image pulled" ($null -ne $sqlimg) "docker pull mcr.microsoft.com/mssql/server:2022-latest"

$port14330 = Get-NetTCPConnection -LocalPort 14330 -State Listen -ErrorAction SilentlyContinue |
  Where-Object { (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName -notmatch 'docker|vpnkit|wslrelay' }
$reserved = netsh interface ipv4 show excludedportrange protocol=tcp |
  Where-Object { $_ -match '^\s*(\d+)\s+(\d+)' -and [int]$Matches[1] -le 14330 -and [int]$Matches[2] -ge 14330 }
Check "Port 14330 free for the workshop container" (($null -eq $port14330) -and ($null -eq $reserved)) 'something already listens on host port 14330, or Windows reserved it (netsh interface ipv4 show excludedportrange protocol=tcp). Stop it, or change the "14330:1433" mapping in docker-compose.yml and Server=localhost,14330 in the connection string to another free port'

$port5000 = Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue
$reserved5000 = netsh interface ipv4 show excludedportrange protocol=tcp |
  Where-Object { $_ -match '^\s*(\d+)\s+(\d+)' -and [int]$Matches[1] -le 5000 -and [int]$Matches[2] -ge 5000 }
Check "Port 5000 free for the workshop API" (($null -eq $port5000) -and ($null -eq $reserved5000)) 'something already listens on port 5000 (the port the workshop API uses from Lab 3 on), or Windows reserved it (netsh interface ipv4 show excludedportrange protocol=tcp). Stop it before the workshop'

dotnet dev-certs https --check --trust 2>&1 | Out-Null
Check "HTTPS dev certificate trusted" ($LASTEXITCODE -eq 0) "dotnet dev-certs https --trust (answer Yes in the Windows security dialog); the Lab 6 Aspire dashboard runs on https://localhost"

$ef = (dotnet ef --version 2>$null | Select-Object -Last 1)
$efOk = ($null -ne $ef) -and ($LASTEXITCODE -eq 0)
if (-not $efOk) { $ef = $null }
Check "EF Core tools         (found: $ef)" $efOk "dotnet tool install --global dotnet-ef"

$git = (git --version)
Check "Git                   ($git)" ($null -ne $git) "install Git"

# The day's commands are printed for bash: on Windows they run in Git Bash, which ships with Git for Windows.
$gitBash = $false
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($null -ne $gitCmd) { $gitBash = Test-Path (Join-Path (Split-Path (Split-Path $gitCmd.Source)) "bin\bash.exe") }
Check "Git Bash (runs the day's terminal commands)" $gitBash "install Git for Windows from git-scm.com, which includes Git Bash"

$gh = (gh --version | Select-Object -First 1)
Check "GitHub CLI            ($gh)" ($null -ne $gh) "install the GitHub CLI from cli.github.com"

$ghauth = $false
if ($null -ne $gh) { gh auth status 2>&1 | Out-Null; $ghauth = ($LASTEXITCODE -eq 0) }
Check "GitHub CLI signed in" $ghauth "gh auth login. The workshop repo you push will be PUBLIC, so branch protection works on the free plan"

$aspire = (aspire --version | Select-Object -First 1)
$aspireAgent = $false
if ($aspire -match '^(\d+)\.(\d+)') { $aspireAgent = ([int]$Matches[1] -gt 13) -or ([int]$Matches[1] -eq 13 -and [int]$Matches[2] -ge 6) }
Check "Aspire CLI 13.6+ with agent commands (found: $aspire)" $aspireAgent "install or update the Aspire CLI per aspire.dev (13.6 or newer: Lab 6 pins Aspire 13.6.0 and uses aspire agent mcp)"

$aspiretpl = (dotnet new list aspire 2>$null | Select-String "aspire-apphost")
Check "Aspire templates installed" ($null -ne $aspiretpl) "dotnet new install Aspire.ProjectTemplates"

$node = (node --version)
$nodeOk = $false
if ($node -match '^v(\d+)\.(\d+)') { $nodeOk = ([int]$Matches[1] -gt 22) -or ([int]$Matches[1] -eq 22 -and [int]$Matches[2] -ge 19) }
Check "Node.js 22.19+        (found: $node)" $nodeOk "install Node.js 22.19 or newer (24 LTS recommended); Lab 7 runs npx @modelcontextprotocol/inspector@latest"

$ide = $null
foreach ($exe in @("devenv", "rider64", "rider", "code")) {
  if ($null -ne (Get-Command $exe -ErrorAction SilentlyContinue)) { $ide = $exe; break }
}
if ($null -eq $ide) {
  foreach ($p in @("$env:ProgramFiles\Microsoft Visual Studio\*\*\Common7\IDE\devenv.exe", "$env:ProgramFiles\JetBrains\JetBrains Rider*", "$env:LOCALAPPDATA\Programs\Microsoft VS Code")) {
    if (Test-Path $p) { $ide = $p; break }
  }
}
Soft "IDE: VS, Rider, or VS Code (found: $ide)" ($null -ne $ide) "install Visual Studio, Rider, or VS Code. Warning only: any one of them is fine, and we can sort this out in the room"

$claude = (claude --version)
Soft "Claude Code           (found: $claude)" ($null -ne $claude) "nice to have, not required: every lab has a manual path"
```

## check-setup.sh (attach as file)

**File: `comms/check-setup.sh` (new file)**

```bash
#!/usr/bin/env bash
check() {
  if [ -n "$2" ]; then printf 'OK      %s\n' "$1"
  else printf 'MISSING %s  -> %s\n' "$1" "$3"; fi
}
soft() {
  if [ -n "$2" ]; then printf 'OK      %s\n' "$1"
  else printf 'WARN    %s  -> %s\n' "$1" "$3"; fi
}
# ver_ge VERSION MAJOR MINOR: true when VERSION (v22.19.0, 13.6.0+abc) is MAJOR.MINOR or newer
ver_ge() {
  v=${1#v}; maj=${v%%.*}; min=${v#*.}; min=${min%%[!0-9]*}
  case "$maj" in ''|*[!0-9]*) return 1 ;; esac
  case "$min" in ''|*[!0-9]*) return 1 ;; esac
  [ "$maj" -gt "$2" ] || { [ "$maj" -eq "$2" ] && [ "$min" -ge "$3" ]; }
}

os=$(uname -s)

# The day's commands are printed for bash and some end in "# comment". macOS Terminal runs zsh,
# which passes those words to the command as arguments unless interactivecomments is set.
case "${SHELL:-}" in
  */zsh)
    zsh_comments=""
    if zsh -ic '[[ -o interactivecomments ]]' </dev/null >/dev/null 2>&1; then zsh_comments="yes"; fi
    check "zsh accepts # comments in pasted commands" "$zsh_comments" "echo 'setopt interactivecomments' >> ~/.zshrc, then open a new terminal"
    ;;
esac

if [ "$os" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
  rosetta=""
  if [ -e /Library/Apple/usr/share/rosetta/rosetta ] || /usr/bin/pgrep -q oahd 2>/dev/null; then rosetta="yes"; fi
  check "Rosetta 2 (Apple Silicon; the SQL Server image is amd64 only)" "$rosetta" "softwareupdate --install-rosetta --agree-to-license, then in Docker Desktop Settings > General turn on 'Use Rosetta for x86_64/amd64 emulation on Apple Silicon'"
fi

dotnet_v=$(dotnet --list-sdks 2>/dev/null | grep '^10\.' | tail -1)
check ".NET SDK 10.x" "$dotnet_v" "install the .NET 10 SDK"

docker_v=""
if docker info >/dev/null 2>&1; then docker_v=$(docker --version 2>/dev/null); fi
check "Docker running" "$docker_v" "install Docker Desktop and start it (docker info must succeed)"

sql_img=$(docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null | grep 'mssql/server:2022-latest')
check "SQL Server image pulled" "$sql_img" "docker pull mcr.microsoft.com/mssql/server:2022-latest"

if command -v lsof >/dev/null 2>&1; then
  port_busy=$(lsof -nP -iTCP:14330 -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $1}' | grep -vi dock)
elif (exec 3<>/dev/tcp/127.0.0.1/14330) 2>/dev/null; then
  port_busy="listener"
else
  port_busy=""
fi
if [ -z "$port_busy" ]; then port_free="yes"; else port_free=""; fi
check "Port 14330 free for the workshop container" "$port_free" 'something already listens on host port 14330. Stop it, or change the "14330:1433" mapping in docker-compose.yml and Server=localhost,14330 in the connection string to another free port'

if command -v lsof >/dev/null 2>&1; then
  api_port_busy=$(lsof -nP -iTCP:5000 -sTCP:LISTEN 2>/dev/null | awk 'NR>1 {print $1}' | sort -u | tr '\n' ' ')
elif (exec 3<>/dev/tcp/127.0.0.1/5000) 2>/dev/null; then
  api_port_busy="listener"
else
  api_port_busy=""
fi
if [ -z "$api_port_busy" ]; then api_port_free="yes"; else api_port_free=""; fi
api_port_hint="something already listens on port 5000 ($api_port_busy), the port the workshop API uses from Lab 3 on. Stop it"
if [ "$os" = "Darwin" ]; then
  api_port_hint="$api_port_hint. On a Mac it is usually AirPlay Receiver (ControlCenter): System Settings > General > AirDrop & Handoff > AirPlay Receiver off"
fi
check "Port 5000 free for the workshop API" "$api_port_free" "$api_port_hint"

ef_v=$(dotnet ef --version 2>/dev/null) || ef_v=""
ef_hint="dotnet tool install --global dotnet-ef"
if [ -z "$ef_v" ] && [ -e "$HOME/.dotnet/tools/dotnet-ef" ]; then
  ef_hint="installed but not on PATH: echo 'export PATH=\"\$PATH:\$HOME/.dotnet/tools\"' >> ~/.zprofile (bash: ~/.bash_profile), then open a new terminal"
fi
check "EF Core tools" "$ef_v" "$ef_hint"

devcert=""
if dotnet dev-certs https --check --trust >/dev/null 2>&1; then devcert="yes"; fi
if [ "$os" = "Darwin" ]; then
  check "HTTPS dev certificate trusted" "$devcert" "dotnet dev-certs https --trust (macOS asks for your login password); the Lab 6 Aspire dashboard runs on https://localhost"
else
  soft "HTTPS dev certificate trusted" "$devcert" "dotnet dev-certs https --trust; the Lab 6 Aspire dashboard runs on https://localhost"
fi

git_v=$(git --version 2>/dev/null)
check "Git" "$git_v" "install Git"

gh_v=$(gh --version 2>/dev/null | head -1)
check "GitHub CLI" "$gh_v" "install the GitHub CLI from cli.github.com"

gh_auth=""
if [ -n "$gh_v" ] && gh auth status >/dev/null 2>&1; then gh_auth="yes"; fi
check "GitHub CLI signed in" "$gh_auth" "gh auth login. The workshop repo you push will be PUBLIC, so branch protection works on the free plan"

aspire_v=$(aspire --version 2>/dev/null | head -1)
aspire_agent=""
if ver_ge "$aspire_v" 13 6; then aspire_agent="$aspire_v"; fi
check "Aspire CLI 13.6+ with agent commands" "$aspire_agent" "install or update the Aspire CLI per aspire.dev (13.6 or newer: Lab 6 pins Aspire 13.6.0 and uses aspire agent mcp)"

aspire_tpl=$(dotnet new list aspire 2>/dev/null | grep aspire-apphost)
check "Aspire templates installed" "$aspire_tpl" "dotnet new install Aspire.ProjectTemplates"

node_v=$(node --version 2>/dev/null)
node_ok=""
if ver_ge "$node_v" 22 19; then node_ok="$node_v"; fi
check "Node.js 22.19+" "$node_ok" "install Node.js 22.19 or newer (24 LTS recommended); Lab 7 runs npx @modelcontextprotocol/inspector@latest"

ide=""
for exe in devenv rider64 rider code; do
  if command -v "$exe" >/dev/null 2>&1; then ide="$exe"; break; fi
done
if [ -z "$ide" ]; then
  for p in "/Applications/Rider.app" "/Applications/Visual Studio Code.app" "$HOME/Applications/Rider.app" "/usr/share/code"; do
    if [ -e "$p" ]; then ide="$p"; break; fi
  done
fi
soft "IDE: VS, Rider, or VS Code" "$ide" "install Visual Studio, Rider, or VS Code. Warning only: any one of them is fine, and we can sort this out in the room"

claude_v=$(claude --version 2>/dev/null)
soft "Claude Code" "$claude_v" "nice to have, not required: every lab has a manual path"
```
