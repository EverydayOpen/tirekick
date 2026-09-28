# Changelog

Newest first. `tools/changelog.py` turns each section into the GitHub release notes and the website changelog, so
write for users. Headings must be `## X.Y.Z — YYYY-MM-DD` (em dash); the release workflow refuses a tag without one.
Write upcoming notes under `## Unreleased`, which is never published (the website deploys on every push to main). On
release day, rename it to `## X.Y.Z — <that day>`, commit, push only the tag, and push main once the release is
published (docs/RELEASING.md "Cutting a release"). Links must be full `https://` URLs: the GitHub release can't
resolve site-relative ones.

## Unreleased

First release. Open Tirekick on a second-hand Mac and in about two minutes it tells you, in plain English, what to
check before you pay.

- **Locks and company enrollment**: Activation Lock, device management (MDM), and whether the Mac is assigned to a
  company in Apple Business or Apple School Manager, which would take it back after it's erased. The company check is
  one command you run in Terminal and paste back; Tirekick never asks for your password.
- **What you're buying**: model, year, chip, cores, memory, storage and serial, to compare with the listing.
- **Battery and SSD**: maximum capacity, cycle count against the battery's rating, and the SSD's SMART status.
- **macOS updates**: whether the Mac gets macOS 27, or which macOS is its last.
- **Guided tests**: keyboard, display, speakers, microphone, camera and trackpad, each ending in Pass, Problem or Skip.
- **Report card**: save it as PNG or PDF, or copy it. The serial number is masked by default.
- **Selling mode** adds a ready-to-sell checklist: signed out of iCloud, FileVault on.
- Every check shows the exact command it ran and the raw output. "Walk away" is kept for hard facts.
- Runs offline, sends nothing, reads nothing personal and changes nothing. It never helps bypass MDM or Activation Lock.
- Requires macOS 13 or later, on Apple silicon or Intel. Free and open source under the MIT License.
