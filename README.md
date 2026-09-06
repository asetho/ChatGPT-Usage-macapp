# ChatGPT Usage

> **Unsigned community software:** these downloads are not publisher-signed, and the Mac app is not notarized by Apple. Your operating system may warn or block installation. This project provides no guarantee that a download is safe. Only proceed if you trust the source and have verified the file. Read [Unsigned installation and security warnings](UNSIGNED-INSTALL.txt) for the app-specific **Open Anyway** (Mac) and **More info → Run anyway** (Windows) steps. Do not disable system-wide security protections.

A lightweight macOS menu-bar app that shows the ChatGPT icon and the remaining percentage in the active five-hour Codex usage window. Click the menu-bar item for five-hour and weekly limits, reset times, available resets, extra model limits, token totals, refresh controls, and a direct link to the ChatGPT usage dashboard. Double-click the item to open the ChatGPT desktop app.

This is an unofficial local companion and is not distributed by OpenAI.

The app launches the locally installed `codex app-server` and reuses Codex's existing ChatGPT sign-in. It does not read, copy, or store authentication tokens.

## Installation and privacy

Download only from [this repository](https://github.com/asetho/ChatGPT-Usage-macapp). Compare the download with its matching `.sha256` file before opening it; instructions are in [UNSIGNED-INSTALL.txt](UNSIGNED-INSTALL.txt). A checksum detects a mismatch but is not a publisher signature or a malware check.

The app requires a working, signed-in Codex CLI for the same user account. Windows setup offers to install the official CLI if it cannot find one; signing in is a separate step. That option downloads and runs OpenAI's current installer over HTTPS, so its contents can change independently of this app. You can decline it and install Codex yourself. Only set `CODEX_EXECUTABLE` to a binary you trust.

See [Privacy](PRIVACY.md) for local data and subprocess behavior, and [Security](SECURITY.md) for reporting concerns. The app uses experimental Codex API capabilities; compatibility can change when Codex updates. Usage figures may be unavailable or stale and should be confirmed in the official dashboard.

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

The macOS command creates `dist/ChatGPTUsage-<version>.dmg`; the Windows command creates `Windows/dist/ChatGPTUsage-Setup-<version>.exe`. Each command also creates a matching `.sha256` file. The Windows build generates the executable and Start-menu icon from the same ChatGPT tray mark. Both remain unsigned community builds: no paid signing service or certificate is required by these scripts.

The installation warning is included in the DMG and displayed before Windows setup installs the app. Build scripts normally retain the three newest packages and their checksums. To preserve existing packages during local verification, use `KEEP_OLD_PACKAGES=1 scripts/build-macos-dmg.sh` or `scripts\build-windows-installer.ps1 -KeepOldPackages`.

Before publishing, follow the [release checklist](RELEASE-CHECKLIST.md). Building locally does not publish a release.

## License

The project source is available under the [MIT License](LICENSE). The license covers only material the copyright holder has authority to license; third-party names, trademarks, and artwork remain subject to their respective owners' rights.
