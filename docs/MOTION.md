# Motion spec: Tirekick (website and app)

**Why:** the owner's requirement (2026-09-28): a modern UI with 3D animation that stays lightweight, for the website
and the app, in both EverydayOpen apps.
**Authority:** this file is authoritative for motion. BUILD_PLAN is frozen (architect), so the three §7 lines it
touches are proposed as amendments in §6. Everything else in BUILD_PLAN is unchanged: safety rules, copy, data flow,
macOS 13 APIs, system parts, no glass.
**Shared system:** §1 is identical in the Whydunit repo's `docs/MOTION.md`; change both together. This file covers
§1, §4 (website), §5 (app) and §6 (budgets and acceptance). Whydunit's copy has §2 and §3.
**Status:**
- The website code (§1.7, §4) was prototype-tested in Chromium on Windows against a copy of `site/`:
  - `build_site.py --check` found 0 errors;
  - no horizontal scroll at 360px;
  - no layout shift from the page;
  - the flip toggles `aria-pressed`;
  - LCP is the static subline.
- The website code hasn't been run in Safari or Firefox yet.
- The Swift (§1.8, §5) is written, not compiled.

## 1. The EverydayOpen motion language (shared, identical in both repos)

### 1.0 What makes 3D feel premium and still light (research, 2026-09-28)

- **Only the object moves.** Apple's product pages keep headlines, prices and buttons still. The product and the
  depth around it do the moving, and the hero plays once and then stops.
- **One camera, a few planes.** Linear and Raycast get depth from 2 to 4 flat layers at different Z, turned a few
  degrees in one perspective. They never build a full 3D model. Flat layers are cheap and keep text sharp.
- **Physical, damped, quick.** Things and Arc use short springs with a little overshoot for small objects and none
  for big surfaces. Nothing floats for more than about a second.
- **Light follows the pointer.** macOS Tahoe's Liquid Glass puts specular highlights where you move, and Reduce Motion
  turns that parallax off. Here that becomes glare under the pointer plus shadows that don't move.
- **The platform does the heavy lifting.** CSS 3D transforms and scroll-driven animations run on the compositor.
  Safari 26 shipped scroll-driven animations, and Safari 26.4 moved them to the compositor thread. Firefox stable
  still hides them behind a flag (mid-2026), so it gets a small IntersectionObserver fallback. In SwiftUI,
  `rotation3DEffect`, springs and transitions cover everything here without SceneKit or Metal.
- **Trust tools animate facts calmly.** Motion never makes a verdict look scarier or more cheerful than it is.

### 1.1 Principles (rules, not taste)

1. **Text never waits.** Hero headlines, taglines, verdicts, numbers and buttons render still, at once. Below the
   fold, a block can rise in as it enters the viewport, and it is done by the time 75% of it is visible.
2. **One hero moment per surface, then stillness.** Every sequence ends: at most 3.2 s on the web and 1 s in the
   apps. The only loops are a progress indicator that runs while real work runs (a scan, the checks).
3. **Motion never encodes severity.** A red "Walk away" arrives exactly like a green "Clean". Nothing shakes, flashes
   or pulses to alarm.
4. **Depth follows light.** A surface turns to face the pointer: the edge under the pointer recedes. The glare sits
   under the pointer. Shadows are fixed per layer and move only with their surface.
5. **Physical and quick.** Surfaces use springs with bounce ≤ 0.25. Small glyphs use ≤ 0.4. Nothing lasts longer
   than 1.1 s except the one-time hero sequence.
6. **Reduce Motion means no movement.** The end state is the same, reached by at most a 150–200 ms fade. No tilt, no
   parallax, no flip: a flip becomes a crossfade or an instant swap.
7. **Compositor only.** The web animates `transform`, `translate`, `rotate`, `scale` and `opacity`. The apps animate
   geometry effects and opacity, never frames or padding, during 3D motion.

### 1.2 Tokens

**Depth.** The web shares one real perspective per scene. SwiftUI has no shared 3D space, so each view gets its own
`perspective:` (1 is the default; lower is flatter). The table's mapping is approximate: VERIFY on a Mac and tune by
eye.

| Token | CSS | SwiftUI `perspective:` | Use |
|---|---|---|---|
| scene | `--persp-scene: 1600px` | 0.4–0.5 | hero scenes, grids, the report card, the laptop |
| card | `--persp-card: 900px` | 0.6 | cards, tiles, rows, FAQ answers |
| glyph | `perspective(400px)` inline | 1.0 (default) | icons, step numbers, keys |

| Z layer | CSS `translateZ` | SwiftUI stand-in | Shadow |
|---|---|---|---|
| back | −140 to −160px | smaller, behind in a ZStack | none |
| surface | 0 | the view itself | `--shadow` (z3) if it floats, none on a band |
| hug | +40 to +60px | offset ×1 of the tilt | `--z1`/`--z2` |
| float | +90px (max +140) | offset ×2 of the tilt | `--shadow` |

Use at most 4 layers in one scene.

**Easing and springs.**

| Token | CSS | SwiftUI (Whydunit, macOS 15) | SwiftUI (Tirekick, macOS 13) | Use |
|---|---|---|---|---|
| out | `--ease-out: cubic-bezier(.16, 1, .3, 1)` | `Motion.spring(_:)` = `.spring(duration: 0.45, bounce: 0.22)` | `.spring(response: 0.45, dampingFraction: 0.78)` | entrances, settling, tilt return, flips |
| hero | `--ease-out` over `--t-hero` | `Motion.hero` = `.spring(duration: 0.9, bounce: 0.2)` | `.spring(response: 0.9, dampingFraction: 0.8)` | one-time entrances (icon, lid) |
| spring | `--ease-spring: cubic-bezier(.34, 1.56, .64, 1)` | `Motion.pop` = `.spring(duration: 0.32, bounce: 0.38)` | `.spring(response: 0.32, dampingFraction: 0.62)` | chips, symbols, keys |
| follow | `var(--t-fast)` with `--ease-out` | `Motion.follow` = `.interactiveSpring(response: 0.25, dampingFraction: 0.86)` | same (macOS 10.15 API) | following the pointer |
| in-out | `--ease-in-out: cubic-bezier(.65, 0, .35, 1)` | `.easeInOut(duration:)` | same | beams, rising files |
| standard | none | `Motion.standard(_:)` (existing) | `Motion.standard(_:)` (existing) | plain state changes |

`.spring(duration:bounce:)` is macOS 14. With bounce ≥ 0 its damping fraction is 1 − bounce, so the Tirekick column
is the same curve.

**Durations.** `--t-fast .16s` (hover, press), `--t-base .32s` (state change, FAQ), `--t-slow .7s` (reveal, tilt
settle), `--t-hero 1.1s` (hero plane). **Stagger:** 90 ms between cards and 80 ms between report rows on the web.
In the apps, Whydunit rows use `Motion.stagger = 0.045` and Tirekick check rows keep their existing 70 ms. The
stagger index is capped (6 on the web, 8 in the apps), so a long list never trickles.

### 1.3 Hover tilt, glare and sheen

| Surface | Max tilt | Lift | Glare |
|---|---|---|---|
| Hero scene (window, laptop and card together) | 5° | none (it already floats) | only the report card |
| Cards and tiles | 7° | `scale 1.02` (web), press `0.97` | web yes, app no |
| App icon (Whydunit Welcome) | 12° | none | yes, masked to the icon |
| Laptop drawing (Tirekick Welcome) | 8° | none | no |
| Reading surface with long text (report card in the app) | 4° | none | yes |
| Tables, forms, lists, sidebars, buttons, navigation, keys | 0° | press depth only | no |

- **Direction.** `px` and `py` run from −1 to 1, measured from the center. CSS uses
  `rotateX(py × −max) rotateY(px × max)`, which was checked in Chromium: the edge under the pointer recedes. SwiftUI
  starts from the same formula; VERIFY the signs on a Mac.
- **Follow fast, settle slow.** Follow the pointer over 160 ms. Return over 700 ms (web) or with `Motion.spring`
  (app).
- **Fine pointers only.** Tilt needs `(hover: hover) and (pointer: fine)`; a Mac always qualifies. Phones get
  scroll-driven depth instead (§1.7).
- **Hit areas never move.** The web reads the pointer on the element and caches the box when the pointer enters. The
  app gets `onContinuousHover` coordinates in the untransformed layout frame.
- **Glare** is a soft radial spot under the pointer, about 60% of the surface wide, fading in over 160 ms. White
  can't shine on white, so light mode uses a faint accent spotlight (`rgb(0 102 204 / .07)`). Dark mode uses white
  at .10, and the app uses white at .28. On the web it is a 200% layer moved with `transform` and clipped by the
  card, drawn between the card's fill and its text, so it never repaints and never lowers text contrast.
- **Sheen** is a single linear highlight sweep. It is used only for the Tirekick scan beam, once.

### 1.4 Shadows that sell depth

- `--z1: 0 1px 2px rgb(0 0 0 / .06), 0 4px 12px rgb(0 0 0 / .05)`: hug layers and guide boxes.
- `--z2: 0 2px 6px rgb(0 0 0 / .06), 0 12px 32px rgb(0 0 0 / .1)`: small floating badges.
- `--shadow` (existing, z3): floating surfaces and chips.
- **Dark mode:** black backgrounds swallow shadows, so each shadow is darker and carries a 1px light rim
  (`0 0 0 1px rgb(255 255 255 / .06–.12)`) that draws the edge.
- **Never animate `box-shadow` or `filter`.** A shadow belongs to its layer. Depth changes come from moving the
  surface, and the shadow moves with it.
- **App:** use `.compositingGroup().shadow(...)` on anything that contains text, so glyphs don't get shadows of
  their own.

### 1.5 Reduce Motion

| Effect | With Reduce Motion |
|---|---|
| Hero sequence (web) | Nothing plays. The page shows the final state: lid open, files uploaded, rows filled, chips gone. |
| Pointer tilt, glare, parallax | Off (flat). |
| Scroll reveal, steps coin, phone scroll lean | Off: content is simply there. |
| FAQ unfold, button press scale | Off. `<details>` opens instantly. |
| Report card flip (web) | Instant swap by `visibility`. The button still works. |
| App entrances (icon, lid, card deal-in) | Shown at rest immediately, or a `Motion.standard(true)` fade. |
| Row flip-ins, split-flap verdict, sheet card swaps | `.opacity` transitions. |
| Scan loops (cloud glyph, laptop beam) | Not drawn. The system `ProgressView` stays. |
| Symbol effects | Removed (`.symbolEffectsRemoved(reduceMotion)` in Whydunit; Tirekick never triggers them). |

The web puts every movement inside `@media (prefers-reduced-motion: no-preference)`, so Reduce Motion needs no
override rules except the flip. The apps read `@Environment(\.accessibilityReduceMotion)` in every view that moves,
or go through `Motion.*(reduceMotion)`. VoiceOver labels, traits and element grouping never change.

### 1.6 Performance rules

**Web**

- Animate `transform`, `translate`, `rotate`, `scale` and `opacity`, plus the custom properties `--px` and `--py`
  that feed them. Never animate `box-shadow`, `filter`, `background-position`, size or position.
- **Grouping properties flatten 3D.** Never put `opacity < 1`, a non-visible `overflow`, `filter`, `clip-path`,
  `mask`, `mix-blend-mode`, `isolation` or `contain: paint` on an element that has
  `transform-style: preserve-3d`. Fade its children or its parent instead. The prototype follows this.
- No `backdrop-filter` inside a 3D scene (Safari draws it flat), and no permanent `will-change`: it wastes GPU memory
  and blurs text in Safari.
- Use `translate`/`rotate`/`scale` (the individual properties) for reveals and `transform` for tilt, so both can
  run on one card without fighting.
- At most one `requestAnimationFrame` per frame. `pointermove` listeners are passive. The box is read once per
  element entered.
- No infinite animations on the web.
- **CSS stays in `styles.css`.** `motion.js` is byte-identical in both repos (2.7 KB; hard cap 5 KB) and loads with
  `defer` from `layout.html`.
- **Two `:root` blocks only.** `tools/build_site.py` `contrast()` unpacks exactly two `:root { }` blocks, light then
  dark; a third one crashes `--check`. New tokens go into the existing two blocks. Any other override uses `html`
  or a class.
- `data-theme` and `localStorage` fail `--check`. Dark and light come from `prefers-color-scheme` only.

**Apps**

- **Zero CPU when idle.** Springs settle and stop. `repeatForever`, a `phaseAnimator` without a trigger, and
  `TimelineView` appear only inside views that exist only while work runs: Whydunit's first-scan view and Tirekick's
  "Checking this Mac…" view.
- Use only `.animation(_:value:)`, never unscoped `.animation`. Call `withAnimation` only in event handlers and
  `onAppear`.
- **3D on content only.** Never add 3D to a `Table` or `List` row container: AppKit owns the cell, its clipping and
  its selection.
- `ImageRenderer` paths get no effects inside the rendered view. Tirekick's `ReportCardView` is the PNG.
- No `drawingGroup()` over text: it rasterizes, and the text blurs at 3D angles.
- Hover state lives in the modifier (`@State`), never in `AppStore` or `AppModel`. Keep at most 8 `HoverTilt`
  views on screen at once; plain `onHover` rows are cheap and don't count.
- Written, not compiled: none of the Swift in this file has been built. Mark every API you can't confirm with
  `VERIFY`.

### 1.7 Shared web code (prototype-tested in Chromium on Windows, 2026-09-28)

**Tokens.** Append these to the **existing** light `:root` block:

```css
  /* Motion and depth (docs/MOTION.md §1). Only these two :root blocks: build_site.py contrast() reads exactly two. */
  --ease-out: cubic-bezier(.16, 1, .3, 1);
  --ease-spring: cubic-bezier(.34, 1.56, .64, 1);
  --ease-in-out: cubic-bezier(.65, 0, .35, 1);
  --t-fast: .16s;
  --t-base: .32s;
  --t-slow: .7s;
  --t-hero: 1.1s;
  --persp-scene: 1600px;
  --persp-card: 900px;
  --z1: 0 1px 2px rgb(0 0 0 / .06), 0 4px 12px rgb(0 0 0 / .05);
  --z2: 0 2px 6px rgb(0 0 0 / .06), 0 12px 32px rgb(0 0 0 / .1);
  --glare: rgb(0 102 204 / .07);   /* white can't shine on white: a faint accent spotlight instead */
```

Then append these to the existing dark `:root` block:

```css
    --z1: 0 0 0 1px rgb(255 255 255 / .06), 0 4px 12px rgb(0 0 0 / .5);
    --z2: 0 0 0 1px rgb(255 255 255 / .08), 0 12px 32px rgb(0 0 0 / .6);
    --glare: rgb(255 255 255 / .1);
```

**Shared rules.** Append these to `styles.css`, and delete the old
`@media (prefers-reduced-motion: no-preference) { .button { transition: background-color .2s; } }` line, which the
button rule below replaces. The block adds about 3 KB.

```css
/* Motion (docs/MOTION.md). Everything above is the finished, still page; movement only under no-preference.
   Animate transform, translate, rotate, scale and opacity only. Never opacity, overflow, filter or clip-path on a
   transform-style: preserve-3d element: they flatten its 3D. */
[data-tilt] { --px: 0; --py: 0; }
.stage { --tilt: 5deg; perspective: var(--persp-scene); }
.scene { position: relative; transform-style: preserve-3d; }
.grid { perspective: var(--persp-scene); }
.card[data-tilt] { --tilt: 7deg; position: relative; isolation: isolate; overflow: hidden; }
/* Glare: a 200% spotlight moved by transform (no repaint), between the card's fill and its text. */
.card[data-tilt]::after {
  content: ""; position: absolute; z-index: -1; inset: -50%; pointer-events: none; opacity: 0;
  background: radial-gradient(circle, var(--glare), transparent 30%);
  transform: translate(calc(var(--px) * 25%), calc(var(--py) * 25%));
}
@media (prefers-reduced-motion: no-preference) and (hover: hover) and (pointer: fine) {
  .scene, .card[data-tilt] {
    transform: rotateX(calc(var(--py) * var(--tilt) * -1)) rotateY(calc(var(--px) * var(--tilt)));
    transition: transform var(--t-slow) var(--ease-out), scale var(--t-base) var(--ease-out);
  }
  .tilting .scene, .card.tilting { transition-duration: var(--t-fast), var(--t-base); }   /* follow fast, settle slow */
  .card.tilting { scale: 1.02; }
  .card[data-tilt]::after { transition: opacity var(--t-base), transform var(--t-fast) linear; }
  .card.tilting::after { opacity: 1; }
}
/* Phones: no pointer, so the hero leans back and straightens as it scrolls into place. */
@media (prefers-reduced-motion: no-preference) and (hover: none) {
  @supports (animation-timeline: view()) {
    .scene { animation: settle linear both; animation-timeline: view(); animation-range: cover 0% cover 45%; }
  }
}
/* Reveal: scroll-driven where supported; motion.js adds .reveal-io and .in elsewhere. */
@media (prefers-reduced-motion: no-preference) {
  @supports (animation-timeline: view()) {
    .reveal { animation: rise linear both; animation-timeline: view(); animation-range: entry 0% entry 75%; }
  }
  .reveal-io .reveal:not(.in) { opacity: 0; }
  .reveal-io .reveal.in { animation: rise var(--t-slow) var(--ease-out) calc(var(--i, 0) * 90ms) backwards; }
  details[open] > p { animation: unfold var(--t-base) var(--ease-out); }
  summary::after { transition: rotate var(--t-base) var(--ease-out); }
  details[open] summary::after { rotate: 180deg; }
  .button { transition: background-color .2s, scale var(--t-fast) var(--ease-out); }
  .button:active { scale: .97; }
}
details { perspective: var(--persp-card); }
@keyframes settle { from { transform: rotateX(12deg) scale(.96); } }
@keyframes rise { from { opacity: 0; translate: 0 32px; rotate: x 10deg; } }
@keyframes unfold { from { opacity: 0; translate: 0 -6px; rotate: x -12deg; } }
@keyframes fade { from { opacity: 0; } }
@keyframes pop { from { opacity: 0; transform: translateZ(0) scale(.8); } }
```

**`site/static/motion.js`** is byte-identical in both repos and loads from `layout.html` right after the stylesheet
link: `<script src="/motion.js" defer></script>`. The build prefixes `src="/`, and `--check` confirms the file
exists. It has three jobs:

1. **Tilt.** Write `--px`/`--py` on the hovered `[data-tilt]` element and toggle `.tilting`. This happens only for
   a mouse, without Reduce Motion, throttled to one rAF per frame. It resets on scroll and when the pointer leaves
   the window.
2. **Reveal fallback.** Where `animation-timeline: view()` is unsupported (Firefox stable), add `.reveal-io` to
   `<html>` and give `.in` to each `.reveal` as it enters, staggered within each batch. Anything already on screen at
   load gets `.in` before the class goes on, so it never flashes.
3. **Flip.** Unhide each `[data-flip]` button and make it toggle `.flipped` on its `aria-controls` target, keeping
   `aria-pressed` in sync.

With no JS, the pages are complete and still. Hero sequences are pure CSS and need no JS.

```js
// Motion for the EverydayOpen sites (docs/MOTION.md). Every page is complete and static without it.
(() => {
  const root = document.documentElement;
  const calm = matchMedia('(prefers-reduced-motion: reduce)');
  const fine = matchMedia('(hover: hover) and (pointer: fine)');

  // Tilt: --px/--py (-1..1 from the center) on the hovered [data-tilt]; CSS turns them into rotation and glare.
  // The box is read once per element entered, so the tilt never feeds back into it.
  let el = null, box, x = 0, y = 0, frame = 0;
  const enter = (t) => {
    if (el) {
      el.classList.remove('tilting');
      el.style.removeProperty('--px');
      el.style.removeProperty('--py');
    }
    el = t;
    if (el) {
      el.classList.add('tilting');
      box = el.getBoundingClientRect();
    }
  };
  const unit = (v, start, size) => Math.max(-1, Math.min(1, (v - start) / size * 2 - 1)).toFixed(3);
  const draw = () => {
    frame = 0;
    if (!el) return;
    el.style.setProperty('--px', unit(x, box.left, box.width));
    el.style.setProperty('--py', unit(y, box.top, box.height));
  };
  addEventListener('pointermove', (e) => {
    if (e.pointerType !== 'mouse' || calm.matches || !fine.matches) return;
    const t = e.target.closest ? e.target.closest('[data-tilt]') : null;
    if (t !== el) enter(t);
    x = e.clientX;
    y = e.clientY;
    if (el && !frame) frame = requestAnimationFrame(draw);
  }, { passive: true });
  addEventListener('scroll', () => el && enter(null), { passive: true });
  root.addEventListener('pointerleave', () => enter(null));

  // Reveal, where CSS scroll-driven animations don't exist yet (Firefox): .in when it enters, staggered per batch.
  const items = document.querySelectorAll('.reveal');
  if (items.length && !calm.matches && !CSS.supports('animation-timeline: view()') && 'IntersectionObserver' in window) {
    const io = new IntersectionObserver((entries) => {
      entries.filter((e) => e.isIntersecting).forEach((e, n) => {
        e.target.style.setProperty('--i', Math.min(n, 6));
        e.target.classList.add('in');
        io.unobserve(e.target);
      });
    }, { rootMargin: '0px 0px -8% 0px' });
    items.forEach((e) => (e.getBoundingClientRect().top < innerHeight ? e.classList.add('in') : io.observe(e)));
    root.classList.add('reveal-io');
  }

  // Flip: a [data-flip] button turns the card named by aria-controls over and back.
  document.querySelectorAll('[data-flip]').forEach((b) => {
    const card = document.getElementById(b.getAttribute('aria-controls'));
    if (!card) return;
    b.hidden = false;
    b.addEventListener('click', () => b.setAttribute('aria-pressed', card.classList.toggle('flipped')));
  });
})();
```

### 1.8 Shared SwiftUI code (PROPOSAL, written, not compiled)

Both apps get the same pointer tilt, in `App/DesignSystem/Tokens.swift`. It uses only macOS 13 APIs:
`onContinuousHover` is macOS 13, and `rotation3DEffect`, `RadialGradient` and `mask` are older. **Whydunit** (macOS
15) replaces the `.background(GeometryReader …)` line with
`.onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }`, which avoids the one-argument `onChange`
that is deprecated from macOS 14.

```swift
/// Turns a surface to face the pointer (the edge under it recedes), at most `max` degrees, with an optional glare
/// masked to the content's own shape. Flat under Reduce Motion. The pointer is read in the layout frame, so the
/// tilt never moves hit areas.
struct HoverTilt: ViewModifier {
    var max = 7.0
    var glare = false
    @State private var size = CGSize.zero
    @State private var p = CGPoint.zero          // -1...1 from the center
    @State private var hovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay {
                if glare && hovering {
                    RadialGradient(colors: [.white.opacity(0.28), .clear], center: .center,
                                   startRadius: 0, endRadius: size.width * 0.6)
                        .offset(x: p.x * size.width / 2, y: p.y * size.height / 2)
                        .mask { content }            // VERIFY: content drawn twice; fine for an icon and one card
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            // VERIFY on a Mac: the edge under the pointer should recede; negate both angles if it rises instead.
            .rotation3DEffect(.degrees(-p.y * max), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(p.x * max), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .background(GeometryReader { g in
                Color.clear.onAppear { size = g.size }.onChange(of: g.size) { size = $0 }
            })
            .onContinuousHover { phase in
                guard !reduceMotion, size.width > 0, size.height > 0 else { return }
                switch phase {
                case .active(let at):
                    withAnimation(Motion.follow) {
                        hovering = true
                        p = CGPoint(x: at.x / size.width * 2 - 1, y: at.y / size.height * 2 - 1)
                    }
                case .ended:
                    withAnimation(Motion.spring(false)) {
                        hovering = false
                        p = .zero
                    }
                }
            }
    }
}
```

The `Motion` additions (`spring`, `hero`, `pop`, `follow`) are in each app's section, spelled for its deployment
target.

**Sources:** WebKit, "WebKit Features in Safari 26.0" (webkit.org/blog/17333) and "WebKit Features for Safari
26.4" (webkit.org/blog/17862); Firefox's `layout.css.scroll-driven-animations.enabled` flag status (mid-2026
developer guides); Apple docs for `onContinuousHover(coordinateSpace:perform:)` (macOS 13) and
`rotation3DEffect(_:axis:anchor:anchorZ:perspective:)`; SF Symbols 6 effects `wiggle`, `breathe` and `rotate`
(macOS 15; WWDC24 "What's new in SwiftUI"). `keyframeAnimator` is deliberately unused. Nobody has checked whether a
one-shot run rests on the last keyframe or on `initialValue`, and plain `@State` plus a spring does the same job on
every macOS version without that question.

## 4. Tirekick website

### 4.1 The story in 3 seconds

A MacBook drawn in CSS opens its lid and its screen lights up with the app icon. A blue beam sweeps the screen once.
Four check chips pop out of the screen toward you, then fly across to the report card. As they land, the card's rows
fill in one by one. After that the page is still: the pointer tilts the scene up to 5°, a spotlight glides over the
card, and a round button in the card's corner turns it over to show where each line comes from. The headline, subline
and both buttons never move.

| t (s) | What happens | Element | Easing |
|---|---|---|---|
| 0.15–1.25 | Lid opens from `rotateX(-88deg)` around its hinge | `.lid` | `--ease-out` |
| 0.30–1.20 | Card deals in from `translate3d(0, 40px, -140px) rotateY(-24deg)`; its front fades in | `.card-wrap`, first `.face` | `--ease-out` |
| 0.80–1.20 | Screen powers on (black overlay fades) | `.screen::after` | ease-out |
| 1.05–2.05 | Beam sweeps top to bottom, once | `.beam` | `--ease-in-out` |
| 1.50–3.16 | Chips pop to Z +90, hold, then fly to the card and fade (0.12 s apart) | `.chips li` | `--ease-out` |
| 2.10–3.11 | Card rows fade in, 80 ms apart | `.report-rows li` | `--ease-out` |

### 4.2 DOM (replaces the hero's second `.wrap`; the report `<figure>` keeps its content)

Add one symbol to the page's sprite:

```html
<symbol id="i-turn" viewBox="0 0 24 24"><path fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" d="M4.5 10a8 8 0 0 1 14.2-3.2M19.5 14a8 8 0 0 1-14.2 3.2M19 3v4h-4M5 21v-4h4"/></symbol>
```

```html
<div class="wrap">
  <!-- Hero scene (MOTION.md §4). The report card is the app ReportCardView as HTML; replace with a real screenshot once the app runs on a Mac. -->
  <div class="stage" data-tilt>
    <div class="scene">
      <div class="mac" aria-hidden="true">
        <div class="lid"><div class="screen"><img src="/icon.png" width="64" height="64" alt=""><i class="beam"></i></div></div>
        <div class="deck"></div>
        <ul class="chips">
          <li style="--i:0"><svg><use href="#i-ok"/></svg>Activation Lock is off</li>
          <li style="--i:1"><svg><use href="#i-ok"/></svg>Not managed by any organization</li>
          <li style="--i:2"><svg><use href="#i-stop"/></svg>Assigned to “Acme Corp”</li>
          <li style="--i:3"><svg><use href="#i-warn"/></svg>Battery at 78%</li>
        </ul>
      </div>
      <div class="card-wrap">
        <div class="flip" id="report-card">
          <figure class="report face" aria-label="Illustration with sample data: a Tirekick report card that says Walk away.">
            …unchanged head, verdict, summary…
            <ul class="report-rows" role="list">
              <li style="--i:0">…</li> … <li style="--i:7">…</li>   <!-- only --i added -->
            </ul>
            …unchanged foot…
          </figure>
          <div class="report face back">
            <p class="report-head"><img src="/favicon.png" width="22" height="22" alt=""><span><b>Where each line comes from</b></span></p>
            <ul class="report-rows" role="list">
              <li><span><code>system_profiler SPHardwareDataType</code>: Activation Lock, model and serial</span></li>
              <li><span><code>profiles status -type enrollment</code>: MDM</span></li>
              <li><span><code>profiles show -type enrollment</code>, run by you in Terminal: company</span></li>
              <li><span><code>system_profiler SPPowerDataType</code> and <code>ioreg</code>: battery</span></li>
              <li><span><code>system_profiler SPStorageDataType</code>: SSD</span></li>
              <li><span>A model list built into the app: macOS updates</span></li>
            </ul>
            <p class="report-foot">The PDF includes every command and its raw output.</p>
          </div>
        </div>
        <button class="flip-btn" type="button" data-flip aria-controls="report-card" aria-pressed="false" aria-label="Show where each line comes from" title="Show where each line comes from" hidden><svg aria-hidden="true"><use href="#i-turn"/></svg></button>
      </div>
    </div>
  </div>
  <p class="small muted center">Illustration with sample data. “Acme Corp” is made up.</p>
</div>
```

- **The chip copy is the card's own rows, shortened.** The back's copy comes from the "What it checks" table and the
  "A report card you can share" list. The owner (infra, `site/**`) should confirm it against BUILD_PLAN §8 tone before
  shipping.
- **Both faces are in the DOM,** so VoiceOver reads the front, then the back, whatever the flip state. The button is
  a real `<button>` with `aria-pressed`, and it stays `hidden` until `motion.js` runs. It is absolutely positioned, so
  showing it moves nothing.
- **Other page edits:**
  - Every `.card` in the problem, tests and privacy grids and each Guides `a.card`: `class="card reveal" data-tilt`.
  - The table, the "A report card you can share" card, the limits and never sections and the FAQ: no markup changes.
- `layout.html`: add `<script src="/motion.js" defer></script>` after the stylesheet link.

### 4.3 CSS (append after the shared block in §1.7; about 5.2 KB)

```css
/* Hero scene (MOTION.md §4): the lid opens, a beam sweeps the screen, checks pop out and land on the report card. */
.scene { display: grid; gap: clamp(28px, 5vw, 56px); align-items: center; padding-top: 48px; }
@media (min-width: 900px) { .scene { grid-template-columns: 5fr 6fr; } }
.mac { position: relative; width: min(100%, 440px); margin-inline: auto; transform: rotateX(8deg); transform-style: preserve-3d; }
.lid { aspect-ratio: 16 / 10.5; padding: 3.5%; border-radius: 16px 16px 4px 4px; background: #1d1d1f; box-shadow: inset 0 0 0 1px rgb(255 255 255 / .1); transform-origin: 50% 100%; }
.screen { position: relative; display: grid; place-items: center; height: 100%; border-radius: 6px; background: #0b0b0d; overflow: hidden; }
.screen img { width: 22%; }
.screen::after { content: ""; position: absolute; inset: 0; background: #000; opacity: 0; }
.beam { position: absolute; inset: 0; background: linear-gradient(transparent 42%, rgb(41 151 255 / .5) 50%, transparent 58%); opacity: 0; }
.deck { position: relative; height: 12px; margin-inline: -7%; border-radius: 0 0 16px 16px / 0 0 10px 10px; background: linear-gradient(#e3e4e6, #a9abb0); }
.deck::before { content: ""; position: absolute; left: 42%; right: 42%; top: 0; height: 4px; border-radius: 0 0 6px 6px; background: rgb(0 0 0 / .18); }
.chips { position: absolute; inset: 10% 10% auto; display: grid; justify-items: start; gap: 8px; margin: 0; padding: 0; list-style: none; transform-style: preserve-3d; pointer-events: none; }
.chips li { display: flex; gap: 8px; align-items: center; padding: 8px 12px; border-radius: 10px; background: #fff; color: #1d1d1f; font-size: 13px; font-weight: 600; letter-spacing: 0; box-shadow: var(--shadow); opacity: 0; }
.chips svg { flex: none; width: 16px; height: 16px; }
.chips { --fly: translate3d(0, 320px, 40px); }
@media (min-width: 900px) { .chips { --fly: translate3d(420px, 40px, 40px); } }
/* The card turns over to "where each line comes from". Both faces share one grid cell, so flipping never moves
   anything; the back is shorter than the front. */
.card-wrap { position: relative; transform-style: preserve-3d; }
.flip { display: grid; transform-style: preserve-3d; transition: transform .8s var(--ease-out); }
.flip.flipped { transform: rotateY(180deg); }
.face { grid-area: 1 / 1; margin: 0; max-width: none; -webkit-backface-visibility: hidden; backface-visibility: hidden; }
.face.back { transform: rotateY(180deg); }
.face.back code { background: #f5f5f7; }
.flip-btn { position: absolute; top: 14px; right: 14px; display: grid; place-items: center; width: 36px; height: 36px; padding: 0; border: 0; border-radius: 50%; background: #f5f5f7; color: #1d1d1f; cursor: pointer; transform: translateZ(2px); }
.flip-btn[hidden] { display: none; }   /* display: grid would beat the hidden attribute */
.flip-btn svg { width: 18px; height: 18px; }
.flip-btn::before { content: ""; position: absolute; inset: -4px; }   /* 44 pt target */
.flip .report { position: relative; isolation: isolate; overflow: hidden; }
.flip .report-head { padding-right: 40px; }   /* room for the flip button */
.flip .report::after {
  content: ""; position: absolute; z-index: -1; inset: -50%; pointer-events: none; opacity: 0;
  background: radial-gradient(circle, rgb(0 102 204 / .07), transparent 30%);   /* the card is always light */
  transform: translate(calc(var(--px) * 25%), calc(var(--py) * 25%));
}
.summary, .prose pre { box-shadow: var(--z1); }
@media (prefers-reduced-motion: no-preference) and (hover: hover) and (pointer: fine) {
  .flip .report::after { transition: opacity var(--t-base), transform var(--t-fast) linear; }
  .tilting .report::after { opacity: 1; }
}
@media (prefers-reduced-motion: no-preference) {
  .lid { animation: lid 1.1s var(--ease-out) .15s backwards; }
  .screen::after { animation: off .4s ease-out .8s backwards; }
  .beam { animation: beam 1s var(--ease-in-out) 1.05s; }
  .chips li { animation: chip 1.3s var(--ease-out) calc(1.5s + var(--i) * .12s) both; }
  .card-wrap { animation: deal .9s var(--ease-out) .3s backwards; }
  .flip > .face:first-child { animation: fade .6s ease-out .3s backwards; }
  .flip > .face:first-child .report-rows li { animation: fade .45s var(--ease-out) calc(2.1s + var(--i) * 80ms) backwards; }
  .checklist input:checked { animation: tick var(--t-base) var(--ease-spring); }
}
@media (prefers-reduced-motion: reduce) {
  .flip { transition: none; }
  .flip.flipped { transform: none; }
  .face.back { transform: none; visibility: hidden; }
  .flipped .face.back { visibility: visible; }
  .flipped .face:first-child { visibility: hidden; }
}
@keyframes lid { from { transform: rotateX(-88deg); } }
@keyframes beam { from { opacity: 1; transform: translateY(-100%); } to { opacity: 1; transform: translateY(100%); } }
@keyframes chip {
  0% { opacity: 0; transform: translate3d(0, 12px, 0) scale(.8); }
  30%, 60% { opacity: 1; transform: translate3d(0, 0, 90px); }
  100% { opacity: 0; transform: var(--fly) scale(.7); }
}
@keyframes deal { from { transform: translate3d(0, 40px, -140px) rotateY(-24deg); } }
@keyframes tick { from { scale: .6; } }
@keyframes off { from { opacity: 1; } }
```

Notes from the prototype:

- **Keep the button hidden without JS.** `.flip-btn { display: grid }` beats the UA's `[hidden] { display: none }`, so
  the explicit `[hidden]` rule is required.
- **Fade the faces, not the containers.** The deal animates only `transform` on `.card-wrap`, and the fade sits on the
  front face. Opacity on `.card-wrap` or `.flip` (both preserve-3d) would flatten the flip.
- **The chips fly to rough coordinates.** `--fly` is set per breakpoint: to the right on desktop, down on phones.
  Chip and row share icon and wording and cross-fade at the same moment, so the eye reads it as landing. No JS
  measures positions.
- **The card stays light.** The report card is always light (like the app's PNG), so its glare uses the light-mode
  spotlight in both schemes. The laptop is an object, so it keeps fixed colors in both schemes.
- **At 360px:** the laptop is 320px wide, the card sits below it and the chips fly down. There is no horizontal
  scroll.

### 4.4 Why the flip is a button, not hover

People move the mouse over the card to read it. If hover turned it over, the thing they're reading would leave.
So hover does what hover should (tilt and spotlight), and the corner button turns the card, like the ⓘ on an Apple
Wallet pass. It works the same by click, tap and keyboard, and it's announced as a toggle.

### 4.5 Sections and guides

| Section | Motion |
|---|---|
| Hero text, subline, both buttons | none (LCP: the subline, about 0.45 s locally) |
| Hero scene | §4.1 once, then tilt (fine pointers) or scroll lean (phones) |
| What goes wrong (3), Then test (6), privacy (4) cards | reveal plus 7° tilt, glare and scale 1.02 |
| What it checks (table) | none: data stays still |
| A report card you can share, What it can't tell you, It will never… | none (text) |
| Guides (4 link cards) | reveal plus tilt; the hover underline stays |
| Questions | answer unfolds; "+" turns into "−" |
| Buttons | press `scale .97` |
| Guide pages | subtle depth: `.summary` boxes and `pre` blocks get a static `--z1` shadow, and meetup checklist boxes pop when ticked. Nothing else moves (the pages are also printed). |

## 5. Tirekick app (macOS 13 deployment, SwiftUI)

This is PROPOSAL code: written, not compiled. The owner is app (`App/**/*.swift`). Every API is macOS 13 unless it
sits in `App/DesignSystem/Compat.swift` behind `if #available`. It doesn't touch `AppModel`, `Collector`, copy, safety
rules or the PNG. BUILD_PLAN §7 (frozen) says Welcome shows the 96 pt icon, Checks shows a centered `ProgressView`,
and rows use `.move(edge: .top)`. The amendments this needs are listed in §6.

### 5.1 Tokens (`App/DesignSystem/Tokens.swift`)

```swift
enum Motion {
    /// `.smooth` is macOS 14. Under Reduce Motion callers also drop movement and keep only the fade.
    static func standard(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.15) : .easeInOut(duration: 0.28)
    }
    /// Surfaces: flips, deal-ins, a tilt settling back. Same curve as `.spring(duration: 0.45, bounce: 0.22)`.
    static func spring(_ reduceMotion: Bool) -> Animation {
        reduceMotion ? .linear(duration: 0.15) : .spring(response: 0.45, dampingFraction: 0.78)
    }
    static let hero = Animation.spring(response: 0.9, dampingFraction: 0.8)
    static let pop = Animation.spring(response: 0.32, dampingFraction: 0.62)
    static let follow = Animation.interactiveSpring(response: 0.25, dampingFraction: 0.86)
}

extension AnyTransition {
    /// Check rows and the verdict: turns down into place from the top edge like a split-flap card, and leaves by
    /// fading, so old and new never overlap mid-turn. Opacity only under Reduce Motion.
    static func flip(_ reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? .opacity : .asymmetric(
            insertion: .modifier(active: FlipDown(angle: 70, opacity: 0), identity: FlipDown(angle: 0, opacity: 1)),
            removal: .opacity)
    }
}

private struct FlipDown: ViewModifier {
    let angle: Double
    let opacity: Double

    func body(content: Content) -> some View {
        content   // VERIFY sign on a Mac: the bottom edge should start toward the viewer
            .rotation3DEffect(.degrees(angle), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
            .opacity(opacity)
    }
}

/// Shows the content until the turn passes 90°, then `back`: a card turning over. `angle` animates.
struct FlipFaces<Back: View>: ViewModifier, Animatable {
    var angle: Double
    let back: Back
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity(angle < 90 ? 1 : 0)
            .overlay {
                back.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(angle < 90 ? 0 : 1)
                    .accessibilityHidden(true)
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

/// The Welcome choices and the Tests tiles: a plain rounded fill that darkens and sinks while pressed, and turns
/// toward the pointer.
struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View { Tile(configuration: configuration) }

    private struct Tile: View {
        let configuration: ButtonStyleConfiguration
        @State private var hovers = 0
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(Space.m)
                .background(shape.fill(configuration.isPressed ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.quaternary)))
                .contentShape(shape)
                .bounce(on: hovers)                                   // Compat: symbol bounce on macOS 14+
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
                .animation(Motion.pop, value: configuration.isPressed)
                .modifier(HoverTilt(max: 7))
                .onHover { if $0 && !reduceMotion { hovers += 1 } }
        }
    }
}
```

`HoverTilt` (§1.8) goes in this file unchanged. It uses the `GeometryReader` background, because one-argument
`onChange` is fine on macOS 13.

### 5.2 `App/DesignSystem/Compat.swift` (new; the only file with `#available`)

```swift
import SwiftUI

// The only file with `if #available` (BUILD_PLAN §10). Each helper does nothing on macOS 13.
extension View {
    /// Bounces the SF Symbols inside once each time `value` changes (macOS 14 symbol effects).
    @ViewBuilder func bounce(on value: some Equatable) -> some View {
        if #available(macOS 14, *) {
            symbolEffect(.bounce, value: value)
        } else {
            self
        }
    }

    /// Leans a surface back, at most 8°, as it scrolls up and away (macOS 14 `visualEffect`).
    @ViewBuilder func scrollLean(_ reduceMotion: Bool) -> some View {
        if #available(macOS 14, *) {
            visualEffect { content, proxy in
                // VERIFY: the .scrollView coordinate space and rotation3DEffect on VisualEffect, macOS 14.
                let past = reduceMotion ? 0 : min(max(-proxy.frame(in: .scrollView).minY / 40, 0), 8)
                return content.rotation3DEffect(.degrees(past), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.4)
            }
        } else {
            self
        }
    }
}
```

The macOS 13 path is the full design: tilt, flips, lid, beam, deal-in and key depth all use macOS 13 APIs. macOS 14
adds only these two touches.

### 5.3 Welcome: the laptop opens, the choices tilt

`App/Views/LaptopView.swift` is new. It is drawn with shapes and no assets:

```swift
import AppKit
import SwiftUI

/// Welcome's laptop: the lid opens once when it appears. With `scanning` the lid starts open and a beam sweeps the
/// screen for as long as the view exists (only while checks run). Still, and open, under Reduce Motion.
struct LaptopView: View {
    var scanning = false
    @State private var open: Bool
    @State private var sweep = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(scanning: Bool = false) {
        self.scanning = scanning
        _open = State(initialValue: scanning)
    }

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(white: 0.12))
                .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).strokeBorder(.quaternary))
                .overlay(screen.padding(6))
                .frame(width: 150, height: 98)
                // VERIFY sign on a Mac: closed means the lid lies toward the viewer, edge-on.
                .rotation3DEffect(.degrees(open || reduceMotion ? 0 : -86), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.45)
            // The deck seen from the front: a slab a little wider than the lid, with the thumb notch.
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.gray.gradient)
                .overlay(alignment: .top) { Capsule().fill(.black.opacity(0.2)).frame(width: 26, height: 2.5) }
                .frame(width: 178, height: 8)
        }
        .accessibilityHidden(true)
        .onAppear {
            if !open { withAnimation(reduceMotion ? nil : Motion.hero.delay(0.1)) { open = true } }
            sweep = scanning   // false → true after the first frame, so the scoped repeatForever below starts
        }
    }

    private var screen: some View {
        ZStack {
            Color.black
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 46, height: 46)
                .opacity(open || reduceMotion ? 1 : 0)
                .animation(Motion.standard(reduceMotion).delay(0.45), value: open)
            if scanning && !reduceMotion {
                LinearGradient(colors: [.clear, .accentColor.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 22)
                    .offset(y: sweep ? 50 : -50)
                    .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: sweep)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}
```

The beam's loop is scoped to `sweep` with `.animation(_:value:)`, not `withAnimation`. A `repeatForever` started
inside a view that is itself transitioning in can otherwise pick up the parent's movement. VERIFY on a Mac.

In `WelcomeView`, replace the 96 pt `Image(nsImage:)` with `LaptopView().modifier(HoverTilt(max: 8))`. It's about the
same height, 106 pt, so the fixed 720×560 window still fits, and the icon lives on its screen. The title, text, tip
and privacy line don't move. The **I'm Buying** and **I'm Selling** tiles get tilt, press depth and (on macOS 14+) a
symbol bounce from `TileButtonStyle`, with no change in `WelcomeView`.

### 5.4 Checks: the beam while it checks, rows flip in, the verdict flips like a split-flap

The loading state (`model.facts == nil`) becomes:

```swift
VStack(spacing: Space.m) {
    LaptopView(scanning: true)
    HStack(spacing: Space.xs) {
        ProgressView().controlSize(.small)
        Text("Checking this Mac…").foregroundStyle(.secondary)
    }
}
```

Rows: change the row transition to `.transition(.flip(reduceMotion))` and keep the existing `revealed` stagger (70 ms).
**Be honest about timing:** `Collector.collectAll()` returns every check at once, so the rows flip in on a reveal
stagger, not as each check finishes. Faking per-check timing would misstate what the app did.

Verdict banner: wrap the icon and title group so a new verdict turns down over the old one:

```swift
ZStack(alignment: .leading) {
    HStack(spacing: Space.s) { …existing VerdictIcon + title + summary line… }
        .accessibilityElement(children: .combine)
        .id(verdict)
        .transition(.flip(reduceMotion))
}
.animation(Motion.spring(reduceMotion), value: verdict)
```

`Verdict` is an `Int` enum, so it's Hashable. The flip plays when the verdict really changes: after Check Again, the
Terminal paste, or "Matches the listing?". VoiceOver still gets `model.announce(...)`, which is unchanged.

### 5.5 Tests: tiles tilt, keys sink

- **Tiles:** handled by `TileButtonStyle` (§5.1). A tile's result icon doesn't bounce when a test ends. `TestsView`
  is rebuilt when the test closes, so no value "changes" to trigger it.
- **Keyboard test key depth.** In `keyView`, with `@Environment(\.accessibilityReduceMotion)` added to the view:

```swift
let isDown = down.contains(key.code) && !reduceMotion
…
.background(shape.fill(…existing fill…)
    .shadow(color: .black.opacity(isDown ? 0 : 0.18), radius: 0, y: isDown ? 0 : 1.5))   // the key's side
…
.contentShape(shape)
.scaleEffect(isDown ? 0.92 : 1)
.offset(y: isDown ? 1 : 0)
.animation(Motion.pop, value: isDown)
```

- The existing 0.7-opacity "held" fill stays, and it is the Reduce Motion cue. Modifiers set only `pressed`, so they
  light without sinking, as they do now.
- The keyboard gets **no** static 3D lean. Whether SwiftUI hit-testing follows `rotation3DEffect` isn't verified, and
  tick-by-hand clicks must land.

### 5.6 Report: the card is dealt face down, turns over, then follows the pointer

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@State private var dealt = false
…
if let card = model.card {
    let shape = RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
    ReportCardView(card: card)          // the PNG's view: never add effects inside it (Export renders it for Save PNG)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color(nsColor: .separatorColor)))
        .modifier(HoverTilt(max: 4, glare: true))
        .modifier(FlipFaces(angle: dealt || reduceMotion ? 0 : 180, back: CardBack().clipShape(shape)))
        .scrollLean(reduceMotion)       // Compat: macOS 14+
        .compositingGroup()
        .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
        .frame(maxWidth: .infinity)
        .onAppear { withAnimation(Motion.spring(reduceMotion).delay(0.1)) { dealt = true } }
}

/// The card's back, seen only while it turns over: white, with the app icon. No text, so nothing to read or miss.
private struct CardBack: View {
    var body: some View {
        Color.white.overlay { Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 72, height: 72) }
    }
}
```

- The deal happens once per visit to the Report screen, in about 0.5 s. Toggling **Mask serial** only changes the
  card's text, with no flip.
- **Interactive flip to a details back: not in v1, owner's call.** It would need a second button on a screen allowed
  one prominent button, and new copy for a back that repeats what Checks › Details already shows. If wanted: a
  `.bordered` "Flip Card" toggles `@State showBack`, and `FlipFaces(angle: showBack ? 180 : 0, back:
  ReportText.cantTell list)`, with the front marked `.accessibilityHidden(showBack)`.

### 5.7 What doesn't move

- The Checks "What you're buying" rows, the Evidence output boxes and the bottom bar's Back and Continue stay still.
- The full-window test scaffolds keep their system motion (RootView's existing crossfade).
- The display test's color screens stay still, because motion there would hide dead pixels.
- The camera, microphone, speakers and trackpad tests stay still, since their feedback is the hardware itself.
- **Not doing:**
  - a `matchedGeometryEffect` from the Welcome laptop to the Checks laptop (two separate instances are simpler);
  - keyframe lid wobble;
  - glass.

## 6. Budgets and acceptance (Tirekick)

### 6.1 Budgets

| Website item | Hard cap | Before | Prototype | Measure |
|---|---|---|---|---|
| `site/static/styles.css` | 40 KB | 11.4 KB | 20.4 KB | `wc -c site/static/styles.css` |
| `site/static/motion.js` | 5 KB | none | 2.7 KB (byte-identical to Whydunit's) | `wc -c`; `cmp` with the other repo |
| Home HTML (built) | 30 KB | 21.1 KB | 24.0 KB | `wc -c site/_dist/index.html` |
| Home first load, uncompressed (HTML + CSS + JS + icon + favicon) | 100 KB | 59.0 KB | 73.6 KB | sum of the above plus `icon.png` and `favicon.png` |
| New image assets, fonts, CDNs, third-party requests | 0 | 0 | 0 | `git diff --stat site/static` shows only `motion.js` |
| Hero sequence | ≤ 3.2 s, once | none | 3.16 s | §4.1 table |
| CLS | 0 | 0 | 0 | the snippet in §6.3 |
| LCP element | static text | subline | subline, about 0.45 s local | the snippet in §6.3 |

| App item | Budget |
|---|---|
| CPU after the entrance settles (Welcome, Checks, Tests, Report, each test) | 0% in Activity Monitor within 2 s |
| Loops | only the `LaptopView(scanning: true)` beam, only while `model.facts == nil` |
| Entrance lengths | lid ≤ 1 s; card deal ≤ 0.6 s; row flips on the existing 70 ms stagger; verdict flip ≤ 0.5 s |
| `HoverTilt` views on screen | ≤ 8 (Tests: 6 tiles) |
| macOS 13 | every API outside `Compat.swift` is macOS 13 |
| New files | `App/DesignSystem/Compat.swift`, `App/Views/LaptopView.swift`; no assets, no dependencies |

### 6.2 Acceptance checklist

**Website, all pages**

- [ ] `python tools/build_site.py --check` passes. It covers links, including `/motion.js`, one `<h1>`, alt text,
  contrast with exactly two `:root` blocks, and no `data-theme`/`localStorage`.
- [ ] With Reduce Motion: the lid is open and the rows are filled; no chips, beam, deal or tilt. The flip button
  swaps faces instantly.
- [ ] With JavaScript off: the page is complete and still, the flip button stays hidden, and the front face shows
  every row.
- [ ] Light and dark are right. The report card and chips stay light in both, and the laptop reads on both
  backgrounds.
- [ ] At 360×740: no horizontal scroll, the laptop sits above the card and the chips fly down.
- [ ] Firefox shows the reveal fallback. Print of a guide shows no shadows or motion artifacts.
- [ ] Performance: no long task from `motion.js`, and no layout or paint while tilting.

**Website, hero**

- [ ] The lid opens, the screen lights and the beam sweeps once. The chips pop out and fly to the card while its
  rows fill in. The page is still after about 3.2 s.
- [ ] The corner button flips the card to "Where each line comes from" and back, with `aria-pressed` in sync.
  Keyboard (Tab, Space, Enter) and tap both work, and hover never flips.
- [ ] The headline, subline and both buttons never move.

**Website, sections and guides**

- [ ] Cards and guide links rise in once and tilt at most 7°, with glare under the pointer. The table never moves.
- [ ] Guide `.summary` and `pre` boxes have a static `--z1` shadow. Checklist boxes pop when ticked (not under Reduce
  Motion).

**App** (on a Mac, or in CI once it compiles)

- [ ] Welcome: the lid opens once. The laptop tilts up to 8°, and the choice tiles tilt up to 7° and sink when
  pressed. On macOS 14+ a tile's symbol bounces once on hover.
- [ ] Checks: the laptop beam sweeps while checking and stops when the facts arrive. The small `ProgressView` still
  announces busy. Rows flip in on the first run only. A changed verdict flips down over the old one, and VoiceOver
  hears the same announcement as before.
- [ ] Tests: keys sink while held and spring back. Tick-by-hand clicks still land. Tiles tilt, and the tests
  themselves don't move.
- [ ] Report:
  - the card turns over from its icon back once per visit, then tilts up to 4° with glare;
  - on macOS 14+ it leans back as it scrolls away;
  - Save PNG is byte-for-byte unaffected (compare a PNG saved before and after the change).
- [ ] macOS 13: everything works without the Compat touches. Reduce Motion: fades only, no beam, no tilt.

### 6.3 How to verify without a Mac

```sh
python tools/build_site.py --check                     # site contract, contrast, links (incl. /motion.js)
wc -c site/static/styles.css site/static/motion.js     # budgets
cmp site/static/motion.js ../whydunit/site/static/motion.js   # shared file, adjust the path to your checkout
python tools/build_site.py
mkdir -p <scratchpad>/pages/tirekick && cp -r site/_dist/. <scratchpad>/pages/tirekick/
python -m http.server 8766 --directory <scratchpad>/pages   # open http://localhost:8766/tirekick/
```

- **Chromium:** DevTools as in Whydunit's §6.3 covers reduced motion, dark mode, the 360px device toolbar, the
  layout-shift and LCP observers, and stepping the hero with `document.getAnimations()`.
- **Firefox on Windows** covers the reveal fallback. **Safari** needs the owner's Mac or iPhone.
- **App, by review until CI compiles it:**

```sh
grep -rn "#available" App/ | grep -v DesignSystem/Compat.swift                          # nothing
grep -rn "symbolEffect\|phaseAnimator\|keyframeAnimator\|visualEffect\|\.smooth(\|spring(duration" App/ | grep -v Compat.swift   # nothing
grep -rn "repeatForever\|phaseAnimator\|TimelineView" App/                                # only Views/LaptopView.swift
grep -n "rotation3DEffect\|HoverTilt\|FlipFaces\|shadow\|scrollLean" App/Views/ReportCardView.swift   # nothing: the PNG stays clean
grep -rn "\.animation(" App/ | grep -v "value:"                                           # nothing
git diff -U0 App/ | grep "^-.*accessibility"                                              # nothing removed
```

- Then the macOS CI build is the first compile. Until it's green, call the app code "written, not compiled".

### 6.4 Proposals for other owners (not made here)

- **architect** (BUILD_PLAN §7, frozen). Replace three lines:
  - Welcome: "96 pt app icon" becomes "`LaptopView` (106 pt, the app icon on its screen), lid opens once".
  - Checks: "centered `ProgressView` + 'Checking this Mac…'" becomes "`LaptopView(scanning: true)` above a small
    `ProgressView` + 'Checking this Mac…'".
  - Rows: "appear with `.opacity.combined(with: .move(edge: .top))`" becomes "appear with `.flip` (MOTION.md §5)".
  - Also add "Motion: docs/MOTION.md" to §7.
- **infra** (`tools/build_site.py` `check()`): add the same size caps as Whydunit's §6.4. In CI, run the first four
  app greps above as failures.
- **infra** (`site/**`): apply §1.7 and §4, confirm the back-face copy against BUILD_PLAN §8, and keep `motion.js`
  byte-identical with Whydunit's.
