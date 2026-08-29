<p align="center">
  <img src="docs/logo.png" alt="ZeroAway" width="160" />
</p>

<h1 align="center">ZeroAway</h1>

<p align="center">
  <strong>Reset system idle. Stay available.</strong><br />
  Native macOS menu bar app — nudge the cursor when idle so Slack, Teams, and similar apps don’t mark you away.
</p>

<p align="center">
  <a href="https://zeroaway.developer.pm/">Documentation</a> ·
  <a href="https://zeroaway.developer.pm/install/">Install</a> ·
  <a href="https://github.com/li-nd/ZeroAway/issues">Issues</a> ·
  <a href="#build">Build</a>
</p>

---

<p align="center">
  <img src="docs/social.png" alt="ZeroAway — menu bar sessions, Tracked Apps, Behavior, Statistics, Icons" width="900" />
</p>

## Features

| | |
|---|---|
| **Sessions** | On/Off from the menu bar · Always (∞) or 1h / 4h / 8h with countdown |
| **Behavior** | Idle timeout · cursor nudge · schedule & tracked-app gates · resume on launch |
| **Tracked Apps** | Track Slack, Teams, Mattermost, or any app by Bundle ID |
| **Schedule** | Work days and hours · timed sessions ignore the schedule |
| **Icons** | Role-based presets · online catalog · export / import / contribute via PR |
| **Statistics** | Optional local nudge & session history — nothing leaves this Mac |

## Screenshots

<table>
  <tr>
    <td width="50%" valign="top">
      <img src="docs/screenshots/7-tracked-apps.png" alt="Tracked Apps" /><br />
      <sub><b>Tracked Apps</b> — Slack, Teams, Mattermost, or any Bundle ID</sub>
    </td>
    <td width="50%" valign="top">
      <img src="docs/screenshots/13-icons-presets.png" alt="Icon presets" /><br />
      <sub><b>Icons</b> — role-based presets and catalog</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="docs/screenshots/6-behavior.png" alt="Behavior" /><br />
      <sub><b>Behavior</b> — idle timeout, nudge, schedule &amp; app gates</sub>
    </td>
    <td width="50%" valign="top">
      <img src="docs/screenshots/16-statistics.png" alt="Statistics" /><br />
      <sub><b>Statistics</b> — local history, stays on your Mac</sub>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <img src="docs/screenshots/10-schedule-always.png" alt="Schedule" /><br />
      <sub><b>Schedule</b> — always on, or work days &amp; hours</sub>
    </td>
    <td width="50%" valign="top">
      <img src="docs/screenshots/15-icons-edit.png" alt="Preset editor" /><br />
      <sub><b>Preset editor</b> — icons per Active / Paused / Waiting / Alert</sub>
    </td>
  </tr>
</table>

## Install

```bash
brew tap li-nd/apps
brew trust li-nd/apps
brew install --cask zeroaway
```

Tap: [li-nd/homebrew-apps](https://github.com/li-nd/homebrew-apps). Or download a zip from [Releases](https://github.com/li-nd/ZeroAway/releases). Full notes: **[Install guide](https://zeroaway.developer.pm/install/)**.

> Builds are **not notarized** (ad-hoc signed). If macOS blocks the app: **System Settings → Privacy & Security → Open Anyway**, or right-click → **Open**.

**Accessibility** is required (see [Install](https://zeroaway.developer.pm/install/)) — allow ZeroAway under Privacy & Security → Accessibility, then **Check again** in the app.

## Build

1. Open `ZeroAway.xcodeproj` in Xcode.
2. Select the **ZeroAway** scheme and run (`⌘R`).

## Documentation

Published site: **[zeroaway.developer.pm](https://zeroaway.developer.pm/)**

| Page | Topic |
|------|--------|
| [Install](https://zeroaway.developer.pm/install/) | Homebrew, Releases, build from source |
| [Menu bar](https://zeroaway.developer.pm/menu-bar/) | Sessions and status |
| [Behavior](https://zeroaway.developer.pm/behavior/) | Idle, nudge, gates |
| [Tracked Apps](https://zeroaway.developer.pm/tracked-apps/) | Tracked apps |
| [Schedule](https://zeroaway.developer.pm/schedule/) | Work hours |
| [Icons](https://zeroaway.developer.pm/icons/) | Catalog, sharing, PRs |
| [Statistics](https://zeroaway.developer.pm/statistics/) | Local history |
| [System](https://zeroaway.developer.pm/system/) | Language, hotkey, access |
| [Troubleshooting](https://zeroaway.developer.pm/troubleshooting/) | Common issues |

### Preview docs locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-docs.txt
mkdocs serve
```

Pages deploy from `main` via [`.github/workflows/pages.yml`](.github/workflows/pages.yml) (MkDocs site + presets catalog in one publish).

## License

[MIT](LICENSE) © [Markus Lind](https://github.com/li-nd)
