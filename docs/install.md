# Install

## Homebrew

```bash
brew tap li-nd/apps
brew trust li-nd/apps
brew install --cask zeroaway
```

Tap: [li-nd/homebrew-apps](https://github.com/li-nd/homebrew-apps). Or download a zip from [GitHub Releases](https://github.com/li-nd/ZeroAway/releases).

> Builds are **not notarized** (ad-hoc signed). If macOS blocks the app: **System Settings → Privacy & Security → Open Anyway**, or right-click → **Open**.

## Requirements

- A recent macOS (Apple Silicon or Intel).
- **Accessibility** permission for ZeroAway (required to reset system idle).

## Accessibility (required)

ZeroAway must be allowed in **System Settings → Privacy & Security → Accessibility**. Without it, the app cannot reset system idle.

When access is missing, the menu bar shows an access gate:

![Accessibility required in menu bar](screenshots/18-accessibility.png)

Use **Open Settings…**, enable ZeroAway in the Accessibility list, then **Check again**.  
You can also fix this from **Settings → System**:

![System — Accessibility needed](screenshots/19-accessibility-settings.png)

When access is granted, System shows a green status:

![System — Accessibility allowed](screenshots/17-system.png)

## Build from source

1. Clone the repository:
   ```bash
   git clone https://github.com/li-nd/ZeroAway.git
   cd ZeroAway
   ```
2. Open `ZeroAway.xcodeproj` in Xcode.
3. Select the **ZeroAway** scheme and run (`⌘R`).

The app appears in the menu bar (no Dock icon by design).

## Next steps

- [Menu bar & sessions](menu-bar.md) — turn on a session  
- [Troubleshooting](troubleshooting.md) — if idle still isn’t reset  
