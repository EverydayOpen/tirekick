# Design spec: Tirekick (website and app)

**Why:** the owner's verdict (2026-09-29): the sites and apps "look cheap". They must look modern, premium and 3D, on
par with Mole, Recordly, Maccy, Rectangle, VoiceInk and MaCursor, while staying lightweight and secure.
**Authority:** this file is authoritative for visual design (tokens, surfaces, compositions, type). `docs/MOTION.md`
stays authoritative for motion and is referenced by section; where they conflict, §2.7 lists what changed. BUILD_PLAN
§7 is frozen (architect), so its lines that need amending are proposed in §9, not amended here. Safety rules, copy,
data flow, macOS 13 APIs and the checker's contract are unchanged.
**Shared system:** §1–§3 are identical in the Whydunit repo's `docs/DESIGN.md`; change both together. §4–§9 are
Tirekick's.
**Status:** nothing here has been run in this repo. The header pill, buttons, key-caps, cards, FAQ rows, contact
shadows and a side-by-side studio stage were prototyped in Chromium on Windows (1440 and 375px) in the Daylight
proposal on a standalone page; the dark bay palette, the laptop/card overlap and the lime accent come from the Night
Studio proposal and have not been rendered. Contrast figures were recomputed with the checker's formula. The Swift
is written, not compiled; anything unconfirmed is marked VERIFY.

## 1. The verdict (shared, identical in both repos)

Two directions were proposed: "Night Studio" (dark, cinematic, one lit object on a dark stage) and "Daylight"
(light, crisp, tactile key-caps, the product in its own small world). Judged against the reference screenshots
(Mole, Recordly, Maccy, Rectangle, VoiceInk, MaCursor), the premium ones share one mechanism, not one palette: **the
product sits inside a world, on a page that is otherwise restrained.** Mole and VoiceInk are light with a wallpaper
frame around the app; Recordly and MaCursor are dark with a sky or a halo behind it. Rectangle and Maccy, the two
plainest, put the product on bare white with nothing behind it, which is exactly what our sites do today.

So the family rule is **one product, one world, one accent**, and each brand picks the world that fits its job:

| | Whydunit | Tirekick |
|---|---|---|
| World | **Sky**: daylight over iCloud, dusk at night. Light-first, follows the system (`prefers-color-scheme`). | **Bay**: a warm-graphite inspection bay lit from above. Dark on every page, in both schemes. |
| Why | Ordinary Mac users with a stuck file want calm and trust. Apple's own iCloud language is white and blue. Mole and VoiceInk prove light reads premium when the product is framed. | A buyer at a meetup wants a tool that looks like an instrument. Dark graphite, mono readouts and one hi-vis accent are distinct from every other Mac utility and from Whydunit. |
| Accent | Sky blue `#2457E0` (`#3461EA` at dusk), also the app's AccentColor. | Hi-vis lime `#C6F23C`, black text on it. Only the one prominent button, the beam, tested keys and eyebrow indices. The app keeps the user's accent for controls. |
| Type voice | Centered, soft pills, `ui-rounded` numerals. | Left-aligned, machined 12px corners, `ui-monospace` eyebrows and readouts. |
| Hero object | The app window floating over a cloud in a sky frame, a ghost Finder window behind it. | A CSS laptop standing back-left, the white report card leaning in front-right, on a tread-marked floor with a lime horizon. |
| Signature scroll moment | Three safe fixes as sticky stacking cards. | Six key-cap test tiles and a paper fan of the shareable card. |

What each brand takes from the other direction: Whydunit takes Night Studio's volumetric cloud, proof strip,
"Finder says / Whydunit says" pairs, type ladder and System Settings–style sidebar tiles. Tirekick takes Daylight's
key-cap recipe, contact shadows, verdict plate on the report card, `StepBar` with a hidden title bar, and its
prototype-tested stage structure.

**Not doing, in either brand:** a webfont (every real visitor is on a Mac and gets SF Pro; Windows gets Segoe UI
Variable, which the Daylight prototype showed is fine), a CSP meta tag (the sites load only same-origin files; it
would only force the `style="--i"` stagger to be rewritten), a nav CTA that hides itself (needs JS for no gain),
mesh blobs, gradient text, emoji icons, live star counts, autoplay video, glass on content.

### 1.1 The eight rules

1. **One world per product.** The sky or the bay appears behind the hero scene, the finale and the download page's
   icon. Every other section is paper (Whydunit) or graphite (Tirekick), separated by whitespace, never by bands.
2. **One accent.** Green, orange and red mean a verdict or a status, and appear only in symbols, tag dots and fills
   behind primary text. Severity never glows: a red "Walk away" is lit exactly like a green "Clean" (MOTION.md §1.1).
3. **Light, not lines.** A key light at the top of the stage, the brand light behind the object, a lit top edge on
   every raised surface, shadows tinted with the brand's ink (navy or warm black), never neutral gray, never animated.
4. **Everything you can press is a key-cap:** a gradient lighter at the top, `inset 0 1px 0` highlight, a hairline,
   and a press that sinks 1px.
5. **Concentric radii:** outer radius = inner radius + padding. Whydunit 10/14/20/28 and pills; Tirekick 6/10/14/20
   and 12px buttons.
6. **Grain on big gradients only** (3–6% noise from an inline SVG, under 1 KB), never under body text. It stops
   8-bit banding, the commonest "cheap dark gradient" tell.
7. **Zero bytes added:** no fonts, images, scripts, CDNs or third-party requests. Illustrations are HTML and CSS.
   `motion.js` stays byte-identical in both repos.
8. **The apps stay native.** Navigation, tables, forms, sheets, Settings and the toolbar are system parts. Premium
   comes from the accent, a static wash, icon wells, tags, key-caps, one lifted object per stage screen, and the
   precision of the type. No custom chrome, and glass only where the macOS 26 SDK draws it by itself.

## 2. Shared web foundation

### 2.1 The contract with `tools/build_site.py`

- `contrast()` reads exactly two `:root { }` blocks and only 6-digit hex tokens. Whydunit's blocks are light then
  dark. Tirekick's are the base (dark) palette then `@media (prefers-contrast: more)`; the checker's "light"/"dark"
  labels are just labels. Everything else overrides on `html` or a class (MOTION.md §1.6).
- `--on-button` is measured against `--button` and `--button-hover` once infra applies the one-line change in the
  brand section. Until then Tirekick's black-on-lime fails the hard-coded white check.
- `data-theme` and `localStorage` must not appear anywhere, including comments.
- All numbers in the token comments were computed with the checker's own WCAG formula (`<scratchpad>/design_contrast.py`, 2026-09-29).

### 2.2 Type: SF Pro, zero bytes

Stack: `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI Variable Text", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif`.
Numerals: Whydunit `ui-rounded` (SF Pro Rounded in Safari), Tirekick `ui-monospace` (SF Mono). Both are system fonts.

```css
/* Type ladder (docs/DESIGN.md §2.2). Every size on the site is one of these; nothing in between.
   h1     clamp(2.6rem, 1.4rem + 5vw, 4.75rem) / 1.02, -.032em, 700, text-wrap: balance
   h2     clamp(2rem, 1.2rem + 3vw, 3.1rem)    / 1.06, -.026em, 700, balance
   lede   clamp(1.1rem, 1rem + .5vw, 1.3rem)  / 1.45, -.011em, 400, --text-2
   h3     1.2rem / 1.3, -.015em, 600          body 17px / 1.55, -.011em          prose 17px / 1.6 (guides)
   card   15px / 1.5                          meta 13px / 1.4 (facts, captions)  floor 12px / 1.2, 600 (chrome, tags)
   eyebrow: Whydunit 13px 600 --accent; Tirekick 12px 600 mono, .06em, sentence case (BUILD_PLAN §8: no ALL CAPS). */
```

- **Two-tone headings** on every h1 and h2 that has a reassurance clause: `<h2>Built to never lose a file. <span class="dim">Every change is logged.</span></h2>`.
- **Numbers** are `font-variant-numeric: tabular-nums` everywhere they line up.
- VERIFY headline tracking by eye in Safari on a Mac: SF Pro Display already tightens above 20px, so −.032em may
  want to relax to −.028em.

### 2.3 Space, widths and radii

- Widths: `.wrap` 1080px (content), `.wide` 1200px (stages), `.read` 720px (prose, FAQ). Gutter 20px.
- Section padding `clamp(72px, 11vw, 128px)`. Gaps are 12, 16, 24, 32, 48 or 64px.
- Radii tokens `--r-s / --r-m / --r-l / --r-xl` and `--r-btn` come from each brand's `:root`.
- `scroll-padding-top: 84px` so anchors clear the floating header.

### 2.4 Shared component CSS (identical in both repos, about 7.5 KB)

These rules read only tokens; each brand's `:root` blocks supply the values. They **replace** the old rules of the
same name (`.site-header`, `.nav`, `.button*`, `.card`, `details`, `summary`, `.site-footer`) and MOTION.md §1.7's
`.button { transition: … }` line. Delete `.band`, `section:not(.band) .card` and `.hero-icon`.

```css
/* Design system (docs/DESIGN.md §2.4). Brand lives in the two :root blocks; these rules only read tokens. */
h1 { font-size: clamp(2.6rem, 1.4rem + 5vw, 4.75rem); letter-spacing: -.032em; line-height: 1.02; text-wrap: balance; }
h2 { font-size: clamp(2rem, 1.2rem + 3vw, 3.1rem); letter-spacing: -.026em; line-height: 1.06; text-wrap: balance; }
.dim { color: var(--text-2); }
.eyebrow { margin: 0 0 14px; color: var(--accent); font-size: 13px; font-weight: 600; }
main > section { padding-block: clamp(72px, 11vw, 128px); }
.wrap { max-width: 1080px; }
.wide { max-width: 1200px; margin-inline: auto; padding-inline: 20px; }
.read { max-width: 720px; }
html { scroll-padding-top: 84px; }

/* Header: a floating glass pill (Mole). Glass only here, never inside a 3D scene (MOTION.md §1.6). */
.site-header { position: sticky; top: 10px; z-index: 10; padding-inline: 12px; background: none; border: 0; -webkit-backdrop-filter: none; backdrop-filter: none; }
.nav { max-width: 1000px; height: 52px; margin: 10px auto 0; padding: 0 8px 0 16px; gap: 20px; border-radius: 999px; background: var(--header); -webkit-backdrop-filter: saturate(180%) blur(20px); backdrop-filter: saturate(180%) blur(20px); box-shadow: var(--z1); }
.brand { font-weight: 600; letter-spacing: -.02em; }
.brand img { border-radius: 6px; box-shadow: 0 1px 2px rgb(var(--ink) / .25); }
.nav .button + .button { margin-left: -8px; }

/* Buttons: key-caps. The fill only darkens toward the bottom, so the label never drops below the measured
   --on-button/--button contrast; the light is an inset line plus a glow in the brand colour. */
.button { gap: 10px; min-height: 48px; padding: 0 22px; border: 1px solid transparent; border-radius: var(--r-btn); font-size: 16px; font-weight: 600; letter-spacing: -.01em; color: var(--on-button);
  background: linear-gradient(var(--button), color-mix(in srgb, var(--button) 88%, #000));
  box-shadow: inset 0 1px 0 rgb(255 255 255 / .25), 0 1px 2px rgb(var(--ink) / .25), 0 10px 24px -8px color-mix(in srgb, var(--button) 60%, transparent); }
.button:hover { background: linear-gradient(var(--button-hover), color-mix(in srgb, var(--button-hover) 88%, #000)); text-decoration: none; }
.button svg { flex: none; width: 18px; height: 18px; }
.button .sep { align-self: stretch; width: 1px; margin-block: 13px; background: currentColor; opacity: .28; }   /* glyph | label (Maccy) */
.button.secondary { color: var(--text); background: linear-gradient(var(--cap-top), var(--cap-bot)); box-shadow: var(--cap); }
.button.small { min-height: 36px; padding: 0 16px; font-size: 14px; }
.skip { color: var(--on-button); }
@media (prefers-reduced-motion: no-preference) {
  .button { transition: background-color .2s, translate var(--t-fast) var(--ease-out), scale var(--t-fast) var(--ease-out); }   /* replaces MOTION §1.7's line; :active { scale: .97 } stays */
}
@media (prefers-reduced-motion: no-preference) and (hover: hover) { .button:hover { translate: 0 -1px; } }

/* Kicker chip over the h1 (Whydunit) and the facts line under the CTAs (both). */
.kicker { display: inline-flex; align-items: center; gap: 8px; margin: 0 0 22px; padding: 6px 12px 6px 7px; border-radius: 999px; font-size: 13px; font-weight: 600; background: linear-gradient(var(--cap-top), var(--cap-bot)); box-shadow: var(--cap); }
.kicker svg { width: 20px; height: 20px; padding: 3px; border-radius: 50%; color: var(--accent); background: color-mix(in srgb, var(--accent) 14%, var(--card)); }
.facts { margin: 0; font-size: 13px; color: var(--text-2); }

/* Cards are raised objects: a hairline, a lit top edge (inside --z2) and an ink-tinted two-layer shadow. */
.card { padding: 26px; border-radius: var(--r-l); background: var(--card); box-shadow: var(--z2); }
.card h3 { margin: 16px 0 6px; }
.card p { font-size: 15px; line-height: 1.5; }
/* Icon well: recessed, tinted with the accent, holds a 1.7-stroke inline SVG. */
.well { display: grid; place-items: center; width: 44px; height: 44px; border-radius: 12px; color: var(--accent);
  background: linear-gradient(color-mix(in srgb, var(--accent) 14%, var(--card)), color-mix(in srgb, var(--accent) 6%, var(--card)));
  box-shadow: inset 0 0 0 .5px color-mix(in srgb, var(--accent) 30%, transparent), inset 0 1px 2px rgb(var(--ink) / .08); }
.well svg { width: 22px; height: 22px; }
/* Tags: colour lives in the dot and the fill; the text stays --text, so it always passes. */
.tag { display: inline-flex; align-items: center; gap: 6px; padding: 2px 9px; border-radius: 999px; font-size: 12px; font-weight: 600; font-variant-numeric: tabular-nums; color: var(--text);
  background: color-mix(in srgb, var(--c, var(--text-2)) 14%, var(--card)); box-shadow: inset 0 0 0 .5px color-mix(in srgb, var(--c, var(--text-2)) 40%, transparent); }
.tag::before { content: ""; width: 6px; height: 6px; border-radius: 50%; background: var(--c, var(--text-2)); }
.tag.ok { --c: var(--ok); } .tag.warn { --c: var(--warn); } .tag.bad { --c: var(--bad); } .tag.info { --c: var(--accent); }

/* Proof strip (VoiceInk): facts in the display face; the hairlines are the grid gap, so wrapping never breaks them. */
.proof { display: grid; grid-template-columns: repeat(auto-fit, minmax(min(100%, 200px), 1fr)); gap: 1px; margin: 0; overflow: clip; border-radius: var(--r-l); background: var(--line); box-shadow: var(--z1); }
.proof div { display: flex; flex-direction: column-reverse; gap: 8px; padding: 22px 26px; background: var(--card); }
.proof dd { margin: 0; font: 700 clamp(28px, 3vw, 40px)/1 var(--font-num); letter-spacing: -.03em; font-variant-numeric: tabular-nums; }
.proof dt { font-size: 13px; color: var(--text-2); }

/* "They say / we find" pairs: a quiet claim card with the finding card lying on top of it. */
.pair { display: grid; }
.pair .claim { padding: 18px 20px 44px; border-radius: var(--r-l); background: var(--bg-alt); box-shadow: inset 0 0 0 1px var(--line); color: var(--text-2); }
.pair .finding { margin: -30px 0 0 10%; padding: 16px 18px; border-radius: var(--r-m); background: var(--card); box-shadow: var(--shadow); }
.pair .finding .tag { margin-bottom: 8px; }

/* FAQ: native <details> as rows you can pick up. MOTION's unfold and +/− turn are unchanged. */
.faq { display: grid; gap: 32px 64px; }
@media (min-width: 900px) { .faq { grid-template-columns: 5fr 7fr; } .faq-head { position: sticky; top: 96px; align-self: start; } }
details { border: 0; padding-inline: 20px; border-radius: var(--r-m); background: var(--card); box-shadow: var(--z1); }
details + details { margin-top: 10px; }
details:first-of-type { margin-top: 0; border-top: 0; }
details[open] { box-shadow: var(--z2); }
summary { padding-block: 18px; font-size: 1.05rem; }
details p { margin-bottom: 20px; }

/* The stage: a still backdrop behind the 3D scene (only .scene moves, MOTION §1.1). Brands paint ::before. */
.stage { position: relative; isolation: isolate; }
.stage::before { content: ""; position: absolute; z-index: -2; inset: 0; border-radius: var(--r-xl); box-shadow: inset 0 0 0 1px rgb(var(--ink) / .06); }
@media (max-width: 640px) { .stage { margin-inline: -20px; } .stage::before, .stage::after { border-radius: 0; } }

/* Finale: the app icon as an object in the world, then the last CTA. Brands paint .panel. */
.finale { text-align: center; }
.finale .panel { position: relative; overflow: clip; padding: 72px 24px; border-radius: var(--r-xl); box-shadow: var(--z2); }
.finale .icon { display: block; width: 112px; height: 112px; margin: 0 auto 28px; filter: drop-shadow(0 24px 30px rgb(var(--ink) / .3)); }
.finale h2 { margin-bottom: 24px; }
@media (max-width: 640px) { .finale .panel { margin-inline: -20px; border-radius: 0; } }
@media (prefers-reduced-motion: no-preference) and (hover: hover) and (pointer: fine) {
  .finale .panel { perspective: var(--persp-card); }
  .finale .icon[data-tilt] { --tilt: 12deg; transform: rotateX(calc(var(--py) * var(--tilt) * -1)) rotateY(calc(var(--px) * var(--tilt))); transition: transform var(--t-slow) var(--ease-out); }
  .finale .icon.tilting { transition-duration: var(--t-fast); }
}

/* Reading pages: boxes and code as objects, nothing moves. */
.summary { background: var(--card); box-shadow: var(--z1); }
code { background: var(--bg-alt); box-shadow: inset 0 0 0 .5px rgb(var(--ink) / .1); }
.release { padding: 22px 24px; border-radius: var(--r-l); background: var(--card); box-shadow: var(--z1); }
.release + .release { margin-top: 20px; border-top: 0; }
.release .tag { font-family: var(--font-mono); }

/* Footer: one slab plus the official-sources line (Maccy, Mole): quiet, and security-relevant. */
.site-footer { padding: 56px 0 40px; border-top: 1px solid var(--line); background: var(--bg-alt); }
.official { display: flex; gap: 10px; align-items: flex-start; margin: 28px 0 0; padding: 12px 14px; border-radius: var(--r-s); background: var(--card); box-shadow: var(--z1); color: var(--text-2); font-size: 13px; }
.official svg { flex: none; width: 18px; height: 18px; margin-top: 1px; color: var(--accent); }

/* Accessibility variants and print. */
@media (prefers-reduced-transparency: reduce) { .nav { background: var(--card); -webkit-backdrop-filter: none; backdrop-filter: none; } }
@media (prefers-contrast: more) {
  html { --grain: none; --glare: transparent; }
  .card, details, .nav, .button, .kicker, .official, .tag, .proof { box-shadow: 0 0 0 2px var(--text); }
}
@media (forced-colors: active) { .button, .card, details, .tag, .well, .proof div { border: 1px solid CanvasText; } }
@media print {
  html { --bg: #fff; --bg-alt: #fff; --card: #fff; --text: #000; --text-2: #333; --accent: #0645ad; --grain: none; }
  .site-header, .site-footer, .skip, .stage::before, .stage::after, .finale { display: none; }
  .card, details, .summary, .release { box-shadow: 0 0 0 1px #ccc; }
}
```

Markup that goes with it (both sites):

- **Sprite:** add `<symbol id="i-down" viewBox="0 0 24 24"><path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" d="M12 4v11m0 0-4.5-4.5M12 15l4.5-4.5M4.5 19.5h15"/></symbol>`.
- **Nav** (`layout.html`): `<a class="button secondary small" href="https://github.com/{{releasesRepo}}">Source</a><a class="button small" href="/download/">Download</a>`. No star count, so no request.
- **Footer** (`layout.html`), after the columns: `<p class="official"><svg aria-hidden="true"><use href="#i-check"/></svg>The only official site is {{baseURL}}. Downloads come only from github.com/{{releasesRepo}}/releases.</p>`. The sprite must then live in `layout.html`, not each page. After the signed 1.0 ships, add "Every release is signed with an Apple Developer ID and notarized by Apple."
- **Illustrations** keep their "Illustration with sample data" caption and `role="img"` labels.

### 2.5 Where gradients, grain and glass are allowed

| Effect | Allowed on | Never on |
|---|---|---|
| Large gradient (sky, bay) | the hero stage, the finale panel, the download page's icon panel, the media wells of stacked cards | paper sections or cards |
| Small gradient (cap, well, orb, button) | key-caps, wells, step orbs, buttons | text |
| Grain (`--grain`) | large gradients only; `none` under `prefers-contrast: more` and in print | body text, paper |
| Glass (`backdrop-filter`) | the header pill only | anything inside `.stage` (Safari flattens it) or on cards |
| Gradient text, mesh blobs, orbs, marquees | nowhere | everywhere |

### 2.6 Sub-pages (download, changelog, guides, support, legal, 404)

- **Reading pages stay still** (MOTION.md): no stage, no tilt. Header strip: `.eyebrow`, h1 at `clamp(2.1rem, 5vw, 3.2rem)`, one meta line in `--text-2`. Prose is `.read` (720px) at 17px/1.6. `.summary` boxes are cards with `--z1`; `code` and `pre` are recessed.
- **Download:** the icon as an object on a small world panel (the finale `.panel` at 220px tall, the icon 128px with `data-tilt`), then h1, the button, the requirements line, three numbered steps (Open the DMG · Drag to Applications · Open the app), the beta note, and the official-sources line. After 1.0: the Developer ID team name, "notarized by Apple" and a link to the release's SHA-256.
- **Changelog:** each release is a `.release` card with the version in a mono `.tag` and the date in `--text-2`.
- **Guides:** reading layout. Tirekick's meetup checklist keeps printing clean (the shared print rules strip stages and shadows).
- **Support and legal:** reading layout only. Support repeats the official-sources line under its h1.
- **404:** the brand's world panel at 240px tall with its object, one line in the product's voice, and a Home button.

### 2.7 What this supersedes in MOTION.md

MOTION.md stays authoritative for motion: the hero sequences, tilt, glare, reveal, flips, `motion.js` and the
Reduce Motion table are unchanged and referenced by section below. Where the two conflict, this file wins:

| MOTION.md | Now |
|---|---|
| §1.7 `--z1`, `--z2`, `--glare` values, and the existing `--shadow` | ink-tinted values in each brand's `:root` (§4.1); the names are unchanged, so the motion CSS keeps working |
| §1.7 `.button { transition: background-color .2s, scale … }` | §2.4's transition line (adds `translate`) |
| §1.7 "light then dark" `:root` blocks | Whydunit unchanged; Tirekick's second block is `prefers-contrast: more` |
| §2.3 `.cloud { fill: var(--glare) }` | `fill: url(#g-cloud)`, a volumetric cloud (Whydunit §4.3) |
| §4.3 `.scene` side-by-side grid at ≥900px, `.beam` blue, `.lid`/`.deck` flat fills | overlap composition at ≥1100px, lime beam, graphite and aluminium materials (Tirekick §4.3) |
| §5.1 `TileButtonStyle` | `KeyCapStyle` (Tirekick §5.2), same tilt, press and bounce behaviour |
| §3 "no card backgrounds on content", "no custom glass" (BUILD_PLAN quotes) | amended as listed in §9 of each brand |

## 3. Shared app foundation (SwiftUI; written, not compiled)

**What stays native:** `NavigationSplitView`, `Table`, `Form(.grouped)`, the toolbar, sheets, Settings, system
materials, the user's accent, and on macOS 26 the SDK's automatic Liquid Glass on toolbars and sidebars.
**What is added:** the brand's static wash, icon wells, tags, key-caps, one lifted object per stage screen, and (Tirekick)
a step bar. Every API below is macOS 13 so both apps can share it; Whydunit-only additions are in its §5.

### 3.1 `App/DesignSystem/Tokens.swift` additions (both apps)

```swift
extension View {
    /// A symbol in a recessed, tinted squircle: the site's icon well. Pure fills, so ImageRenderer-safe.
    func well(_ tint: Color, size: CGFloat = 44) -> some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        return frame(width: size, height: size)
            .background(shape.fill(tint.opacity(0.16).gradient))          // Color.gradient: macOS 13
            .overlay(shape.strokeBorder(tint.opacity(0.24), lineWidth: 0.5))
    }

    /// A raised object (app icon, laptop, report card; never a row): a tight contact shadow plus a wide soft one,
    /// like the site's --shadow. compositingGroup so glyphs don't cast their own shadows (MOTION.md §1.4).
    func lifted() -> some View {
        compositingGroup()
            .shadow(color: .black.opacity(0.10), radius: 1.5, y: 1)
            .shadow(color: .black.opacity(0.20), radius: 24, y: 14)
    }
}

/// A count or a word in a tinted capsule. Colour sits in the dot and the fill; the text stays primary, so it always
/// has full contrast ("only symbols carry colour"). Increase Contrast adds a stroke.
struct Tag: View {
    let text: String
    var tint: Color = .secondary
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 6, height: 6).accessibilityHidden(true)
            Text(text).font(.caption.weight(.semibold)).monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tint.opacity(0.14), in: Capsule())
        .overlay(Capsule().strokeBorder(contrast == .increased ? Color.primary.opacity(0.4) : tint.opacity(0.3), lineWidth: contrast == .increased ? 1 : 0.5))
    }
}
```

### 3.2 Performance and accessibility (both apps)

- Everything added is static fills and gradients plus at most 6 `lifted()` shadows per screen. Idle CPU stays 0%;
  motion follows MOTION.md §3/§5 exactly, and the only loops are the scan glyph and the laptop beam.
- Wells hide duplicate symbols from VoiceOver; `SeverityIcon`/`VerdictIcon` keep speaking their words; combined
  elements are unchanged. Differentiate Without Color still shows the words.
- Reduce Transparency turns materials solid by itself. Increase Contrast: tags and wells get a 1pt primary stroke,
  and the wash falls back to the plain window background.
- No `drawingGroup()`, no animated `blur` or `shadow`. `ReportCardView` (the PNG) gets no effects around it.

## 4. Tirekick website: the inspection bay

Dark on every page, in both colour schemes: the bay is the brand, and a light second scheme would show it to almost
nobody. The second `:root` block is `prefers-contrast: more`, a real accessibility feature that also keeps the
checker's two-block contract. Print overrides on `html` (shared §2.4), so the meetup checklist still prints on paper.

### 4.1 Tokens (replace the two `:root` blocks in `site/static/styles.css`)

```css
:root {
  color-scheme: dark;
  /* contrast(), base, worst of bg / bg-alt / card: text 16.1:1, text-2 5.97:1, accent 14.2:1;
     on-button (black) on button 15.3:1, on hover 12.9:1. Needs the --on-button lookup in build_site.py (§9). */
  --bg: #0a0a09;                      /* warm graphite, never #000 */
  --bg-alt: #11110f;
  --card: #181816;
  --well: #050504;                    /* recessed icon wells and code */
  --text: #f4f4f0;
  --text-2: #96968e;
  --accent: #cdf54a;                  /* hi-vis lime: links, eyebrow indices, well icons */
  --button: #c6f23c;
  --button-hover: #b4e02a;
  --on-button: #0a0a09;               /* black label on lime */
  --line: #262622;                    /* hex so the checker can read it if a pair is ever added */
  --header: rgb(12 12 11 / .78);
  --ink: 0 0 0;
  --ok: #32d74b; --warn: #ff9f0a; --bad: #ff453a;
  /* The world: an overhead key light, the lime spill and one lit horizon, only on stages. */
  --key: rgb(255 255 245 / .08);
  --glow: rgb(198 242 60 / .28);
  --horizon: rgb(198 242 60 / .75);
  --tread: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='32' height='18'%3E%3Cpath d='M0 14 16 5l16 9' fill='none' stroke='%23fff' stroke-opacity='.045' stroke-width='3'/%3E%3C/svg%3E");
  /* Key-caps: machined, a lit top edge, a dark side. */
  --cap-top: #24241f; --cap-bot: #1a1a17;
  --cap: inset 0 1px 0 rgb(255 255 255 / .12), 0 0 0 1px rgb(255 255 255 / .08), 0 2px 0 #050504, 0 10px 20px -10px rgb(0 0 0 / .8);
  /* Depth (MOTION §1.4 names): black swallows shadows, so every raised surface carries a 1px light rim. */
  --z1: inset 0 1px 0 rgb(255 255 255 / .05), 0 0 0 1px rgb(255 255 255 / .07), 0 1px 2px rgb(0 0 0 / .6);
  --z2: inset 0 1px 0 rgb(255 255 255 / .07), 0 0 0 1px rgb(255 255 255 / .08), 0 14px 36px -12px rgb(0 0 0 / .8);
  --shadow: 0 0 0 1px rgb(255 255 255 / .1), 0 50px 100px -30px rgb(0 0 0 / .9), 0 24px 48px -24px rgb(0 0 0 / .7);
  --glare: rgb(255 255 255 / .08);
  --grain: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='160' height='160'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.85' numOctaves='3' stitchTiles='stitch'/%3E%3CfeColorMatrix values='.33 .33 .33 0 0 .33 .33 .33 0 0 .33 .33 .33 0 0 0 0 0 0 .06'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
  --font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI Variable Text", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, Consolas, monospace;
  --font-num: var(--font-mono);       /* readouts like a spec sheet */
  --r-s: 6px; --r-m: 10px; --r-l: 14px; --r-xl: 20px; --r-btn: 12px;
  /* MOTION.md §1.7: --ease-*, --t-*, --persp-* unchanged, here. */
}
@media (prefers-contrast: more) {
  :root {
    /* text 17.8:1, text-2 9.4:1, accent 15.1:1; on-button on button 16.2:1. */
    --text: #ffffff; --text-2: #bdbdb4; --accent: #d8fa6a; --on-button: #000000;
    --line: #4a4a44; --header: rgb(12 12 11 / .9);
  }
}
```

`layout.html`: `<meta name="color-scheme" content="dark">` and one `theme-color`, `#0a0a09`. The `.report` card keeps
its fixed light colours (the app's PNG); it is the brightest object on the page, on purpose.

**Why lime.** Hi-vis is the inspector's colour. At about 73° of hue it sits well away from verdict green (135°), from
Whydunit's blue, and from the purple gradient that now reads as a generic startup. Verdicts keep system green, orange
and red, always with a symbol and a word.

**Identity pieces**

```css
.eyebrow { font: 600 12px/1.2 var(--font-mono); letter-spacing: .06em; color: var(--text-2); }   /* sentence case */
.eyebrow b { color: var(--accent); }                                                              /* "<b>01</b> · What goes wrong" */
.ticks { height: 8px; margin: 10px 0 20px; background: repeating-linear-gradient(90deg, rgb(255 255 255 / .2) 0 1px, transparent 1px 10px);
  -webkit-mask-image: linear-gradient(90deg, #000 40%, transparent); mask-image: linear-gradient(90deg, #000 40%, transparent); }
```

Section heads are left-aligned (drop the `center` class): confidence reads left-aligned, calm reads centered, and it
keeps the two siblings apart.

### 4.2 Home page, section by section

| # | Section | Composition | Motion (MOTION.md) |
|---|---|---|---|
| 0 | Header pill | icon, wordmark · What it checks, Tests, Guides, FAQ · **Source** · **Download** (lime) | none |
| 1 | Hero | ≥1100px: copy left (5fr), the **bay** right (7fr); below: stacked. Eyebrow, two-tone h1, lede, Download + View source, mono facts line | §4.1 sequence, flip button, 5° tilt |
| 2 | Proof strip | `dl.proof` in mono: **0** "network calls" · **0** "changes to the Mac" · **6** "hands-on tests" · **≈2 min** "for every check" | reveal |
| 3 | `01 · The listing says` (replaces "What goes wrong") | h2 "The listing says it's fine. *Check anyway.*"; three `.pair`s: the seller's claim in quotes ("Signed out of everything", "Battery is great", "Not a work laptop") under a finding card with a verdict `.tag` and the app's fixed string, e.g. `.tag.bad` Walk away + 'Assigned to "Acme Corp" in Apple Business. After it's erased, it will lock itself to them again.' | finding cards: tilt, glare, reveal |
| 4 | `02 · What it checks` | the existing table as a spec sheet: `.table-scroll.instrument`, caliper `.ticks` above, mono headers, source commands in dim mono, `tabular-nums` | none: data stays still |
| 5 | `03 · Then test what you'll touch` | six `.card.key` tiles with a recessed `.well` lime symbol, name, one line | reveal, 7° tilt |
| 6 | `04 · A report card you can share` | two columns: the checklist card; a static **paper fan** (§4.4) | 4° tilt on the fan |
| 7 | `05 · What it can't tell you` and `It will never…` | two columns: the limits card with question wells; the "never" card with a lock well and a lime hairline top | none |
| 8 | `06 · Runs offline. Sends nothing…` | four `.card`s with lime wells | reveal, tilt |
| 9 | `07 · Guides` | four `a.card.key` "manual" cards: mono index G1–G4, title, one line, an arrow that nudges 2px on hover | reveal, tilt |
| 10 | Questions | `.faq`, left-aligned head | unfold |
| 11 | Finale | `.finale .panel`: the icon standing on the lime horizon with a reflection, "Check it before you pay. *It's free.*", the button, the facts line | icon tilt 12° |
| 12 | Footer | slab, official-sources line, trademark line | none |

### 4.3 Hero: the inspection bay

MOTION.md §4.1's sequence is kept (lid opens, beam sweeps, chips fly to the card, rows fill, the corner button
flips the card). It gains the world, materials, contact shadows and an overlap: the laptop stands back-left at
`translateZ(-60px)`, the white card leans in front-right at `translateZ(70px)`, overlapping the deck. The overlapping
planes are the 3D. Below 1100px it stacks: copy, laptop, card (MOTION's phone layout, prototyped at 375px).

```html
<section class="hero" aria-labelledby="hero-h">
  <div class="wide hero-grid">
    <div class="hero-copy">
      <p class="eyebrow"><b>Used-Mac inspector</b> · macOS {{minMacOS}} or later</p>
      <h1 id="hero-h">Kick the tires <span class="dim">before you pay.</span></h1>
      <p class="lede">Locks, battery, SSD, keys, screen and updates in about two minutes. Then a report card you can share.</p>
      <p class="actions">
        <a class="button" href="/download/"><svg aria-hidden="true"><use href="#i-down"/></svg><span class="sep" aria-hidden="true"></span>Download free</a>
        <a class="button secondary" href="https://github.com/{{releasesRepo}}">View source</a>
      </p>
      <p class="facts mono">Free · Runs offline · Sends nothing · Changes nothing</p>
    </div>
    <div class="stage bay" data-tilt>
      <i class="horizon" aria-hidden="true"></i>
      <div class="scene"><!-- MOTION.md §4.2 unchanged: .mac (lid, screen, beam, chips) + .card-wrap (flip, faces, flip button) --></div>
    </div>
  </div>
  <p class="small dim center">Illustration with sample data. “Acme Corp” is made up.</p>
</section>
```

```css
/* The bay (DESIGN.md §4.3): graphite floor with tread marks fading into the dark, an overhead key light, a lime
   spill under the laptop and one lit horizon line. Static paint; only MOTION's planes move. */
.hero { overflow: clip; padding-top: clamp(64px, 9vw, 104px); }
.hero-grid { display: grid; gap: clamp(40px, 6vw, 72px); align-items: center; }
.hero-copy { text-align: center; }
.hero .lede { margin-inline: auto; }
.facts.mono { font-family: var(--font-mono); font-size: 12px; }
.stage.bay { padding: 56px clamp(12px, 4vw, 56px) 72px; }
.stage.bay::before { inset: 0; background: var(--grain), radial-gradient(60% 50% at 50% 0%, var(--key), transparent 70%), linear-gradient(#131311, #0d0d0b 58%, #0a0a09); }
.stage.bay::after { content: ""; position: absolute; z-index: -1; inset: auto 0 0; height: 42%; border-radius: 0 0 var(--r-xl) var(--r-xl); pointer-events: none;
  background: radial-gradient(50% 60% at 50% 0%, var(--glow), transparent 70%), var(--tread);
  -webkit-mask-image: linear-gradient(#000, transparent 92%); mask-image: linear-gradient(#000, transparent 92%); }
.horizon { position: absolute; z-index: -1; left: 0; right: 0; top: 58%; height: 1px; pointer-events: none;
  background: linear-gradient(90deg, transparent, var(--horizon) 50%, transparent); box-shadow: 0 0 28px 2px var(--glow); }
/* Materials for MOTION's laptop: graphite lid, bright bezel edge, aluminium deck, a lime-lit screen and beam. */
.lid { background: linear-gradient(160deg, #2a2b2e, #151618); box-shadow: inset 0 0 0 1px rgb(255 255 255 / .12), inset 0 1px 0 rgb(255 255 255 / .18); }
.deck { background: linear-gradient(#d9dadd, #8e9095); box-shadow: inset 0 1px 0 #fff; }
.screen { background: radial-gradient(80% 70% at 50% 40%, #1a2410, #07090b); }
.screen img { border-radius: 22%; box-shadow: 0 0 40px rgb(198 242 60 / .25); }
.beam { background: linear-gradient(transparent 42%, rgb(198 242 60 / .55) 50%, transparent 58%); }
/* Contact shadows: a radial gradient, nothing to repaint. VERIFY in Safari that they sort behind their object;
   if not, make them plain sibling elements. */
.mac::after, .card-wrap::after { content: ""; position: absolute; left: 8%; right: 8%; bottom: -18px; height: 24px; z-index: -1; pointer-events: none;
  background: radial-gradient(closest-side, rgb(0 0 0 / .7), transparent); transform: translateZ(-1px); }
/* The card: paper under a key light; the verdict gets a plate so it reads first even as a thumbnail. */
.flip .report { border-radius: 18px; box-shadow: 0 0 0 1px rgb(255 255 255 / .6), 0 30px 60px -16px rgb(0 0 0 / .8), 0 60px 120px -40px rgb(0 0 0 / .9); }
.report-verdict { padding: 14px 16px; border-radius: 14px; background: #ffece9; box-shadow: inset 0 0 0 .5px rgb(255 59 48 / .35); }   /* the sample says Walk away */
.flip-btn { background: #fff; box-shadow: 0 1px 3px rgb(0 0 0 / .2); }
@media (min-width: 1100px) {
  .hero-grid { grid-template-columns: minmax(0, 5fr) minmax(0, 7fr); }
  .hero-copy { text-align: left; } .hero .actions { justify-content: flex-start; } .hero .lede { margin-inline: 0; }
  .bay .scene { display: grid; grid-template-columns: 1fr; gap: 0; }        /* overrides MOTION's 5fr 6fr grid */
  .bay .mac { grid-area: 1 / 1; justify-self: start; width: 62%; margin: 0; transform: translateZ(-60px) rotateX(8deg); }
  .bay .card-wrap { grid-area: 1 / 1; justify-self: end; align-self: end; width: 60%; margin-bottom: -6%; transform: translateZ(70px); }
  .chips { --fly: translate3d(240px, 140px, 60px); }                         /* retune by eye in the Chromium prototype */
}
```

- MOTION's `deal` keyframe has only a `from`, so it now lands on the card's static `translateZ(70px)`.
- The white chips stay white: they read as paper tags that become the card's rows. The laptop keeps fixed colours.
- Between 900 and 1100px MOTION's side-by-side grid applies unchanged.

### 4.4 Section recipes

```css
/* Key-caps: test tiles, guide cards, export chips. Keyboard DNA for a Mac inspector. */
.key { background: linear-gradient(var(--cap-top), var(--cap-bot)); box-shadow: var(--cap); }
.key .well { color: var(--accent); background: var(--well); box-shadow: inset 0 2px 4px rgb(0 0 0 / .6), 0 1px 0 rgb(255 255 255 / .06); }
a.key { color: inherit; }
a.key:active { translate: 0 1px; }                                          /* MOTION's scale .97 also applies */
a.key .arrow { display: inline-block; margin-left: 6px; color: var(--accent); }
@media (prefers-reduced-motion: no-preference) { a.key .arrow { transition: translate var(--t-fast) var(--ease-out); } a.key:hover .arrow { translate: 2px 0; } }
/* Spec sheet: the checks table as an instrument face. */
.instrument { padding: 6px 20px; border-radius: var(--r-l); background: var(--card); box-shadow: var(--z2); }
.instrument thead th { font: 500 12px/1.3 var(--font-mono); letter-spacing: .04em; color: var(--text-2); }
.instrument td, .instrument th { border-color: var(--line); font-variant-numeric: tabular-nums; }
.instrument code, .prose pre, .face.back code { background: var(--well); color: var(--text-2); box-shadow: inset 0 0 0 .5px rgb(255 255 255 / .06); }
/* Pairs, three across. */
.pairs { display: grid; gap: 36px 20px; margin-top: 48px; grid-template-columns: repeat(auto-fit, minmax(min(100%, 300px), 1fr)); }
.pair .claim { font-style: italic; }
/* Paper fan: two sheets under the key light. Skeleton lines only, so it costs about 300 bytes of HTML. */
.fan { position: relative; aspect-ratio: 4 / 3; perspective: var(--persp-card); }
.fan .sheet { position: absolute; inset: 10% 12%; padding: 8%; border-radius: 12px; background: #fff; box-shadow: 0 30px 60px -16px rgb(0 0 0 / .8), 0 0 0 1px rgb(255 255 255 / .5); }
.fan .sheet.pdf { rotate: 5deg; translate: 8% -5%; background: #f5f5f7; }
.fan .sheet.png { rotate: -4deg; }
.fan i { display: block; height: 8px; margin: 8px 0; border-radius: 4px; background: #e5e5ea; }
.fan i:first-child { width: 40%; height: 14px; background: #1d1d1f; }
/* The "never" card: a lock well and a lime hairline along the top. */
.never { box-shadow: var(--z2), inset 0 1px 0 var(--horizon); }
.never .well { color: var(--accent); }
/* Finale: the icon standing on the lime horizon with a reflection. */
.finale .panel { background: var(--grain), radial-gradient(60% 45% at 50% 100%, var(--glow), transparent 70%), var(--bg-alt); }
.finale .obj { position: relative; width: 112px; margin: 0 auto 64px; }
.finale .obj .icon { margin: 0; }
.finale .obj img + img { position: absolute; top: 100%; left: 0; transform: scaleY(-1); opacity: .22; filter: none;
  -webkit-mask-image: linear-gradient(to top, #000, transparent 55%); mask-image: linear-gradient(to top, #000, transparent 55%); }
.finale .obj::after { content: ""; position: absolute; left: -140%; right: -140%; top: 100%; height: 1px;
  background: linear-gradient(90deg, transparent, var(--horizon), transparent); box-shadow: 0 0 24px 1px var(--glow); }
```

Markup notes: the finale and download page use two `<img src="/icon.png" width="112" height="112" loading="lazy">`;
the second has `alt=""` and `aria-hidden="true"` (one URL, one request). The tilt `data-tilt` goes on the first. Test
tiles are `div`s and don't press (no fake key legends: Tirekick has no shortcuts); guide and export tiles are links
and do.

### 4.5 Sub-pages, Tirekick specifics

- **Download:** the icon on the lime horizon (the finale `.obj` in a 220px `.panel`), then "Only from
  github.com/EverydayOpen/tirekick/releases."
- **404:** a 240px bay with MOTION's laptop, lid open, "Nothing here to inspect.", Home.
- **Guides:** the meetup checklist prints on white with no shadows (shared print rules); checklist boxes keep
  `accent-color: var(--button)`.

## 5. Tirekick app (macOS 13; macOS 14+ and 26 only in `Compat.swift`). Written, not compiled.

### 5.1 Window and chrome

- `.windowStyle(.hiddenTitleBar)` on the `Window` scene (macOS 11). The window is still titled "Tirekick" for the
  Window menu, Mission Control and VoiceOver, and still fixed at 720×560. The bay runs full-bleed under the traffic
  lights, as in Mole. VERIFY that the window still drags from the top strip; if not, keep the title bar and put
  `StepBar` at the top of the content.
- **`StepBar`** replaces the missing sidebar and toolbar as orientation: Mole's capsule tab bar, centered at the top,
  level with the traffic lights, display only.
- The bottom bar loses its `Divider` and floats on `.regularMaterial` in a capsule: Back on the left, the hi-vis
  Continue on the right.

### 5.2 Tokens (`App/DesignSystem/Tokens.swift`, plus §3.1's `well`, `lifted`, `Tag`)

```swift
enum Brand {
    /// Hi-vis lime: the one prominent button, the beam, tested keys. Black text on it. Lime text is unreadable on
    /// white, so text and symbols use `hiVisInk` (olive in light mode).
    static let hiVis = Color(red: 0.776, green: 0.949, blue: 0.235)                   // #C6F23C
    static let hiVisInk = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.804, green: 0.961, blue: 0.290, alpha: 1)                // #CDF54A
            : NSColor(red: 0.247, green: 0.384, blue: 0.071, alpha: 1)                // #3F6212, 6.4:1 on white
    })
}

/// The bay: warm graphite with an overhead key light (dark), a daylight workshop (light). Static, drawn once.
/// Increase Contrast gets the plain window background.
struct Bay: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let dark = scheme == .dark
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            if contrast != .increased {
                LinearGradient(colors: dark ? [Color(red: 0.075, green: 0.075, blue: 0.07), Color(red: 0.04, green: 0.04, blue: 0.035)]
                                            : [Color(white: 0.97), Color(white: 0.91)],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [.white.opacity(dark ? 0.07 : 0.6), .clear], center: .top, startRadius: 0, endRadius: 420)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Where you are, Mole-style: the four steps in one capsule, the current one lit. Not a control (Back and Continue
/// move), so AppModel doesn't change. VoiceOver: "Step 2 of 4: Checks".
struct StepBar: View {
    let current: AppModel.Step
    @Namespace private var lit
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(AppModel.Step.allCases, id: \.self) { step in
                Text(title(step))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(step == current ? Color.black : Color.secondary)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background { if step == current { Capsule().fill(Brand.hiVis).matchedGeometryEffect(id: "lit", in: lit) } }
            }
        }
        .padding(3)
        .background(.regularMaterial, in: Capsule())
        .animation(reduceMotion ? nil : Motion.spring(false), value: current)
        .allowsHitTesting(false)                                   // drags pass through to the window
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current.rawValue + 1) of \(AppModel.Step.allCases.count): \(title(current))")
    }

    private func title(_ step: AppModel.Step) -> String {
        switch step {
        case .welcome: "Start"
        case .checks: "Checks"
        case .tests: "Tests"
        case .report: "Report"
        }
    }
}

/// The one prominent button per screen (Continue, Save PNG…): hi-vis fill, black label, a machined lower edge.
/// Replaces .borderedProminent there; .keyboardShortcut(.defaultAction) still works on any Button.
struct HiVisButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Body(configuration: configuration) }

    private struct Body: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var enabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
            configuration.label
                .font(.body.weight(.semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 18).frame(minHeight: 30)
                .background(shape.fill(Brand.hiVis))
                .overlay(shape.strokeBorder(.white.opacity(0.4), lineWidth: 0.5))
                .overlay(alignment: .bottom) { shape.fill(.black.opacity(0.22)).frame(height: 1.5).clipShape(shape) }   // the machined lower edge
                .compositingGroup()
                .shadow(color: Brand.hiVis.opacity(configuration.isPressed ? 0.12 : 0.3), radius: 10, y: 3)
                .opacity(enabled ? 1 : 0.4)
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
                .animation(Motion.pop, value: configuration.isPressed)
        }
    }
}

/// Welcome choices and Tests tiles: a key-cap. Raised fill, lit top edge, hairline; sinks 1pt when pressed.
/// Replaces MOTION §5.1's TileButtonStyle and keeps its tilt, press and bounce.
struct KeyCapStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Cap(configuration: configuration) }

    private struct Cap: View {
        let configuration: ButtonStyleConfiguration
        @State private var hovers = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @Environment(\.colorScheme) private var scheme
        @Environment(\.colorSchemeContrast) private var contrast

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
            let down = configuration.isPressed && !reduceMotion
            let dark = scheme == .dark
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(Space.m)
                .background {
                    if contrast == .increased {
                        shape.fill(.quaternary)                     // today's fill
                    } else {
                        shape.fill(Color(nsColor: .controlBackgroundColor))
                            .overlay(shape.fill(LinearGradient(colors: [.white.opacity(dark ? 0.08 : 0), .black.opacity(dark ? 0 : 0.035)], startPoint: .top, endPoint: .bottom)))
                            .overlay(shape.strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5))
                            .shadow(color: .black.opacity(dark ? 0.6 : 0.12), radius: 0, y: down ? 0 : 2)   // the key's side
                            .shadow(color: .black.opacity(dark ? 0.4 : 0.08), radius: 8, y: 4)
                    }
                }
                .contentShape(shape)
                .offset(y: down ? 1 : 0)
                .scaleEffect(down ? 0.985 : 1)
                .animation(Motion.pop, value: configuration.isPressed)
                .bounce(on: hovers)                                   // Compat: symbol bounce on macOS 14+
                .modifier(HoverTilt(max: 7))
                .onHover { if $0 && !reduceMotion { hovers += 1 } }
        }
    }
}
```

VERIFY: Full Keyboard Access draws a focus ring on `HiVisButtonStyle` and `KeyCapStyle` buttons; `NSColor(name:
dynamicProvider:)` on macOS 13; `matchedGeometryEffect` inside a `background` closure. `Compat.swift` stays as MOTION
§5.2 (`bounce`, `scrollLean`); glass on 26 is not needed and not added.

### 5.3 Screens

- **Welcome** on `Bay()`: MOTION §5.3's `LaptopView` (lid opens once, 8° tilt) standing on a floor line,
  `Rectangle().fill(LinearGradient(colors: [.clear, Brand.hiVis.opacity(0.5), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)`,
  with a lime spill `RadialGradient` under it. Laptop materials: graphite lid gradient, a white 0.5pt bezel highlight,
  an aluminium deck `LinearGradient([Color(white: 0.85), Color(white: 0.56)])`, a screen glowing from `#1a2410` to
  black. Title in `.system(size: 28, weight: .bold)` with `.fontWidth(.expanded)` (VERIFY macOS 13; drop it if not).
  The two choices are `KeyCapStyle` tiles with symbols in `Brand.hiVisInk`. The meetup tip sits in a recessed note
  well: `RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.25))` in dark, `.quaternary` in light, with
  `lightbulb` in `.well(.secondary, size: 28)`. The privacy line stays a footnote in `.monospaced()`. Height: laptop
  106 plus the existing stack fits 560, and the hidden title bar gives back about 28pt.
- **Checking** (`facts == nil`): `LaptopView(scanning: true)` with the beam in `Brand.hiVis`, the small
  `ProgressView` and "Checking this Mac…" (MOTION §5.4).
- **Checks:** `Form(.grouped)` with `.scrollContentBackground(.hidden)` over `Bay()`. Verdict banner:
  `VerdictIcon(size: 28).well(verdict.color, size: 56)` on a neutral white key-light radial (never the verdict colour),
  `bannerTitle` in `.system(size: 26, weight: .bold)`, the summary line, "Check Again" `.bordered`; the split-flap swap
  is MOTION's. Rows: native, plus a trailing `Tag(text: check.verdict.word, tint: check.verdict.color)`. Evidence
  output boxes become terminal wells: `.padding(Space.s).background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8, style: .continuous))`
  in `.caption.monospaced()`, selectable. "What you're buying" values in `.monospacedDigit()`.
- **Tests:** `KeyCapStyle` tiles; the symbol in a recessed `.well(.secondary, size: 44)` tinted `Brand.hiVisInk`,
  the result as a `Tag` (Passed green, Problem red, Skipped gray). Keyboard test: keys already registered get a hi-vis
  backlight (`Brand.hiVis.opacity(0.85)` fill, black legend); lime means "registered", never "passed". Held keys sink
  (MOTION §5.5). Full-window test scaffolds stay still.
- **Report,** the studio stage: `Bay()` with a brighter key light; the card sits on a studio panel
  (`RoundedRectangle(cornerRadius: 20)` filled white 0.97→0.90 in light, 0.17→0.10 in dark, 0.5pt separator stroke).
  Card motion: MOTION §5.6 deal-in, `HoverTilt(max: 4, glare: true)`, `lifted()`, and a contact ellipse
  `Ellipse().fill(.black.opacity(0.5)).blur(radius: 10)` under it (static). Controls under the card: Mask serial left;
  right: **Save PNG…** in `HiVisButtonStyle`, Save PDF… and Copy `.bordered`. "What Tirekick can't tell you" stays a
  quiet list.
- **`ReportCardView` refresh** (the shared PNG; owner approval needed because every shared PNG changes). Always light,
  600pt, pure SwiftUI. Keep the 40pt icon and title; add a 2pt `Brand.hiVis` rule under the header; the verdict on a
  plate so it reads first as a thumbnail:

  ```swift
  HStack(spacing: Space.s) {
      VerdictIcon(verdict: card.verdict, size: 34, showsWord: false).accessibilityHidden(true)
      VStack(alignment: .leading, spacing: Space.xxs) {
          Text(card.headline).font(.system(size: 30, weight: .bold)).tracking(-0.4)
          if let summary = card.summary { Text(summary).font(.title3).fixedSize(horizontal: false, vertical: true) }
      }
  }
  .padding(Space.m)
  .frame(maxWidth: .infinity, alignment: .leading)
  .background(card.verdict.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(card.verdict.color.opacity(0.28), lineWidth: 1))
  ```

  Row badges become capsules: `.caption.weight(.bold)`, `.textCase(.uppercase)` (BUILD_PLAN §8 allows the card's
  small-caps badges), primary text on `verdict.color.opacity(0.14)`; the 124pt column stays. Footer unchanged. Check
  readability at a 300px thumbnail. The site's `.report` figure mirrors the plate.

**Acceptance (app).** Everything outside `Compat.swift` is a macOS 13 API; macOS 13 is the full design. The only
loop is the beam. `ReportCardView` gets no effects unless the refresh is approved. VoiceOver announcements are
unchanged, and `StepBar` reads "Step 2 of 4: Checks".

## 6. Icon and social image (infra: `tools/make_icon.py`, `tools/make_og.py`)

- **Icon.** Keep the graphite squircle with tread chevrons and the laptop. Body: brushed graphite `#3A3B40` →
  `#151618` with the chevrons embossed at 6% and a specular arc on the top edge. Laptop: aluminium `#F2F3F5` →
  `#C9CCD1` with a silver lid edge. The check turns hi-vis (`#C8F53A` → `#8BD62A`) with a soft glow: it is the brand
  mark, not a verdict, and it is not verdict green. Later, on a Mac: an Icon Composer `.icon` (VERIFY on 26).
- **OG (1200×630).** The graphite floor with the lime horizon, the icon standing with a reflection, the white
  wordmark left, and the card turned slightly off the right edge.

## 7. What to delete from the current look

- The 128px icon as the hero and the product name as the h1; the centered section heads; the `.band` sections and
  `section:not(.band) .card`.
- Apple.com's stock palette (`#0071e3`, `#f5f5f7`, `#1d1d1f`, pure `#000` dark), the untinted grey `--shadow`, the
  flat `--bg-alt` card slabs, the bare-hairline FAQ, the sticky header bar, the grey footer block.
- "What goes wrong with used Macs" as three grey cards (it becomes the listing-says pairs). The blue beam.
- In the app: the standard title bar with nothing in it, the 96pt icon on an empty pane, `.quaternary` tiles, the
  bottom bar's `Divider`, `.borderedProminent` in the user's accent for Continue (it becomes hi-vis), the report card
  as a generic list.

## 8. Acceptance and budgets

**Looks premium (a judge checks these against screenshots at 1440 and 360, base and `prefers-contrast: more`):**

- [ ] The page is warm graphite, never pure black; raised surfaces carry a 1px light rim and a lit top edge.
- [ ] The hero bay shows a laptop behind and a white report card in front, overlapping, on a tread-marked floor with
  one lime horizon; the card is the brightest object on the page.
- [ ] Exactly one accent is visible (lime); verdict colours appear only in tag dots, symbols and the card's plate.
- [ ] Eyebrows are mono with a lime index; readouts and table headers are mono; headlines are tight and two-tone;
  nothing is ALL CAPS.
- [ ] Test tiles read as key-caps (lit edge, dark side); the header is a floating pill; the primary button is lime
  with black text and a lime glow.
- [ ] No band edges; sections are left-aligned and separated by whitespace. No emoji, no stock icon set, no gradient text.
- [ ] The finale icon stands on the lime horizon with a reflection. The footer names the only official site.
- [ ] App: the window has no empty title bar; `StepBar` shows where you are; Continue is the one hi-vis control.

**Functional (on top of MOTION.md §6.2):**

- [ ] `python tools/build_site.py --check` passes after the `--on-button` change; exactly two `:root` blocks.
- [ ] 1440 and 360: no horizontal scroll, the stage is full-bleed at ≤640px, the laptop stacks above the card below
  1100px and the chips fly down.
- [ ] Reduced motion: lid open, rows filled, no chips, beam, deal or tilt; the flip swaps instantly. Reduced
  transparency: solid header. `prefers-contrast: more`: 2px outlines, no grain. Print (meetup checklist): white page,
  no stage, no shadows.
- [ ] JS off: complete and still; the flip button stays hidden. CLS 0; LCP is the h1.
- [ ] Owner, Safari: the 3D sort of the contact shadows and the overlap, `color-mix`, the header glass, dark banding.
- [ ] App (once CI compiles it): MOTION's greps pass; `grep -rn "#available" App/` matches only `Compat.swift`;
  idle CPU 0% within 2 s; Save PNG changes only if the refresh is approved.

**Budgets** (caps from MOTION.md §6.1; measure with `wc -c`):

| Item | Cap | Today | Estimate |
|---|---|---|---|
| `site/static/styles.css` | 40 KB | 11.4 KB (20.4 with MOTION) | about 31 KB |
| `site/static/motion.js` | 5 KB | 2.7 KB (MOTION) | 2.7 KB, byte-identical with Whydunit's |
| Home HTML, built | 30 KB | 21.1 KB | about 27 KB (pairs, proof strip, fan) |
| New fonts, images, scripts, requests | 0 | 0 | 0 |
| App: new files | — | — | `Compat.swift`, `LaptopView.swift` (MOTION); no assets, no dependencies |

## 9. Changes for other owners, decisions for the lead, VERIFY list

**Other owners (proposals, not made here):**

1. **Architect, BUILD_PLAN §7 (frozen):** "standard title bar" → "hidden title bar with `StepBar`"; "System colors
   only; the accent is the user's" → "the user's accent for controls; hi-vis lime only on the one prominent button
   (`HiVisButtonStyle`), the beam and registered keys"; "no card backgrounds on check rows" stays; "`TileButtonStyle`"
   → "`KeyCapStyle`"; the bottom bar "Divider + HStack" → "a material capsule"; add the report card refresh if
   approved, and "Design: docs/DESIGN.md; motion: docs/MOTION.md".
2. **Infra, `tools/build_site.py contrast()`:** `on = "on-button" if "on-button" in light else "#ffffff"`, then
   measure `(on, "button")` and `(on, "button-hover")`. Add the MOTION §6.4 size caps.
3. **Infra:** §2.4 markup, §4, `layout.html` (`color-scheme` dark, one `theme-color`), icon and OG (§6).
4. **AGENTS.md:** add "Design: docs/DESIGN.md (tokens, compositions); motion: docs/MOTION.md."
5. **CI, later:** real window captures for a "See it" gallery, as in the Whydunit spec §9.

**Decisions for the lead:**

- Approve dark-on-every-page for Tirekick (the second `:root` block is `prefers-contrast: more`).
- Approve the report card PNG refresh (§5.3): it changes what every buyer shares.
- "Signed and notarized" enters the facts line and footer only with the signed 1.0 download.
- Copy owner: the new h1, lede, pair copy and proof stats against BUILD_PLAN §8.

**VERIFY:** window dragging with a hidden title bar; `fontWidth(.expanded)` and `NSColor(name:dynamicProvider:)` on
macOS 13; focus rings on the custom button styles; contact-shadow sorting in Safari; the overlap and `--fly` by eye;
`color-mix` and `text-wrap: balance` in Safari; dark banding with the grain.
