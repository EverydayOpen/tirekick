# Design spec: Tirekick (website and app)

**Why:** the owner's verdict (2026-09-29): the sites and apps "look cheap". They must look modern, premium and 3D, on
par with Mole, Recordly, Maccy, Rectangle, VoiceInk and MaCursor, while staying lightweight and secure.
**Authority:** this file is authoritative for visual design (tokens, surfaces, compositions, type). `docs/MOTION.md`
stays authoritative for motion and is referenced by section; §2.8 lists exactly where this file overrides it.
BUILD_PLAN lines that need amending are listed in §9, not amended here. Safety rules, copy, data flow and the
checker's contract are unchanged.
**Shared system:** §1–§3 are identical in the Whydunit repo's `docs/DESIGN.md`; change both together. §4–§9 are
Tirekick's.
**Status:** nothing in this file has been built. Two directions were proposed ("Afterglow", dark-first and
cinematic; "Daylight Native", light-first and object-based); this is the final judgement and the spec builders
implement. Every contrast figure was recomputed with `tools/build_site.py`'s own `contrast()` formula
(`<scratchpad>/final_contrast.py`, 2026-09-29). The Swift is written, not compiled; anything unconfirmed is marked
VERIFY.

## 1. The verdict (shared, identical in both repos)

Judged against the reference captures, the premium references share one mechanism, not one palette: **a real
product object sits inside a small world that has one light source, on a page that is otherwise quiet.** Recordly
(dark page) floats its window over a blue sky; Mole (light page) floats its window over a silk wallpaper; VoiceInk's
social card stands its icon on a lit horizon; MaCursor, the weakest of the six, is a generic dark-blue template with
nothing lit. Rectangle and Maccy, the plainest, put the product on bare white, which is where our sites are today.

Neither proposal wins outright. Each brand takes the direction whose *world* fits its job, and grafts the other's
best mechanics:

| | Whydunit | Tirekick |
|---|---|---|
| Direction | **Daylight Native** (light-first, dark follows the system). | **Night Bay** (dark on every page, in both schemes). |
| Why | iCloud's own language is white and blue; the app is light by default; Mole and VoiceInk prove light reads premium when the product is framed in a world. Calm is the brand. | The white report card must be the brightest object on the page, which only a dark bay gives. A hard lime laser, a floor grid and mono readouts read as an instrument, distinct from every other Mac utility and from Whydunit. |
| World | A **macOS desktop diorama**: a dawn wallpaper with a horizon glow, a menu bar, a Finder window behind, the Whydunit window in front, a notification landing top right. Real Mac objects, no cartoon cloud. | An **inspection bay**: a full-bleed night band, a perspective floor grid, one lime laser line, the CSS laptop behind and the paper report card in front. |
| Grafted from the other | From Afterglow: one key light per scene (the horizon glow), lit top rims on every raised surface, real CI captures only at half scale, small-caps labels, severity only in dots and tags, the sidebar without an orange wall, `Horizon` under one object per stage screen. | From Daylight: the `<mark>` highlighter on the h1, a paper-stack edge on the report card, key-caps that sink on `:active`, the StepBar loses its lime, the verdict header without a box, the `html[lang]` fix, real screenshots below the fold. |
| Accent | Sky blue `#2457E0` (`#3563EA` at night). The app keeps AccentColor. | Hi-vis lime `#C6F23C`, black text on it. Only the one prominent button, the laser, LEDs and eyebrow indices. |
| Type voice | Inter Display 600 headlines, centered hero, `ui-rounded` numerals, pills. | Inter Display 600 headlines, left-aligned hero, `ui-monospace` readouts, 12px machined corners. |
| Signature scroll moment | Three safe fixes as sticky stacking cards; a real-screens filmstrip. | Six key-cap test tiles; a paper fan of the shareable card. |

**Decided, in both brands** (each reverses an earlier rule; the reasons are in the sections named):

1. **One webfont**, Inter Display SemiBold, Latin subset, ≤ 32 KB, byte-identical in both repos (§2.2). The owner
   judges the sites on Windows, where every headline currently renders in Segoe UI Bold: the single cheapest thing on
   either page. Body and UI text stay on the system stack.
2. **Real CI screenshots below the fold**, shown at half their pixel width (§2.6). The hero stays HTML.
3. **Content surfaces are porcelain panels**, never grey grouped cells, in both apps (§3.1). Glass exists only on the
   controls layer, and only where the macOS 26 SDK or `barSurface()` draws it (§3.2).
4. **No serif clause, no `ui-serif`.** VoiceInk's italic is lovely, but a second display voice on top of Inter
   Display is one voice too many, and Windows would render it in Georgia. One display face.
5. **Whydunit keeps its toolbar actions** (BUILD_PLAN §6); no floating selection bar. Tirekick keeps its floating bar.
6. **Icons are unchanged for now.** The OG images are redone (§6). An Icon Composer `.icon` waits for a Mac.

**Not doing, in either brand:** a CDN, a tracker, a second font, a live star count, autoplay video, mesh blobs,
gradient text, emoji icons, glass on content, a nav CTA that hides itself, `style=""` attributes, `data-theme`.

### 1.1 The eight rules

1. **One world per product, and it appears only behind objects:** the hero scene, the fixes' media wells, the finale
   and the download page's icon. Every other section is paper (Whydunit) or graphite (Tirekick), paced by whitespace.
2. **One key light per scene.** Whydunit's is the dawn glow on the wallpaper's horizon; Tirekick's is the lime laser.
   Nothing else glows, and a glow is never severity-coloured (MOTION §1.1 rule 3).
3. **Light, not lines.** Every raised surface has a lit top edge (`inset 0 1px 0`), a 0.5px hairline (a 1px light
   rim in dark, because black swallows shadows) and a shadow tinted with the brand's ink, never neutral grey, never
   animated (MOTION §1.4).
4. **One accent.** Green, orange and red mean a status and appear only in 6px dots, symbols and tag fills behind
   primary text. Severity never gets a coloured panel: a red "Walk away" is set exactly like a green "Clean".
5. **Objects, not illustrations.** Every product visual is a faithful Mac object: a window, a sheet, a notification,
   a Finder list, the report card, the laptop. No cartoon clouds, orbs or glossy coins.
6. **Everything you can press is a key-cap:** a gradient lighter at the top, a lit rim, a hairline, a side wall in
   Tirekick, and a press that sinks 1–2px with the shadow swapped instantly (never transitioned).
7. **Concentric radii:** outer radius = inner radius + padding. Whydunit 8/12/18/28 and pills; Tirekick 6/10/14/20
   and 12px buttons. Grain (≤ 6%, inline SVG) only on wallpaper and bay gradients, never under body text.
8. **The apps stay native.** Navigation, tables, sheets, Settings, the toolbar and the inspector are system parts.
   Premium comes from the wash, porcelain panels, one lifted object per stage screen, the accent, tags, key-caps and
   the precision of the type. Nothing moves at idle.

## 2. Shared web foundation

### 2.1 The contract with `tools/build_site.py`

- `contrast()` reads exactly two `:root { }` blocks and only 6-digit hex tokens. Whydunit's blocks are light then
  `@media (prefers-color-scheme: dark)`. Tirekick's are the base (dark) palette then `@media (prefers-contrast:
  more)`. Every other override sits on `html[lang]` (§2.7), never on a third `:root`.
- Hero copy sits on `--bg` in both brands (the diorama and the bay are behind objects only), so no new pairs are
  needed. The window replica (`--win-*`) and the report card (`--paper*`) are `role="img"` pictures, not measured.
- `data-theme` and `localStorage` must not appear anywhere, including comments.
- Tirekick's `CSP` constant and `layout.html` meta must gain `font-src 'self'` (tools owner, §9). Whydunit's
  `default-src 'self'` already permits the font.
- `build_site.py` rewrites `href="/` and `src="/`; it must also rewrite and link-check `srcset="/` before the real
  screens ship (§2.6; tools owner).

### 2.2 Type: Inter Display for headlines, the system for everything else

**File.** Inter Display SemiBold from Inter 4.x (SIL OFL 1.1, `github.com/rsms/inter` releases), subset once to
Latin with fonttools on a dev machine (a one-off, not a repo tool), committed with `OFL.txt` at
`site/static/fonts/InterDisplay-SemiBold.woff2` in both repos, byte-identical. Expected 20–30 KB; the cap is 32 KB
(VERIFY after subsetting). `font-display: optional` plus a preload: it paints on the first frame or not at all for
that view, so CLS is 0 and the h1 stays the LCP.

```css
/* Relative URL: the site is served under a project path and the build doesn't rewrite CSS url(). */
@font-face { font-family: "Inter Display"; src: url("fonts/InterDisplay-SemiBold.woff2") format("woff2"); font-weight: 600; font-style: normal; font-display: optional; }
```
```html
<!-- layout.html, before the stylesheet; the build prefixes href="/ -->
<link rel="preload" href="/fonts/InterDisplay-SemiBold.woff2" as="font" type="font/woff2" crossorigin>
```

Stacks (first `:root` block):

```css
--font: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI Variable Text", "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
--font-display: "Inter Display", -apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI Variable Display", "Segoe UI", sans-serif;
--font-mono: ui-monospace, "SF Mono", SFMono-Regular, Menlo, "Cascadia Mono", Consolas, monospace;
```

**Type ladder.** Put this comment at the top of both `styles.css` files; no size outside it.

```css
/* Type ladder (docs/DESIGN.md §2.2). Display = var(--font-display) 600; everything else = var(--font).
   h1       display  clamp(2.75rem, 1.5rem + 4.8vw, 5.25rem) / 1.0,  -.038em, text-wrap: balance
   h2       display  clamp(2rem, 1.35rem + 2.6vw, 3.25rem)   / 1.04, -.032em, balance
   feature  display  clamp(1.5rem, 1.2rem + 1vw, 2rem)       / 1.1,  -.025em
   card h3  system   17px / 1.3, -.015em, 600
   lede     system   clamp(1.125rem, 1rem + .45vw, 1.3125rem) / 1.45, -.012em, --text-2
   body     17px / 1.55, -.011em        small 15px / 1.5        meta 13px / 1.4, 500
   numerals display, tabular-nums: 40px (proof strip), 64–88px (finale)
   labels   13px 600 with font-variant-caps: all-small-caps and .04em tracking (styling, not ALL CAPS copy)
   eyebrow  Whydunit 13px 600 --accent · Tirekick 12px 500 mono "01 · Checks", index in --accent
   numerals in UI: Whydunit ui-rounded, Tirekick ui-monospace, both tabular */
h1, h2, .display, .feature h3, .proof dd, .brand { font-family: var(--font-display); font-weight: 600; }
```

Weight 600, not 700: at 44–84px, Inter Display SemiBold at −.038em reads engineered; Bold reads loud. Recordly
makes the same choice. Two-tone headings stay (`<span class="dim">`); numbers that line up are `tabular-nums`.

### 2.3 Space, widths and radii

- Widths: `.wrap` 1080px (content), `.wide` 1240px (stages), `.read` 720px (prose, FAQ). Gutter 20px, 16px under 480.
- `main > section { padding-block: clamp(72px, 10vw, 136px) }`: more silence, fewer sections. Gaps are 12, 16, 24,
  32, 48 or 64px. `scroll-padding-top: 84px`.
- Radii tokens `--r-s / --r-m / --r-l / --r-xl` and `--r-btn` come from each brand's `:root`.

### 2.4 Light and depth (MOTION §1.4 names, retuned values)

Every shadow and hairline is the brand's ink at an alpha. Light recipe (dark values are in each brand's tokens):

| Token | Role | Recipe |
|---|---|---|
| `--hi` | lit top edge on raised surfaces | `rgb(255 255 255 / .9)`; dark `/ .06` |
| `--z1` | hairline plus contact: rows, pills, the header | `0 0 0 .5px ink/.12, 0 1px 2px ink/.05` |
| `--z2` | porcelain card | `inset 0 1px 0 var(--hi), 0 0 0 .5px ink/.12, 0 2px 4px ink/.04, 0 12px 28px -12px ink/.16` |
| `--shadow` | a floating object on paper | `0 0 0 .5px ink/.22, 0 2px 4px ink/.06, 0 24px 48px -16px ink/.30, 0 64px 128px -32px ink/.34` |
| `--shadow-win` | a window on the wallpaper | `0 0 0 .5px rgb(0 0 0 / .28), 0 2px 6px rgb(0 0 0 / .08), 0 28px 56px -12px wp-ink/.45, 0 72px 140px -24px wp-ink/.5` |
| `--cap` | key-caps (buttons, pills, test keys) | `inset 0 1px 0 var(--hi), 0 0 0 .5px ink/.18, 0 1px 2px ink/.08, 0 4px 10px -4px ink/.12` |

In dark every shadow is black at .5–.8 and the hairline becomes a `0 0 0 1px rgb(255 255 255 / .07–.10)` rim. Never
animate `box-shadow` or `filter`; a state swap with no transition is fine.

### 2.5 Shared components (identical CSS in both repos; tokens differ)

These replace the current rules of the same name. Everything else in the current files stays.

```css
/* Header pill: 48px, the only backdrop-filter on the page. */
.nav { height: 48px; max-width: 980px; padding: 0 6px 0 14px; border-radius: 999px; background: var(--header);
  -webkit-backdrop-filter: saturate(180%) blur(20px); backdrop-filter: saturate(180%) blur(20px);
  box-shadow: inset 0 1px 0 var(--hi), var(--z1); }
.brand { font-size: 17px; letter-spacing: -.02em; }

/* Section head: editorial, left-aligned; heading left, lede right on wide screens. */
.sec-head { display: grid; gap: 16px 64px; align-items: end; margin-bottom: clamp(40px, 5vw, 64px); }
@media (min-width: 900px) { .sec-head { grid-template-columns: 7fr 5fr; } }
.sec-head h2, .sec-head .lede { margin: 0; }

/* Primary button: a key-cap whose fill only darkens downward, so the label keeps its measured contrast. */
.button { border-radius: var(--r-btn); min-height: 48px; padding: 0 22px; font: 600 16px/1 var(--font); color: var(--on-button);
  background: linear-gradient(var(--button), color-mix(in srgb, var(--button) 88%, #000));
  box-shadow: inset 0 1px 0 rgb(255 255 255 / .3), inset 0 -1px 0 rgb(0 0 0 / .18), var(--cap); }
.button.secondary { color: var(--text); background: linear-gradient(var(--cap-top), var(--cap-bot)); box-shadow: var(--cap); }
.button:active { translate: 0 1px; box-shadow: inset 0 1px 0 rgb(255 255 255 / .3), 0 0 0 .5px rgb(var(--ink) / .18); }

/* Porcelain card. */
.card { border-radius: var(--r-l); background: var(--card); box-shadow: var(--z2); }

/* Proof strip: hairlines only, no box. */
.proof { display: grid; grid-template-columns: repeat(4, 1fr); gap: 0; border-block: 1px solid var(--line); }
.proof div { padding: 24px 28px 24px 0; } .proof div + div { border-left: 1px solid var(--line); padding-left: 28px; }
.proof dd { font: 600 clamp(28px, 3.2vw, 44px)/1 var(--font-display); letter-spacing: -.03em; font-variant-numeric: tabular-nums; }
@media (max-width: 720px) { .proof { grid-template-columns: 1fr 1fr; } .proof div:nth-child(odd) { border-left: 0; padding-left: 0; } }

/* Ledger: rules as a spec sheet. Replaces icon-well card grids. */
.rules { margin: 0; padding: 0; list-style: none; border-top: 1px solid var(--line); }
.rules li { display: grid; grid-template-columns: 1fr auto; gap: 4px 24px; padding: 20px 0; border-bottom: 1px solid var(--line); }
.rules h3 { margin: 0; font: 600 17px/1.3 var(--font); letter-spacing: -.015em; }
.rules p { margin: 0; color: var(--text-2); font-size: 15px; }
.rules code { grid-column: 2; grid-row: 1 / span 2; align-self: center; }

/* FAQ: one grouped panel with hairline rows (System Settings), not a stack of cards. "+" turns into "×", no JS. */
.faq-list { border-radius: var(--r-l); background: var(--card); box-shadow: var(--z2); }
.faq-list details { padding-inline: 20px; } .faq-list details + details { border-top: 1px solid var(--line); }
.faq-list summary::after { content: "+"; transition: rotate var(--t-base) var(--ease-spring); }
.faq-list details[open] summary::after { rotate: 45deg; }

/* Real screens: a scroll-snap filmstrip (§2.6). Keyboard-scrollable, no lightbox, no JS. */
.film { display: grid; grid-auto-flow: column; grid-auto-columns: min(560px, 84vw); gap: 24px; overflow-x: auto;
  scroll-snap-type: x mandatory; overscroll-behavior-x: contain; padding: 8px 20px 36px; scrollbar-width: thin; }
.film figure { margin: 0; scroll-snap-align: center; }
.film img { display: block; width: 100%; height: auto; border-radius: 10px; background: var(--win-bg); box-shadow: var(--shadow); }
.film figcaption { margin-top: 12px; font-size: 13px; color: var(--text-2); }

/* Finale: the app icon standing on a glossy floor. Chrome and Safari reflect; Firefox simply doesn't. */
.finale .icon { width: 128px; height: 128px; -webkit-box-reflect: below 6px linear-gradient(transparent 62%, rgb(0 0 0 / .22)); }   /* VERIFY inside a 3D parent in Safari */

/* Small-caps labels. */
.label { font: 600 13px/1.3 var(--font); font-variant-caps: all-small-caps; letter-spacing: .04em; color: var(--text-2); }
```

### 2.6 Imagery: an HTML hero, real screenshots below the fold

- **Hero:** an HTML replica of the app (0 image bytes, sharp at any DPI, follows the scheme). Caption: "Illustration
  with sample data". Its copy matches `App/Demo.swift`, so the replica and the CI captures agree.
- **Real screens:** 3 CI captures per brand in the `.film` strip, one image per scheme.
  - **The half-scale rule.** The CI runner's display is 1x: a 1120×760pt window captures at 1136×804 with the
    shadow. An image shown at half its pixel width is exact 2x on Retina, so a 1120px capture is shown at 560 CSS px.
    Never show a capture at a size that upscales it.
  - **Pipeline (CI owner, `screens.yml`):** add a no-shadow variant `screencapture -x -o -l "$ID"`; convert with
    `sips -s format jpeg -s formatOptions 82 in.png --out shots/<screen>-<mode>.jpg` (VERIFY the percent syntax;
    VERIFY whether `sips --formats` lists WebP as writable on the runner and prefer it); cap each file at 110 KB. The
    lead commits the chosen files to `site/static/shots/`; they're our own app.
  - **Markup:** `<picture>` with a dark `<source>`, `width` and `height`, `loading="lazy" decoding="async"`, a
    real `alt`. `img { border-radius: 10px }` hides the JPEG's filled corners (VERIFY by eye against the window
    radius at half scale).
  - Ship the section only once the captures are committed; until then leave it out of the page.

### 2.7 Accessibility media, and a bug to fix first

**Bug (both sites).** The `html { --grain: none; … }` overrides under `prefers-contrast: more` and `@media print`
never apply: `:root` has specificity (0,1,0) and beats `html` (0,0,1) whatever the order (Whydunit `styles.css`
lines 468 and 473, Tirekick 479 and 484). Tirekick therefore prints light text on white paper. Fix: `html[lang] { … }`
(0,1,1) wins, and it doesn't match the checker's `:root\s*\{` regex, so the two-block rule holds. Both `layout.html`
files already set `<html lang="en">`.

```css
@media (prefers-contrast: more) { html[lang] { --grain: none; --glare: transparent; --glow: transparent; }
  .card, details, .nav, .button, .tag, .proof, .faq-list, .note, .window, .report { box-shadow: 0 0 0 2px var(--text); } .finale .icon { -webkit-box-reflect: unset; } }
@media (prefers-reduced-transparency: reduce) { .nav { -webkit-backdrop-filter: none; backdrop-filter: none; background: var(--card); } }
@media (forced-colors: active) { .button, .card, details, .tag, .well, .proof div, .nav, .note { border: 1px solid CanvasText; } }
@media print { html[lang] { color-scheme: light; --bg: #fff; --bg-alt: #fff; --card: #fff; --text: #000; --text-2: #333; --grain: none; }
  .site-header, .site-footer, .skip, .stage, .finale, .film { display: none; } }
```

Also keep: visible 3px focus rings, 44px hit areas, content visible without JS (`.reveal` hides only after
`motion.js` adds `.reveal-io`), no `style=""` (stagger uses `:nth-child`), and every image with `width`/`height`.

### 2.8 What this supersedes in MOTION.md

MOTION.md stays authoritative for motion: tilt, glare, reveal, flips, `motion.js`, the Reduce Motion table and the
performance rules are unchanged and referenced by section. Where the two conflict, this file wins:

| MOTION.md | Now |
|---|---|
| §1.7 `--z1`, `--z2`, `--glare`, `--shadow` values | §2.4 recipes with each brand's ink; names unchanged, so the motion CSS keeps working |
| §1.7 `.button { transition: … }` | §2.5's button (adds `translate` on `:active`, shadow swapped instantly) |
| §2.1 Whydunit story (cloud, rising files, check) | the diorama sequence, 2.0 s (Whydunit §4.3); `.sky`, `.cloud`, `.cloud-ok`, `.doc`, `.ghost` and `upload` are deleted |
| §2.3 `.cloud { fill: … }` | gone with the cloud |
| §4.1 Tirekick story (chips fly from the screen to the card) | laser snaps on, lid opens, card deals in, beam sweeps the card, verdict settles; 2.45 s (Tirekick §4.3). The lid and card-deal keyframes are kept and retimed |
| §4.3 `--tread` floor, `.horizon` bloom, blue `.beam` | perspective floor grid, 1px lime laser with a tight spill, lime beam (Tirekick §4.3) |
| §5.1 `TileButtonStyle` | `KeyCapStyle` with a real side wall (Tirekick §5.2); same tilt, press and bounce |
| §3.4 Summary hero "lands" as a card | the verdict plate (a porcelain surface) lands with the same `flipIn`; the Form is gone (Whydunit §5.2) |
| §1.8 `Sky`/`Bay` as the only backgrounds | `Sky` grows a sun (Whydunit §5.1); `Bay` gets a per-step key light and loses its grey ramp in light (Tirekick §5.1) |

New motion, both within MOTION §1.1's rules: a notification slides in from the right with `--ease-spring`; key-caps
sink 2px on `:active` with the translate transitioned and the shadow swapped; Tirekick's key light moves 0.35 s per
step. Reduce Motion shows final states (MOTION §1.5) throughout.

## 3. Shared app foundation (SwiftUI; written, not compiled)

**Material hierarchy, in order:** the system window (sidebars and toolbars stay system; on macOS 26 the SDK makes
them glass by itself) → a static wash at the top of stage screens (`Sky` / `Bay`) → porcelain surfaces for content
groups → controls. One accent; severity only as symbol tint, tag fill and dot. One lifted object per stage screen.
Nothing moves at idle (MOTION §1.6: zero CPU, springs only, at most 8 `HoverTilt` on screen).

### 3.1 `App/DesignSystem/Tokens.swift` additions (identical in both apps; macOS 13 APIs only)

```swift
extension View {
    /// Porcelain surface: white (a 5.5% white lift in dark), a hairline rim, a tight contact shadow plus a wide soft
    /// one tinted with the brand's ink. Concentric: pass the outer radius; content inside pads by radius - inner.
    /// Replaces grey grouped Form cells and `.quaternary` slabs. Never glass, never on a single row.
    func surface(_ radius: CGFloat = 16) -> some View { modifier(Surface(radius: radius)) }
}

private struct Surface: ViewModifier {
    let radius: CGFloat
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let dark = scheme == .dark, strong = contrast == .increased
        content
            .background(dark ? AnyShapeStyle(Color.white.opacity(0.055)) : AnyShapeStyle(.background), in: shape)
            .overlay { shape.strokeBorder(strong ? Color.primary.opacity(0.5) : Color.primary.opacity(dark ? 0.10 : 0.07), lineWidth: strong ? 1 : 0.5) }
            .compositingGroup()   // glyphs inside don't cast their own shadows (MOTION §1.4)
            .shadow(color: .black.opacity(dark ? 0.35 : 0.05), radius: 1, y: 1)
            .shadow(color: Brand.ink.opacity(dark ? 0.5 : 0.10), radius: 16, y: 8)
    }
}

/// An object standing on a glossy floor: the view, its mirror fading out over 45% of its height, and a still
/// contact shadow. Drawn once. Pass a stateless view: it is drawn twice. None of the mirror under Reduce Transparency.
struct OnFloor<Content: View>: View {
    var height: CGFloat
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        VStack(spacing: 2) {
            content
            if !reduceTransparency {
                content
                    .scaleEffect(x: 1, y: -1)
                    .frame(height: height * 0.45, alignment: .top).clipped()
                    .mask(LinearGradient(colors: [.black.opacity(0.22), .clear], startPoint: .top, endPoint: .bottom))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .background(alignment: .center) {
            Ellipse().fill(.black.opacity(0.16)).frame(width: height * 0.7, height: height * 0.08).blur(radius: 6)
                .offset(y: height * 0.02)   // VERIFY by eye: the ellipse should sit at the object's base
                .accessibilityHidden(true)
        }
    }
}

/// The key light under a lifted object: a pool of light and a thin bright line. Static; drawn once per size.
/// `soft`: Whydunit's dawn bloom. Tirekick passes false: a hard line with a tight spill. Decorative, hidden from VoiceOver.
struct Horizon: View {
    var tint: Color
    var width: CGFloat = 420
    var soft = true
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        ZStack {
            if contrast != .increased {
                RadialGradient(colors: [tint.opacity(soft ? 0.42 : 0.22), tint.opacity(soft ? 0.10 : 0), .clear],
                               center: .center, startRadius: 0, endRadius: width / 2)
                    .frame(width: width, height: width * (soft ? 0.32 : 0.14))
            }
            LinearGradient(colors: [.clear, tint, .white.opacity(0.9), tint, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: width * 0.86, height: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A small-caps label over a big number. One VoiceOver element. Whydunit passes .rounded, Tirekick .monospaced.
struct Metric: View {
    let label: String
    let value: String
    var unit: String? = nil
    var dot: Color? = nil
    var design: Font.Design = .rounded

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption.weight(.semibold).smallCaps()).foregroundStyle(.secondary)   // VERIFY small caps with SF
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let dot { Circle().fill(dot).frame(width: 6, height: 6).accessibilityHidden(true) }
                Text(value).font(.system(size: 26, weight: .semibold, design: design)).monospacedDigit()
                if let unit { Text(unit).font(.callout.weight(.medium)).foregroundStyle(.secondary) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
```

`Brand.ink`: Whydunit navy `Color(red: 0.06, green: 0.11, blue: 0.24)`; Tirekick olive-black `Color(red: 0.09,
green: 0.10, blue: 0.04)`. `Tag`, `well`, `lifted`, `HoverTilt`, `flipIn`/`flip` and `cardSwap` are unchanged.

**Type in the apps:** SF only. Stage headlines `.system(size: 28–30, weight: .semibold)` with `.tracking(-0.5)`
(Tirekick's Welcome keeps `.heavy` + `.width(.expanded)`, VERIFY on macOS 13); plate titles 22pt semibold; rows 13pt
with a 12pt secondary line; every number `.monospacedDigit()`; big metrics 26pt semibold rounded (Whydunit) or
monospaced (Tirekick); small-caps labels only on metric labels, inspector and section headers. Radii: 18 (plates),
14 (tiles), 12 (rows and inner groups), 8 (chips), capsules for buttons.

### 3.2 The controls layer: glass only here

Whydunit has no floating bar, so it adds nothing; the macOS 26 SDK draws its sidebar and toolbar glass by itself.
Tirekick's `FloatingBar` and `StepBar` call this, in `Compat.swift` (the only file allowed `#available`,
BUILD_PLAN §10):

```swift
extension View {
    /// Liquid Glass on macOS 26; a material with a hairline before. Floating bars and the StepBar only, never content.
    @ViewBuilder func barSurface() -> some View {
        if #available(macOS 26, *) {
            glassEffect(.regular, in: Capsule())                       // VERIFY: glassEffect(_:in:) signature, Xcode 26 SDK
        } else {
            background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        }
    }
}
```

Materials and glass handle Reduce Transparency themselves.

### 3.3 Performance and accessibility (both apps)

- Everything added is static: `surface`, `OnFloor`, `Horizon`, `Sky`/`Bay` draw once per size. At most 6 shadows
  per screen, no `drawingGroup()` over text. Idle CPU stays 0%; the only loops are `ScanGlyph` and Tirekick's
  checking beam, inside their scanning views.
- Decorative layers (`Horizon`, the mirror, contact shadows) are `accessibilityHidden`. Labels, traits and combined
  elements from MOTION §1.5 are unchanged; severity always carries its word.
- Increase Contrast: surfaces get a 1pt primary stroke, `Horizon` loses its pool, `Sky`/`Bay` become the plain
  window. Reduce Transparency: no mirrors, materials go solid. Reduce Motion: MOTION §1.5 exactly.

## 4. Tirekick website: Night Bay

### 4.1 Tokens (replace the two `:root` blocks in `site/static/styles.css`)

Dark on every page, in both schemes. The second block stays `prefers-contrast: more`, so `contrast()` is untouched.

```css
:root {
  color-scheme: dark;
  /* Worst of bg/bg-alt/card: text 16.1:1, text-2 5.97:1, accent 14.2:1; black on button 15.3:1, hover 12.9:1. */
  --bg: #0a0a09; --bg-alt: #11110f; --card: #181816; --well: #050504;     /* warm graphite, never #000 */
  --text: #f4f4f0; --text-2: #96968e; --accent: #cdf54a;
  --button: #c6f23c; --button-hover: #b4e02a; --on-button: #0a0a09;
  --line: #262622; --header: rgb(12 12 11 / .78); --hi: rgb(255 255 255 / .06);
  --ink: 0 0 0;
  --ok: #32d74b; --warn: #ff9f0a; --bad: #ff453a;
  /* The bay: one key light (the laser), a sodium skylight, a graphite floor. Never a box. */
  --bay-floor: #0d0d0b; --lime: #c6f23c; --lime-core: #f4ffd0;
  --spill: rgb(198 242 60 / .2); --sodium: rgb(255 240 210 / .07); --glow: rgb(198 242 60 / .14);
  --mark: rgb(198 242 60 / .38);                                          /* the highlighter behind one h1 phrase */
  --grid: rgb(255 255 255 / .045); --grid-major: rgb(255 255 255 / .08);
  /* The report card is paper in every scheme (it's the app's PNG). role="img", not measured. */
  --paper: #ffffff; --paper-ink: #0b0b0a; --paper-2: #55554e; --paper-line: #e6e6e0;
  /* Key-caps: a real side wall, never a bloom. */
  --cap-top: #262622; --cap-bot: #1b1b18; --cap-side: #050504;
  --cap: inset 0 1px 0 rgb(255 255 255 / .14), 0 0 0 1px rgb(255 255 255 / .08), 0 3px 0 var(--cap-side), 0 10px 20px -10px rgb(0 0 0 / .8);
  /* Depth: black swallows shadows, so every raised surface has a 1px light rim. */
  --z1: inset 0 1px 0 var(--hi), 0 0 0 1px rgb(255 255 255 / .07), 0 1px 2px rgb(0 0 0 / .6);
  --z2: inset 0 1px 0 rgb(255 255 255 / .07), 0 0 0 1px rgb(255 255 255 / .08), 0 14px 36px -12px rgb(0 0 0 / .8);
  --shadow: 0 0 0 1px rgb(255 255 255 / .1), 0 50px 100px -30px rgb(0 0 0 / .9), 0 24px 48px -24px rgb(0 0 0 / .7);
  --glare: rgb(255 255 255 / .08);
  --grain: /* the existing inline feTurbulence SVG, 6% */;
  --font, --font-display, --font-mono: as §2.2;  --font-num: var(--font-mono);   /* readouts like a spec sheet */
  --r-s: 6px; --r-m: 10px; --r-l: 14px; --r-xl: 20px; --r-btn: 12px;         /* machined, never pills */
  /* motion tokens unchanged (MOTION §1.2) */
}
@media (prefers-contrast: more) {
  :root {
    /* text 17.8:1, text-2 9.4:1, accent 15.1:1; on-button on button 16.2:1. */
    --text: #ffffff; --text-2: #bdbdb4; --accent: #d8fa6a; --on-button: #000000;
    --line: #4a4a44; --header: rgb(12 12 11 / .9); --grid: rgb(255 255 255 / .12); --spill: transparent; --glow: transparent;
  }
}
```

Deleted tokens: `--tread`, `--horizon` (the bloom), `--key`. `layout.html`: `color-scheme` stays `dark`, `theme-color`
stays `#0a0a09`; add the font preload (§2.2); the CSP meta and the `CSP` constant in `build_site.py` gain
`font-src 'self'` (tools owner, they must match exactly).

Why not a light override, as Afterglow proposed: the white report card is the brightest object on the page only on
a dark bay, and a second palette would move the `prefers-contrast` block off `:root` for no visual gain. Mole
proves a dark app on a light site; Recordly proves a dark site. Tirekick is the instrument, so it stays dark.

### 4.2 Home page, section by section (11 blocks, down from 12)

1. **Header pill** (§2.5, graphite glass). The lime "Download" key-cap has ink text and a hard lip; its glow is gone.
2. **Hero bay** (§4.3).
3. **Instrument strip.** The `.proof` strip in mono numerals: "0 · network connections", "0 · changes to this Mac",
   "6 · hardware tests", "≈2 min · start to report card". The first gets a 6px `--ok` dot, the one LED.
4. **"The listing says it's fine. Check anyway."** Three pairs: the seller's claim in quotes, dimmed (`opacity: .6`,
   `rotate: -2deg`, `--text-2`, strikethrough), and the Tirekick readout `.card` overlapping below it with a 3px
   status tick on each row's leading edge, a mono readout on the right ("78 %", "540 / 1000 cycles", "Assigned:
   Acme Corp") and a tag. A 1px lime line joins the two. No tilt; Tirekick is sharp.
5. **"Apple's own tools. Their exact output."** One `.card` table with hairline rows: tick · check · source (the
   command, mono, in a `--well` chip) · readout (mono, right-aligned). Header labels use `.label` small caps. The
   verdict rule as a footnote.
6. **"Then test what you'll touch."** Six `.keytile` key-caps, 3×2 (§4.4). The only skeuomorphic depth on the page,
   because it is literally the keyboard test.
7. **"A report card you can share."** The paper fan pinned (`position: sticky; top: 96px`) while three short text
   blocks scroll past: "Mask the serial", "Save a PNG", "PDF with every command's output". Static under Reduce
   Motion.
8. **Limits and privacy, merged.** A two-column `.rules` ledger, "It can tell you" / "It can't tell you", with mono
   `?` markers; under it a 4-item privacy row: offline · sends nothing · reads nothing personal · changes nothing.
   Honesty is part of the trust. No cards.
9. **Real screens.** The `.film` strip (§2.6): Checks, Tests, Report; dark captures only (the app's bay). Caption:
   "Real screens, captured by CI from the app with sample data."
10. **Guides and FAQ.** Guides as a compact linked list (title, one line, arrow; no cards). The grouped `.faq-list`.
11. **Finale bay band** and footer: the icon at 176px standing on the laser over the floor grid with its reflection,
    the h2, the lime key-cap, the mono trust line, the official-sources line; then the `--bg-alt` footer slab with a
    1px `--line` top rule, mono column titles and the version tag.

### 4.3 Hero: the inspection bay (the 3D product scene)

**Copy, left, 5 of 12 columns** (nothing here moves): eyebrow `<b>01</b> · Used-Mac inspector · macOS 13 or later`
in 12px mono, the index in `--accent`; h1 `Kick the tires <mark>before you pay.</mark>`; the lede; the lime key-cap
and the "View source" secondary; the mono trust line "Free · Runs offline · Sends nothing · Changes nothing".

```css
.hero h1 mark { color: inherit; padding: 0 .06em; background: linear-gradient(transparent 56%, var(--mark) 56% 90%, transparent 90%);
  -webkit-box-decoration-break: clone; box-decoration-break: clone; }
```

The marker is the one lime moment in the headline (the `.dim` second line is gone).

**The bay, right, 7 of 12 columns, and no box.** The `.hero` section itself is the band: full-bleed, no radius, no
border. The laptop sits back-left; the report card stands front-right; one laser lies between them on a floor grid.

```html
<section class="hero bay" aria-labelledby="hero-h">
  <div class="wide hero-grid">
    <div class="hero-copy">…</div>
    <div class="stage" data-tilt>
      <div class="scene">
        <i class="laser" aria-hidden="true"></i>                              <!-- back, Z -200 -->
        <i class="floor" aria-hidden="true"></i>                              <!-- the plane everything stands on -->
        <div class="mac" aria-hidden="true">…the existing .lid/.screen/.deck laptop, no .chips…</div>   <!-- Z -120, rotateY(14deg) -->
        <div class="card-wrap"><div class="flip" id="report-card">…the existing two .report faces…</div></div>   <!-- Z +40, rotateY(-10deg) -->
      </div>
    </div>
  </div>
  <p class="caption">Illustration with sample data. "Acme Corp" is made up.</p>
</section>
```

```css
.bay { background: radial-gradient(50% 40% at 70% 12%, var(--sodium), transparent 70%), linear-gradient(var(--bg) 55%, var(--bay-floor)); }
.stage { position: relative; min-height: 560px; perspective: var(--persp-scene); perspective-origin: 50% 30%; }
.scene { position: absolute; inset: 0; transform-style: preserve-3d; }
/* The floor: a perspective grid. The mask sits on this flat plane, never on the preserve-3d scene (MOTION §1.6). */
.floor { position: absolute; left: -40%; right: -40%; bottom: -8%; height: 70%; transform-origin: 50% 100%; transform: rotateX(80deg);
  background: repeating-linear-gradient(90deg, var(--grid-major) 0 1px, transparent 1px 112px), repeating-linear-gradient(var(--grid-major) 0 1px, transparent 1px 112px),
              repeating-linear-gradient(90deg, var(--grid) 0 1px, transparent 1px 28px), repeating-linear-gradient(var(--grid) 0 1px, transparent 1px 28px);
  -webkit-mask-image: radial-gradient(60% 80% at 50% 100%, #000 20%, transparent 70%); mask-image: radial-gradient(60% 80% at 50% 100%, #000 20%, transparent 70%); }
/* The laser: the one key light. A 1px line with a tight spill; no bloom anywhere else. */
.laser { position: absolute; left: 0; right: 0; top: 56%; height: 1px; transform: translateZ(-200px) scale(1.14);
  background: linear-gradient(90deg, transparent, var(--lime) 18% 82%, transparent); box-shadow: 0 0 10px var(--spill); }
.laser::before { content: ""; position: absolute; left: 12%; right: 12%; bottom: 0; height: 180px; background: radial-gradient(50% 100% at 50% 100%, var(--spill), transparent 70%); }
.mac { position: absolute; left: 4%; top: 12%; width: 58%; transform: translateZ(-120px) rotateY(14deg); }
.card-wrap { position: absolute; right: 2%; top: 18%; width: 46%; transform: translateZ(40px) rotateY(-10deg); }
/* Paper: white in every scheme, a lime rim on the bay, and a paper-stack edge (five sheets). */
.report { position: relative; overflow: hidden; border-radius: var(--r-l); background: var(--paper); color: var(--paper-ink);
  box-shadow: 0 1px 0 #e4e4dd, 0 2px 0 #fbfbf8, 0 3px 0 #dcdcd4, 0 4px 0 #f7f7f3, 0 5px 0 #d3d3cb, 0 0 0 1px var(--glow), var(--shadow); }
.report::after { content: ""; position: absolute; inset: 0; pointer-events: none; translate: 0 -100%; opacity: 0;   /* the scan beam */
  background: linear-gradient(transparent 88%, color-mix(in srgb, var(--lime) 35%, transparent) 97%, var(--lime)); }
.report-verdict { display: flex; gap: 12px; align-items: center; padding: 8px 0 14px; border-bottom: 1px solid var(--paper-line); background: none; }   /* ink, not a pink panel */
.report-verdict strong { font: 600 34px/1 var(--font-display); letter-spacing: -.03em; color: var(--paper-ink); }
.report-verdict svg { width: 24px; height: 24px; color: var(--bad); }
.report-rows li { display: grid; grid-template-columns: 6px 1fr auto; gap: 10px; align-items: center; padding: 6px 0; border-bottom: 1px solid var(--paper-line); }
.report-rows li i { width: 6px; height: 6px; border-radius: 50%; }                     /* the status dot; colour class per row */
.report-rows li code { font: 500 12px/1 var(--font-mono); color: var(--paper-2); }    /* the mono readout */
@media (max-width: 900px) { .mac { display: none; } .card-wrap { position: static; width: min(440px, 100%); margin: 24px auto 0; transform: none; } .stage { min-height: 0; } }
```

**The card** keeps "Walk away", as ink on paper: a 24px red ✕, the word at 34px display 600, then readout rows,
each with a mono value and a 6px status dot. The flip button and the back face are unchanged (MOTION §4.4).

**Sequence** (2.45 s, once; hard light switches on rather than fading; replaces MOTION §4.1's chips):

| t (s) | What happens | Element | Easing |
|---|---|---|---|
| 0.00–0.45 | The laser snaps on (`scale 0 1 → 1 1`, a transform) | `.laser` | `--ease-out` |
| 0.10–0.90 | The floor fades in | `.floor` | `--ease-out` |
| 0.15–1.25 | The lid opens from `rotateX(-88deg)` around its hinge; the screen powers on 0.80–1.20 | `.lid`, `.screen::after` | `--ease-out` (MOTION §4.1, kept) |
| 0.40–1.30 | The card deals in from `translate3d(120px, 0, -160px) rotateY(-30deg)` to rest | `.card-wrap` | `--ease-out` (kept, retimed) |
| 1.30–2.10 | The beam sweeps the card once, top to bottom (`translate 0 -100% → 0 0` with opacity) | `.report::after` | `--ease-in-out` |
| 2.05–2.45 | The verdict settles (`scale .94 → 1`) | `.report-verdict` | `--ease-spring` |

After 2.45 s the page is still; pointer tilt up to 5° (MOTION §1.3); the spotlight over the card stays. On phones
the laptop is hidden, the card sits flat, and the laser and floor stay. Reduce Motion, print and no-JS show the
final state.

**Delete:** `--tread`, `.stage::before` panels, the `.horizon` bloom, `.chips` and their keyframes, the blue `.beam`,
the box around the stage (radius, border, `--card` fill), the pink `.report-verdict` panel, and the lime `box-shadow`
blooms under `.button` and `.nav .button`.

### 4.4 Section recipes

- **Key-caps (`.keytile`, the tests grid):** the `--cap` recipe with a real side wall, a mono glyph well, the name
  and one line. Hover: `data-tilt` 7° with glare (MOTION §1.3) and a 5px lime LED at the top right that lights.
  Press: the key sinks 2px, the wall shrinks, the shadow swaps instantly.

```css
.keytile { position: relative; border-radius: var(--r-l); padding: 20px; background: linear-gradient(var(--cap-top), var(--cap-bot)); box-shadow: var(--cap); }
.keytile::after { content: ""; position: absolute; top: 12px; right: 12px; width: 5px; height: 5px; border-radius: 50%; background: rgb(255 255 255 / .12); }
.keytile:hover::after { background: var(--lime); box-shadow: 0 0 6px var(--spill); }
@media (prefers-reduced-motion: no-preference) { .keytile { transition: translate var(--t-fast) var(--ease-out); } }
.keytile:active { translate: 0 2px; box-shadow: inset 0 1px 0 rgb(255 255 255 / .14), 0 0 0 1px rgb(255 255 255 / .08), 0 1px 0 var(--cap-side); }
```

- **Readout rows** (listing pairs, the tools table, the app's Checks): a 3px status tick on the leading edge
  (`::before`, `var(--ok|--warn|--bad)`, 10px inset top and bottom), title 15px 600, detail `--text-2`, then the
  mono readout right-aligned, then `.tag`. Hairlines between rows, never cards.
- **Paper fan:** the three `.report` faces at `rotate: -6deg / 0 / 6deg` with `translateZ(-60px / 0 / 30px)`; the
  front card carries the stack edge (§4.3). Under Reduce Motion the fan is simply static.
- **Guides list:** `.rules` with a trailing arrow glyph instead of a code chip.
- **Finale `.reflect`:** `.finale .icon` from §2.5, standing on a `.laser` copy over a `.floor` copy inside the band.

### 4.5 Sub-pages

- **Download:** a 240px bay band with the icon standing on the laser, the h1, the lime key-cap, the requirements
  line, three key-cap steps (Open the DMG · Drag to Applications · Open the app) and the official line.
- **Changelog:** release `.card`s with a 2px lime rail on the left and the version in a mono tag.
- **Guides:** the reading layout; the meetup guide prints clean (the print rules in §2.7 strip the bay).
- **Support, privacy, terms:** the reading layout on graphite. They stay still.
- **404:** the bay with an empty paper card at a tilt and "Nothing to inspect here." (copy owner to confirm).

## 5. Tirekick app (macOS 13; macOS 14+ and 26 only in `Compat.swift`). Written, not compiled.

### 5.1 Window, chrome and the bay

- 720×560, hidden title bar, `StepBar` level with the traffic lights: unchanged.
- **StepBar.** The track becomes `barSurface()` (§3.2). Labels 12pt mono semibold. **Lime leaves the tab:** the lit
  step is a `Color.primary` capsule with inverse text (`Color(nsColor: .windowBackgroundColor)`), sliding with
  `matchedGeometryEffect` under `Motion.spring`, no animation under Reduce Motion. In the current captures the lime
  tab and the lime Continue compete; now lime is only the one prominent button, the beam, tested-key LEDs and lit keys.
- **The bay: one moving key light, a per-step shot.** `Bay(step:)` keeps its dark gradient. A 720pt warm
  `RadialGradient` (sodium white: .06 in dark, .5 in light) is placed with `.position` at a per-step point and moves
  only on step change (`.animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: step)`). Only `.position`
  animates, which is safe on macOS 13; idle stays 0%.

  | Step | Key light (x, y) | Step | Key light (x, y) |
  |---|---|---|---|
  | Start | 0.5, 0.3 | Tests | 0.5, 0.0 |
  | Checks | 0.2, 0.05 | Report | 0.5, 0.55 |

- **Light mode:** the window background plus the skylight only. The 0.97→0.91 grey ramp goes; that ramp with grey
  cards on it is why light mode reads grey-on-grey.

### 5.2 Tokens (`App/DesignSystem/Tokens.swift`, plus §3.1's `surface`, `OnFloor`, `Horizon`, `Metric`)

- `Brand.ink = Color(red: 0.09, green: 0.10, blue: 0.04)`. `Brand.hiVis` and `hiVisInk` unchanged.
- **`HiVisButtonStyle`:** drop the `.shadow(color: Brand.hiVis.opacity(0.3), radius: 10, y: 3)` glow. Keep the lit
  top edge and the machined lip; a press sinks 1pt. Hard light fits the brand.
- **`KeyCapStyle`, refined into a real key-cap** (Welcome choices, Tests tiles, the ABM Copy key):

```swift
private struct Cap: View {
    let configuration: ButtonStyleConfiguration
    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let dark = scheme == .dark, down = configuration.isPressed && !reduceMotion
        let face = dark ? [Color(red: 0.149, green: 0.149, blue: 0.133), Color(red: 0.106, green: 0.106, blue: 0.094)]   // #262622 → #1B1B18
                        : [Color.white, Color(red: 0.945, green: 0.945, blue: 0.925)]                                        // #FFFFFF → #F1F1EC
        let wall = dark ? Color(red: 0.02, green: 0.02, blue: 0.016) : Color(red: 0.788, green: 0.788, blue: 0.753)          // #050504 / #C9C9C0
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(Space.m)
            .background {
                if contrast == .increased {
                    shape.fill(.quaternary).overlay(shape.strokeBorder(Color.primary, lineWidth: 1))
                } else {
                    ZStack {
                        shape.fill(wall).offset(y: down ? 1 : 3)                                   // the side wall
                        shape.fill(LinearGradient(colors: face, startPoint: .top, endPoint: .bottom))
                            .overlay(shape.strokeBorder(Color.white.opacity(dark ? 0.14 : 0.9), lineWidth: 1).mask(LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .center)))
                            .overlay(shape.strokeBorder(hovering ? Brand.hiVis.opacity(0.6) : Color.primary.opacity(dark ? 0.08 : 0.12), lineWidth: hovering ? 1 : 0.5))
                            .shadow(color: .black.opacity(dark ? 0.5 : 0.10), radius: 8, y: 4)  // constant: never animated
                    }
                }
            }
            .contentShape(shape)
            .offset(y: down ? 2 : 0)
            .animation(Motion.pop, value: configuration.isPressed)
            .modifier(HoverTilt(max: 7))
            .onHover { hovering = $0 && !reduceMotion }
    }
}
```

- The `well` keeps its inner shadow (recessed). `Tag`, `lifted`, `terminal`, `flip`, `FlipFaces` are unchanged.
- **Field note** (the meetup tip): a hairline box (`Color.primary.opacity(0.04)`, 12pt radius) with a 2pt lime tick on
  the leading edge, a small-caps "At a meetup" label, and the unchanged body. It stays visible; a disclosure would hide
  safety advice.
- **LED bar** (speaker and microphone meters): 12 capsules, 4×10pt, that fill `Brand.hiVis` from the left; unfilled
  ones `Color.primary.opacity(0.1)`. One `accessibilityValue`.

### 5.3 Screens

**Welcome.** `OnFloor(height: 120) { LaptopView() }` (the screen shows the lime check) standing on
`Horizon(tint: Brand.hiVis, width: 440, soft: false)`, with `HoverTilt(max: 8)` on the whole `OnFloor`. The title
keeps its heavy expanded two-tone setting (VERIFY `Font.width(.expanded)` on macOS 13). The two choices are the
refined key-caps with a 44pt `well` symbol, a 15pt semibold title and one secondary line. The field note replaces
the grey slab. The mono privacy line is unchanged.

**Checks.** The verdict header sits **on the bay without a box**: `VerdictIcon` as a 60pt System Settings tile (a
white symbol on the verdict colour's gradient), the word at `.system(size: 34, weight: .bold)` with `tracking(-0.8)`,
"Checked 7 things" in mono, and a trailing `.bordered` capsule "Check Again". Below it, **one `.surface(16)`** of
readout rows separated by 0.5pt hairlines inset 40pt: a 3pt status tick on the leading edge
(`.overlay(alignment: .leading) { Capsule().fill(tint).frame(width: 3).padding(.vertical, 10) }`), the title 13pt
semibold, the detail 12pt secondary, a trailing mono readout right-aligned ("83 %", "88 / 1000 cycles", "Off"), then
the `Tag`; "Details" as a small borderless disclosure. The flip-in and the checking beam are unchanged (MOTION §5.4).
The grey verdict slab and the grey list slab are deleted.

**Tests.** A 3×2 grid of the refined key-caps (six `HoverTilt`, within the cap of 8): a 40pt `well` symbol, the name,
a `Tag` and a mono note. A tested tile lights a 5pt lime LED at its top right; lime means "tested", the verdict stays
in the `Tag`. The keyboard test draws mini key-caps whose faces turn lime with a 1pt lime rim as each key registers.
The speaker and microphone meters become the LED bar.

**Report.** `ReportCardView` stays the untouched `ImageRenderer` view; all decoration sits outside it:

```swift
ReportCardView(card: card)
    .background(alignment: .bottom) {                      // two sheets under it: thickness
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(white: 0.86)).padding(.horizontal, 10).offset(y: 6)
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color(white: 0.93)).padding(.horizontal, 5).offset(y: 3)
        }
        .accessibilityHidden(true)
    }
    .lifted()
    .modifier(HoverTilt(max: 4, glare: true))
    .background(alignment: .bottom) { Horizon(tint: Brand.hiVis, width: 520, soft: false).offset(y: 24) }
```

The bottom bar keeps Back, Mask serial, Copy, Save PDF… and the HiVis Save PNG…, on `barSurface()` (via
`floatingBar()`).

**Report card PNG (`ReportCardView`; no materials, blur or shadows inside).** Paper white at 560pt. Header: the icon
at 28pt, "Tirekick report" semibold, the model line in mono. A 2pt lime rule, the one brand mark on paper. Verdict:
the symbol at 30pt in its colour and the word at 34pt heavy expanded **in ink**, no coloured panel. The readout
table: check · mono readout on the right · `Tag`, with `#E6E6E0` hairlines. Small-caps section badges (BUILD_PLAN §8
already allows them on the card). Footer in mono secondary: date, masked serial, "Only trust a check you run yourself".

**ABM handoff.** The existing `terminal()` panel (`#050504` with a lime `$` prompt) inside a `.surface(16)` with a
Copy key-cap.

**Dark mode.** Today's bay. Surfaces are white .055 with a white .10 rim. Lime text uses `Brand.hiVisInk`, as now.
Increase Contrast gives the plain window, 1pt primary strokes, and `Horizon` without its pool.

## 6. Icon and social image (infra: `tools/make_icon.py`, `tools/make_og.py`)

- **Icon: unchanged for now.** The graphite squircle with the laptop and lime check is already the brand. Later, on a
  Mac: an Icon Composer `.icon` with three layers (graphite, laptop, lime check) and a lime rim light along the base.
- **OG image (1200×630):** the bay (floor grid, one laser), the icon at 280px standing on the laser with its
  reflection, a paper report card leaning against it, and the wordmark under it. No sentence in the image; `og:title`
  carries it.

## 7. What to delete from the current look

- The boxed stage (radius, border, `--card` fill), the `--tread` chevron wallpaper, the `.horizon` bloom, the blue
  `.beam`, the `.chips` flight, the ghost second window, the toy-scale laptop.
- The pink "Walk away" panel; every lime `box-shadow` bloom under buttons; weight 700 on headings; the `.dim` second
  h1 line (the `<mark>` replaces it); the centered section heads; the boxed proof strip; the stack of FAQ cards; the
  guide cards.
- In the app: the lime StepBar capsule, the HiVis glow, the grey verdict slab, the grey checks slab, the flat tiles
  with a dark bottom bevel, the grey meetup slab, the green verdict panel inside the PNG, the 0.97→0.91 light ramp.

## 8. Acceptance and budgets

**Looks premium (a judge checks captures at 1440 and 390px, base and `prefers-contrast: more`, against `refs/`):**

- [ ] Headlines render in Inter Display on Windows Chromium with no shift; the h1 carries one lime highlighter.
- [ ] The hero has no container edge: light comes only from the laser; a perspective floor grid reads as a floor;
      the laptop is behind, the white report card in front and the brightest object on the page; the verdict is ink
      with a red symbol, no pink panel; the card has a paper-stack edge; everything is still after 2.5 s.
- [ ] Exactly one accent is visible (lime); verdict colours appear only in dots, symbols and tag fills.
- [ ] Buttons have a lip and no bloom; the key-caps show a visible side wall and sink on press; the LED lights on hover.
- [ ] Eyebrows are mono with a lime index; readouts and table headers are mono; labels are small caps, nothing is
      ALL CAPS copy.
- [ ] Real screens appear only at ≤ 50% of their pixel width; no horizontal page scroll at 360px.
- [ ] Print (the meetup guide) is dark text on white (§2.7 fix); Reduce Motion and no-JS show the final state.
- [ ] `python tools/build_site.py --check` passes with exactly two `:root` blocks, no `style=""`, and the CSP
      including `font-src 'self'`.
- [ ] App, from CI captures: the StepBar's lit step is not lime; one lime button per screen; no grey-on-grey, no
      bevels, no glow; the verdict header sits on the bay without a box and the checks are one porcelain surface with
      status ticks and mono readouts; the laptop stands on a hard lime horizon with a reflection; the report card has
      thickness; VoiceOver labels and traits are unchanged.

**Budgets:**

| Item | Cap |
|---|---|
| `styles.css` | 40 KB (checker cap; 37.8 KB today: §7's deletions pay for the bay, the grid and the key-caps; VERIFY with `wc -c`) |
| `motion.js` | unchanged, ≤ 5 KB, byte-identical in both repos |
| Font | one woff2 ≤ 32 KB, byte-identical in both repos |
| Home HTML (built) | ≤ 36 KB |
| First load (HTML + CSS + JS + font + icon + favicon) | ≤ 150 KB |
| Lazy screenshots | ≤ 110 KB each, 3 (dark only) |
| Third-party requests, CDNs, trackers, network calls from the app | 0 |
| Hero sequence | ≤ 2.5 s, once; ≤ 5 planes |
| CLS / LCP | 0 / the h1 text |
| App CPU after entrance | 0% within 2 s; the key light moves only on a step change (0.35 s); `HoverTilt` ≤ 8; new assets or dependencies: none |

**Security.** Nothing here touches the safety rules, `Process`, the entitlements or the data flow; Tirekick still
makes no network calls. The report PNG path stays effect-free. Glass and materials are system APIs. The only CSP
change is `font-src 'self'`.

## 9. Changes for other owners, decisions for the lead, VERIFY list

**By owner (proposed, not made):**

- **Site owner (`site/**`):** §2 and §4, the font file plus `OFL.txt`, the `layout.html` preload and CSP meta, the
  §2.7 `html[lang]` fix.
- **App-views owner (`App/DesignSystem`, `App/Views`, `App/Tests`):** §3 and §5. `barSurface()` goes in
  `Compat.swift`. Nothing touches `AppModel`, the safety rules or the copy.
- **Tools owner (`tools/build_site.py`):** `font-src 'self'` in the `CSP` constant; rewrite and link-check
  `srcset="/`; add size caps to `--check` for `styles.css` (40 KB), `motion.js` (5 KB), `fonts/*.woff2` (32 KB) and
  `shots/*` (110 KB).
- **CI owner (`screens.yml`):** a `-o` no-shadow capture per screen plus `sips` conversion into `shots/`.
- **Release owner:** the OG image (§6).
- **Copy owner:** the instrument strip numbers, the listing pairs, the 404 line.
- **BUILD_PLAN §7:** amend "no custom glass, no card backgrounds on check rows" to "check rows sit in one opaque
  porcelain surface (DESIGN.md §3.1); glass only on the controls layer (`barSurface`, §3.2)". **§8:** small-caps
  *styling* on labels is allowed; it stays "no ALL CAPS copy".
- **MOTION.md:** record §2.8's table (the laser/beam sequence replaces §4.1's chips; the key light move and the
  key-cap sink are new).

**Decisions for the lead:** (1) confirm the webfont; (2) confirm real screenshots on the site; (3) confirm the
StepBar losing its lime; (4) confirm porcelain surfaces as the BUILD_PLAN §7 amendment.

**VERIFY (on a Mac or in Safari):** `glassEffect(_:in:)` on the CI Xcode; `Font.width(.expanded)` and
`.buttonBorderShape(.capsule)` on macOS 13; `Font.smallCaps()` with SF; `OnFloor`'s shadow offset and the
reflection; `HoverTilt` signs; the key-cap wall offset by eye; `-webkit-box-reflect` inside a 3D parent; the
floor's mask on a rotated plane in Safari; `sips formatOptions` syntax and WebP support on the runner;
`screencapture -o -l`; the JPEG corner radius at half scale; the Inter Display subset size; `font-display: optional`
with preload in Safari.
