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
