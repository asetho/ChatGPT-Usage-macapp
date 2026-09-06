# Privacy

ChatGPT Usage is an unofficial local companion. The app itself does not read, copy, or save authentication tokens. It launches the Codex CLI under your user account and requests account rate limits and token-usage summaries through private standard-input/output pipes. The CLI receives the app's inherited environment and uses its own sign-in, configuration, network connections, storage, and logging; this document does not make guarantees about that separate software.

The app keeps the returned usage snapshot and error state in memory and displays them in its menu bar, tray, widget, or window. It has no app-owned telemetry endpoint, account database, or usage export feature. Usage information is visible to anyone who can see your desktop or screenshots. On Mac, a CLI failure may show a limited excerpt of that process's error output.

Opening the usage dashboard opens `https://chatgpt.com/codex/settings/usage` in your browser. Sign-in, purchases, and reset actions there are handled by the external site; this app does not perform them automatically.

Windows setup offers an optional Codex CLI installation. It downloads and executes OpenAI's current HTTPS installer, which can change independently of this app. Setup records its output at `%LOCALAPPDATA%\Temp\ChatGPTUsage-CodexInstall.log`. The log is deleted after installation succeeds and the CLI is found, but kept for troubleshooting on failure. Its contents depend on the external installer. Review and redact logs before sharing them; never include tokens, passwords, account identifiers, or other private information in a public issue.

Windows setup installs the companion per user and adds a per-user startup entry, removed by the uninstaller. Uninstalling the companion does not remove the separately installed Codex CLI, its sign-in state, or a retained failure log. Use the CLI's own documented account/removal workflow if you also want to remove it.
