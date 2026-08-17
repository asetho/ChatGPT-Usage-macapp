# ChatGPT Usage

A lightweight macOS menu-bar app that shows the ChatGPT icon and the remaining percentage in the active five-hour Codex usage window. Click the menu-bar item for five-hour and weekly limits, reset times, available resets, extra model limits, token totals, refresh controls, and a direct link to the ChatGPT usage dashboard. Double-click the item to open the ChatGPT desktop app.

This is an unofficial local companion and is not distributed by OpenAI.

The app launches the locally installed `codex app-server` and reuses Codex's existing ChatGPT sign-in. It does not read, copy, or store authentication tokens.

## Build

```sh
xcodegen generate
xcodebuild -project CodexUsage.xcodeproj -scheme CodexUsage -configuration Release -destination 'platform=macOS' build
```

Requires macOS 13 or newer and a signed-in Codex CLI or ChatGPT desktop app.

## Versioning and installers

`VERSION` is the release version for both platforms. Update that file before a release, then build the platform artifact:

```sh
scripts/build-macos-dmg.sh
```

```powershell
scripts\build-windows-installer.ps1
```

The macOS command creates `dist/ChatGPTUsage-<version>.dmg`; the Windows command creates `Windows/dist/ChatGPTUsage-Setup-<version>.exe`. The Windows build also generates the executable and Start-menu icon from the same ChatGPT tray mark. Both are unsigned local builds and may prompt for confirmation on another machine.
