# Workshop A setup addendum email: Mac and Windows (draft, 2026-10-12)

Send only if the 2026-10-10 welcome email already went out (the welcome draft now carries the
same section). Same BCC list as `welcome-email-workshop-a-2026-10-10.md`. Send it after the
starter kit's `fix/mac-and-windows-setup-checks` branch is merged, so `git pull` brings the
updated checker.

---

**Subject:** Friday's workshop: three 2-minute settings for your Mac or Windows laptop

Hi everyone,

One short addition to the setup list, so every command on Friday runs as printed whether
you bring a Mac or a Windows laptop.

**Both:** trust the HTTPS development certificate (the Aspire dashboard in the afternoon
runs on https://localhost):

```
dotnet dev-certs https --trust
```

Windows shows a security dialog (answer Yes); macOS asks for your login password.

**Windows:** run the day's terminal commands in **Git Bash** (it comes with Git for Windows;
open it from the Start menu, or pick it as a Windows Terminal or VS Code terminal profile).

**macOS:** the stock Terminal is fine, with two settings:

1. Some commands end in a `# comment`, and zsh, the Mac's default shell, passes those words
   to the command unless you turn on interactive comments. Run this once, then open a new
   terminal window:

   ```
   echo 'setopt interactivecomments' >> ~/.zshrc
   ```

2. Turn off **AirPlay Receiver** (System Settings > General > AirDrop & Handoff). On a Mac it
   listens on port 5000, which is the port our API uses from late morning on.

If `dotnet ef` says "command not found" on your Mac after you installed it, run
`echo 'export PATH="$PATH:$HOME/.dotnet/tools"' >> ~/.zprofile` and open a new terminal.

Then re-run the setup checker from your starter-kit clone (`git pull` first, it has new
checks for all of this):

- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File .\setup\check-setup.ps1`
- macOS: `bash setup/check-setup.sh`

Every line should say OK. Anything stubborn, reply here or come to the setup clinic at 8:15.

See you Friday,

Ivan Ball-llovera
https://ivanball.github.io/
