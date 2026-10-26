# RunCatter

**A cute running cat animation on your macOS menubar — with a RAM fill gauge.**

[![Issues](https://img.shields.io/github/issues/gmu-d/RunCatter)](https://github.com/gmu-d/RunCatter/issues)
[![Forks](https://img.shields.io/github/forks/gmu-d/RunCatter)](https://github.com/gmu-d/RunCatter/network/members)
[![Stars](https://img.shields.io/github/stars/gmu-d/RunCatter)](https://github.com/gmu-d/RunCatter/stargazers)
[![Top language](https://img.shields.io/github/languages/top/gmu-d/RunCatter)](https://github.com/gmu-d/RunCatter/)
[![License](https://img.shields.io/github/license/gmu-d/RunCatter)](https://github.com/gmu-d/RunCatter/)

`Swift` `macOS` `Xcode`

## About This Fork

RunCatter is a **fork of [RunCat Neo](https://github.com/runcat-dev/RunCatNeo)** by [Kyome22](https://github.com/Kyome22), a macOS menu-bar app that animates a running cat reflecting CPU load.

**What this fork adds:**

- **RAM usage visualization** — the menu-bar cat fills up from the bottom as RAM usage rises, colored by load zone.
- Configurable load thresholds and per-zone colors, edited in Runner Settings.
- Rebranded as a standalone project ("RunCatter") with its own bundle identity; removed the in-app donation/IAP flow.

Thanks to the original author and all RunCat Neo contributors — this project exists because of their excellent work.

## Legal & Non-Commercial Notice

- This project is licensed under the **Apache License 2.0** (see [LICENSE](LICENSE)). The original upstream copyright notice is retained as the license requires.
- Modifications relative to upstream are listed above; this fork is a separate project and is **not affiliated with, endorsed by, or sponsored by the original developer**. "RunCat" and its logos/assets belong to their respective owners; visual assets retained under the terms of the license.
- This is a **hobby project made for fun**. It has **no commercial purpose**, generates no revenue, and is not distributed on the App Store.
- Developed largely with **AI assistance using [OpenCode](https://github.com/sst/opencode) and GLM** — every change was reviewed and tested by the maintainer.
- The software is provided "as is", without warranty of any kind, as stated in the license.

## Requirements

- Development with Xcode 26.5+
- Compatible with macOS 26.3+
- Written in Swift 6.2

## Architecture

This project is built using an architecture called [LUCA](https://github.com/Kyome22/LUCA).
Please refer to the following article for more details.

https://dev.to/kyome22/luca-a-modern-architecture-for-swiftui-development-3g2i

## Custom Metrics

RunCatter can watch any local JSON file in the documented format and render it as a card on the dashboard. Use it to display Claude Code usage, GPU temperature, GitHub contributions, remaining reminders, or anything else you can write to a file.

- [JSON schema](docs/CustomMetricsSchema.md)
- [Claude Code statusLine sample](docs/samples/claude-code/)
- [Codex integration sample](docs/samples/codex/)
- [Bitcoin price sample](docs/samples/bitcoin/)

## Custom Runners

By creating your own keyframe animations, you can have any runner you like dashing across your menu bar.

Runners are managed outside of this repository. If you want to share one you made, please fork this repository or manage it locally from Runner Settings.
