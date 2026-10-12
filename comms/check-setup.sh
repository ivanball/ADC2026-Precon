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
