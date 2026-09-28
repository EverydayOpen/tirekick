# Tirekick: notes for coding agents

Tirekick is a free, open-source (MIT), offline macOS app (Swift/SwiftUI, macOS 13+, Swift 5 language mode, not
sandboxed, hardened runtime, Developer ID) that checks a used Mac before you pay: Activation Lock, MDM and company
assignment, battery, SSD, specs, macOS updates, guided hardware tests and a shareable report card.

Read [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) first. It is the contract: public API names, file ownership (§9),
safety rules (§3), UI rules (§7) and copy (§8). Going live: [docs/GO_LIVE.md](docs/GO_LIVE.md),
[docs/RELEASING.md](docs/RELEASING.md).

## Be honest about what has run

- Only `TirekickCore` has been compiled and tested (Linux, in Docker). `TirekickMac`, `App/` and the release workflow
  have never been compiled or run. **Never claim Mac or App code builds or works unless a CI run shows it.** Say
  "written, not compiled".
- Don't invent APIs, flags or command output. Check Apple's docs or real published output; mark anything you couldn't
  verify with `VERIFY`. If you're unsure an API exists on macOS 13, don't use it, or put it in
  `App/DesignSystem/Compat.swift` behind `if #available`.
- macOS 13 means `ObservableObject`, `@Published` and `@StateObject`; never `@Observable` or `@Bindable`.

## Test

```sh
bash tools/test_core_docker.sh          # Core build + tests in Docker (Windows Git Bash too); must pass with no warnings
swift test                              # on a Mac: Core and Mac tests
python tools/changelog.py --self-test   # changelog parser and markdown renderer
python tools/build_site.py --check      # website build: links, meta tags, contrast, placeholders
bash tools/doctor.sh                    # what's configured and what's left before go-live
```

CI (`.github/workflows/ci.yml`) runs all of these, the universal app build on macOS, and the safety greps below.
Real command output for Core tests comes from `.github/workflows/fixtures.yml` (GitHub's arm64 and Intel runners) and
from testers' Help › Copy Raw Data text. Parsers are tested against every fixture in `Tests/TirekickCoreTests/Fixtures`.

## Safety rules (BUILD_PLAN §3; CI greps enforce them)

- **Read-only.** Never `removeItem`, `trashItem`, `unlink`, `rmdir`, `moveItem` or `replaceItem`. No writes
  (`.write(to:`, `createFile`, `FileHandle(forWriting`, `createDirectory`) anywhere except `App/Export.swift`, which
  saves a report the user chose through `NSSavePanel`. No `UserDefaults`, `@AppStorage` or `@SceneStorage`: v1 has
  zero settings. Never change a setting, sign anyone out or erase anything; deep links only.
- **No shell.** `Process()` only in `Sources/TirekickMac/Platform/ProcessRunner.swift`; `ProcessRunner` is internal to
  `TirekickMac`, and `ProcessRunner.run` is called only in `Sources/TirekickMac/Collector.swift`; `Command` values only
  in `Sources/TirekickCore/Model/Evidence.swift`. The only executables are `/usr/sbin/system_profiler`,
  `/usr/sbin/ioreg`, `/usr/sbin/sysctl`, and `/usr/bin/profiles` and `/usr/bin/fdesetup` with `status` as the first
  argument. No `/bin/sh`, `/usr/bin/env`, AppleScript, `NSTask`, `Process.run`, `system()`, `popen()`, `posix_spawn()`
  or `exec*()`. The app contains no privileged code: admin rights are typed into Terminal, never into
  Tirekick.
- **No network.** No `URLSession`, Network framework, `CFStream`, `NSURLConnection` or web views. Links open in the
  user's browser only when clicked. No Sparkle.
- **Never help bypass MDM or Activation Lock.** No copy, link or code that removes, hides or works around either.
- **Findings, not guarantees.** Every check shows its command and raw output. "Walk away" only for Activation Lock on,
  DEP or MDM enrolled, an organization found, SMART failing. Never "certified", "guaranteed" or "safe to buy".
- **Redaction by default**: serial masked to its last 4 characters on the card and in Copy Raw Data; never a user name,
  host name or Apple Account.
- Camera and microphone prompts appear only when the user starts those tests. Nothing is recorded or saved.
- No `Button` with an empty action (a dialog's `role: .cancel` is the exception), and never replace the standard Edit
  menu's `.pasteboard` or `.textEditing` groups (Paste Result needs ⌘V).

## Repo rules

- Never name the AI tooling used to build this repo in any file, comment, doc or commit message.
- No personal home paths in committed files (Windows user folders, or `/Users/` followed by a real name). CI fails on
  them. Use `~` or a repo-relative path. `/Users/Shared` and the example users `you` and `jane` are allowed.
- Every release needs a `## X.Y.Z — YYYY-MM-DD` section in `CHANGELOG.md`, written for users: it becomes the GitHub
  release notes and the site's changelog. Upcoming notes go under `## Unreleased` (never published).
- One base URL, `https://everydayopen.github.io/tirekick`: `site/site.json` `baseURL` == `App/Links.swift`
  `Links.website`. `tools/doctor.sh --ci` fails when they disagree.
- No third-party dependencies in the app. Python tools use the standard library only.
- Never commit key material (`.p12`, `.p8`) or real secrets.
- Code style is ponytail (BUILD_PLAN §10): the shortest correct code, no protocols with one implementation, no view
  model per screen, comments only where the why isn't obvious.

## Ownership

When several agents work in parallel, each edits only its own files (BUILD_PLAN §9). `Model/*`, `Package.swift` and
`docs/BUILD_PLAN.md` are frozen: add extensions in your own files, and propose any other change in your report.
