# Going live: from zero to the first public release

Tirekick is free and open source: there are no payments, licences or accounts to set up. Do the steps in order; each
one unblocks the next. `bash tools/doctor.sh` shows what's configured and what's still open. Signing and
notarization details live in [RELEASING.md](RELEASING.md); this file covers everything around them. Anything marked
**VERIFY** wasn't confirmed against the provider's docs, so check it there when you get to it.

Dates are from PICK §3 and §5: beta.1 in week 1, fixtures from the CI dump by **Oct 2**, Developer ID approved by
**Oct 20** (otherwise the launch slips a week), launch **Tue Oct 27**.

## 1. Name check (before anything goes public)

"Tirekick" is a working name. A knockout search is a quick screen for obvious conflicts, not a legal clearance.

- Search "Tirekick" and close variants ("Tire Kick", "TireKicker", "Tyrekick") for software in Nice classes **9**
  (downloadable software) and **42** (software services):
  - USPTO: https://tmsearch.uspto.gov/
  - WIPO Global Brand Database (many national registers): https://branddb.wipo.int/
  - India, IP India public search: https://tmrsearch.ipindia.gov.in/tmrpublicsearch/ (**VERIFY** the address)
  - The Mac App Store, the iOS App Store (a vehicle-inspection app named "TireKicker Inspections" exists) and a web
    search for "Tirekick app" and "Tirekick Mac".
- If a live mark or a shipping app uses the same or a confusingly similar name for software, switch to the backup
  name (Dealbreaker) now. The name appears in `project.yml`, `App/`, `site/site.json`, the workflows' `APP`, the
  README and the site pages.

## 2. GitHub: repo, Pages and the first CI runs

1. **Public repo.** On GitHub's free plan the repo must be public for the `release` environment, its secrets and its
   `v*` rule, and for required reviewers
   ([environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments)).
   A public repo also runs standard GitHub-hosted runners, macOS included, for free (**VERIFY** current Actions
   pricing if you ever go private).
2. **Push.** From this folder, with `gh` logged in under the EverydayOpen organization, run
   `git init -b main && git add -A && git status --ignored`. Every file staged to commit becomes public, so check
   that no key material or secrets are among them, and check the ignored files too. Then:
   `git commit -m "Initial commit" && gh repo create EverydayOpen/tirekick --public --source . --push`.
   Keep `-b main`: `ci.yml` and `site.yml` run only on `main`.
3. **Pages.** The first push runs `site.yml`, which creates the `gh-pages` branch. Then open Settings › Pages ›
   Build and deployment › Source: **Deploy from a branch**, branch `gh-pages`, folder `/ (root)`, and **Save**. The
   site is served at `https://everydayopen.github.io/tirekick/`, which is `site/site.json`'s `baseURL` and
   `Links.website` in `App/Links.swift`; `bash tools/doctor.sh` checks that they agree. Leave **Issues** on (Settings ›
   General › Features): the support page and the app's Help menu send people there.
4. **Fixtures (kill-it-early, Oct 2).** Open Actions › **fixtures** › Run workflow. It dumps every allowlisted command
   on the arm64 and Intel runners. Read `profiles_status_nobody` in the log: if `profiles status` needs root, the lock
   checks get redesigned in week 1, not week 4 (PICK §5). Hand the artifacts to whoever owns the Core parsers.

## 3. Optional: a custom domain

Skip this unless you want your own domain; `everydayopen.github.io/tirekick` works as is.

1. Verify the domain for the EverydayOpen organization first (organization Settings › Pages › **Add a domain**; GitHub
   shows a TXT record to add). This stops anyone else from taking the domain over on GitHub Pages.
2. Add these records at your DNS host:

   | Type | Name | Value |
   |---|---|---|
   | A | `@` | `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153` (four records) |
   | AAAA | `@` | `2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153` |
   | CNAME | `www` | `everydayopen.github.io` |

3. In the repo, open Settings › Pages › Custom domain, enter the domain and save. GitHub commits a `CNAME` file to
   `gh-pages`, which `site.yml` never overwrites. Tick **Enforce HTTPS** when it becomes available.
4. Change `site/site.json` `baseURL` and `Links.website` to `https://<domain>` (no path) and run
   `bash tools/doctor.sh`. The app has no update feed, so older copies only lose their Help link's address; GitHub
   redirects the old one.

## 4. Apple Developer Program and signing

Needed even for a free app: without a Developer ID signature and Apple's notarization, macOS refuses to open a
downloaded app without a trip to System Settings, and Tirekick runs on strangers' Macs. Follow RELEASING.md steps 1 to
4: enrollment (Individual, $99 a year; in India only through the Apple Developer app), the Developer ID Application
certificate, the App Store Connect Team API key, and the `release` environment with its seven secrets. With `gh`
logged in, `bash tools/doctor.sh` lists any secret that's still missing. If the account isn't approved by Oct 20,
slip the launch to Nov 3 and keep testers on `beta.yml` builds; never launch publicly unsigned.

## 5. Website and legal review

1. `site/site.json` names the owner (EverydayOpen) and the governing law (the laws of India) on the legal pages.
   Run `python tools/build_site.py --check` and push `main`: `site.yml` publishes the site. `/download/` shows
   "Coming soon" until `CHANGELOG.md` on `main` has a released section (step 7).
2. **Legal review.** The terms and privacy pages are drafts, not reviewed by a lawyer. Have one check them against:
   - free, open-source software under the MIT License: provided as is, no warranty, limitation of liability.
     Consumer law in India and in your main users' countries may not allow excluding all liability, even for
     something given away;
   - "findings, not guarantees": a buyer or seller who relied on a report. The terms say the app reports what macOS
     reports and isn't an inspection or certification;
   - what the app actually does: no network access, no telemetry, no account, no stored settings of its own (macOS may still remember its window position and last save
     folder, as for any app); it reads hardware
     and system status (including the serial number, masked on reports by default), counts iCloud accounts without
     reading them, and uses the camera and microphone live only during those tests (CHANGELOG.md);
   - GitHub as host of the site and the downloads: it sees visitors' IP addresses (GitHub's privacy statement;
     **VERIFY** what it logs for Pages and release downloads);
   - the contact route for privacy requests: GitHub Issues are public, so ask whether you also need a private one.
3. When the review is done, set `"legalReviewed": true` in `site/site.json` and push `main` to redeploy.

## 6. Placeholders

Run `bash tools/doctor.sh` until it reports no `todo` lines, or only ones you have decided to accept. `release.yml`
refuses to build while `baseURL` or `Links.website` is a placeholder or they disagree, or while `site/site.json`'s
`releasesRepo` isn't this repository.

## 7. First release

1. **Rehearse** as RELEASING.md describes under "Before the first public release": tag a throwaway `v0.0.1` from a
   throwaway branch, install it on a Mac, then delete it.
2. On release day, rename `## Unreleased` in `CHANGELOG.md` to `## 1.0.0 — <that day>` and commit it, then tag and
   push only `v1.0.0`. Push `main` once the release is published (RELEASING.md "Cutting a release"): that push
   deploys the site, and `/download/` stops showing "Coming soon".

## 8. Post-release checks

- `<baseURL>/download/` downloads the new DMG
  (`https://github.com/EverydayOpen/tirekick/releases/latest/download/Tirekick.dmg`). It opens and the app launches
  without a Gatekeeper warning. The release workflow already launched it on Apple silicon and Intel.
- `/changelog/` and `/feed.xml` show the release. Every page's footer links terms, privacy and support, and the
  support page leads to Issues.
- In the app, the Help menu opens the website, and every check works with Wi-Fi off (except the company check, which runs in Terminal).
- For the first weeks, watch Issues (testers' raw output becomes Core fixtures) and the Actions runs. The weekly
  **ci** run fails if the hardware specs stop parsing or `profiles status` prints nothing on the current macos-26
  image. Nothing checks the rest automatically: download the weekly **fixtures** artifacts and compare them with
  Tests/TirekickCoreTests/Fixtures by hand.
