# Ariantra Site — Bug Log

Record of bugs that reached the deployed site, root causes, class-level fixes,
and the prevention gate. Same discipline as the MarksZen `docs/BUG-FIX-LOG.md`:
**read this before fixing anything; fix the class, not the symptom; the log
entry ships with the fix.** Newest first.

---

### 2026-07-24 — Tech-debt pass: root/deploy drift (inverted), rename closeout, llms.txt, IP disclosure, check-links self-test

- **Root/deploy drift — inverted this time.** `blog.html` and
  `how-kids-build-games-with-ai.html` existed only in `ariantra-deploy/`
  while root's `sitemap.xml` already listed them — the same drift class as
  the 2026-07-14 entry, in the opposite direction (root is the source of
  truth; deploy is the staging copy). Backfilled both to root and added both
  root copies to `check-links.sh`'s `PAGES` list, which had silently not been
  scanning them.
- **Stray `index1.html` deleted** — an outdated duplicate of the homepage
  that would ship the old site if ever uploaded by accident (recoverable from
  git history). `Session Log.html` left in place pending an owner decision.
- **Rename closeout (platform TECH_DEBT #62d):** the last two `kidgemini`
  references — `trackEvent('kidgemini_click', …)` on the two games-lab CTA
  buttons — renamed to `ari_click` (owner decision 2026-07-24; Mixpanel is
  now the only analytics destination, GA/Clarity having been removed, so the
  continuity cost is one event stream). Repo now has zero `kidgemini` or
  `ari.ariantra.com` references.
- **`llms.txt` added** (root + deploy) — the landing had none despite the
  sitewide SEO/AI-answer rule; describes all five pages, the sibling
  surfaces, and how assistants should cite Ariantra.
- **IP-retention disclosure completed (platform TECH_DEBT #29):**
  `privacy.html`'s Technical-usage-data row now states that IP is recorded on
  sign-ins, game plays and score submissions with a short capped history, and
  adds score-integrity to the purpose. Both copies.
- **`check-links.sh` grew the fixture-based self-test** the 2026-07-14 entry
  asked for: `bash scripts/check-links.sh --self-test` runs the checks
  against `scripts/fixtures/` — two must-be-caught files (one per bug class,
  including the URL-first `<link>` attribute order the old positional regex
  missed) and one must-pass-clean file covering every exemption (Google
  Fonts, absolute metadata, cross-host links). Verified the self-test mode
  was a silent no-op before implementing it, and that both bad fixtures are
  caught and the good one passes after.
- **Not live yet:** all of the above is repo-only until the next
  `ariantra-deploy/*` upload to Hostinger (the 2026-07-14-era pages went live
  before this pass — verified 2026-07-24: blog answers 200, games-lab links
  present).

### 2026-07-14 — `check-links.sh` was blind to the exact regression it exists to prevent

- **Symptom:** none visible yet — caught by a full-repo review, not a live
  incident. But the gate has been silently non-functional since it was written
  on 2026-07-03.
- **Root cause — positional-regex class:** the external-stylesheet check
  (`<link[^>]*stylesheet[^>]*https?://`) required the word "stylesheet" to
  appear *before* the URL inside the tag. Every real `<link>` in this repo —
  including the Google Fonts link this script's own comment calls "exempt" —
  is written `href="https://..." rel="stylesheet"`, URL first. That ordering
  never matched, so the check silently never ran. Reproduced directly: a
  synthetic tag copying the 2026-07-03 `api.ariantra.com/brand/...css`
  incident's exact shape slipped straight past the old regex.
- **Fix (class level):** replaced the single positional regex with an
  order-independent AND-chain — extract every `<link ...>` tag, then require
  it to contain `rel="stylesheet"` **and** `https?://` **and not**
  `fonts.googleapis`, regardless of attribute order.
- **Prevention:** re-verified against the live repo (`bash scripts/check-links.sh`
  still prints "clean" — no false positive on the legitimate Google Fonts
  link) and against a reproduction of the original incident's link shape
  (now correctly caught). Anyone touching this script again should add a
  fixture-based check rather than trusting a single hand-run repro.

### 2026-07-14 — Full-repo review: 13 correctness/accessibility/SEO fixes across index.html, privacy.html, terms.html

- **Mixpanel never received a custom event.** `trackEvent()` only called
  `gtag()`/`clarity()`; `mixpanel.track()` was never wired up despite
  `mixpanel.init()` running on every page load. Fixed by adding the missing
  call — every `plan_selected`/`whatsapp_click`/etc. event now reaches all
  three analytics destinations.
- **WhatsApp deep link silently failed on iPad.** The mobile-vs-desktop check
  (`/android|iphone|ipad|ipod/i.test(navigator.userAgent)`) misses iPadOS 13+
  Safari, which reports as desktop "MacIntel" with no "ipad" token. Fixed by
  adding the standard `navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1`
  fallback that distinguishes a touch iPad from an actual Mac.
- **Two of three WhatsApp entry points were mistagged in analytics** — the
  location ternary keyed off CSS classes (`hero-cta`/`cta-big`) that no wa.me
  link actually carried, so pricing and footer clicks both fell into the
  default `'nav'` bucket. Replaced with explicit `data-location` attributes on
  each of the three links (`pricing` / `footer` / `floating`).
- **Primary CTA buttons failed WCAG AA contrast sitewide** — white text on
  `--accent` (#FF5C00) computed to ≈3.10:1, below the 4.5:1 minimum for normal
  text. Fixed by switching CTA text color to the existing `--black` (#0f172a)
  token wherever it sits on an accent background (nav, hero, step numbers,
  pricing badge/CTA, final CTA) — reuses an existing token, ≈5.77:1 contrast,
  no change to the brand accent color itself. Also fixed the same pattern on
  the unused-but-latent `.nav-btn` rule while sweeping, and on privacy.html's
  and terms.html's `.nav-book` — same bug, caught by the visual verification
  pass (computed-style check), missed by the original text-only review
  because that pass only scanned index.html.
- **Mobile bottom tab bar's active tab never updated.** `.nav-tab.on` was
  hardcoded onto "Home" with no JS keeping it in sync. Added an
  `IntersectionObserver` on `#videos` that toggles the highlighted tab (and
  `aria-current`) between Home and Videos as that section scrolls in/out —
  the only two in-page destinations in the tab bar.
- **privacy.html and terms.html shipped with zero SEO metadata** — no meta
  description, OpenGraph, canonical, or JSON-LD (index.html had all four).
  Added a full metadata block to both, matching index.html's pattern.
- **Design-token drift:** `--text-muted` was `#777` in index.html but
  `#64748b` in privacy.html/terms.html. Standardized on `#64748b` (still
  ≥4.5:1 on white) and removed a hardcoded `#777` in `.pricing-note` that
  duplicated the old value instead of referencing the token. Also moved
  `.price-feats li.lim`'s `#888` (≈3.55:1, failed AA) onto the same token.
- **Contact email inconsistency** — index.html used `contact@ariantra.com`;
  privacy.html/terms.html used `hello@ariantra.com`. Standardized on
  `contact@ariantra.com` everywhere (owner-confirmed).
- **Security/accessibility on the game modal:** `#gameModalLink`
  (`target="_blank"` to a dynamically-set third-party game URL) had no
  `rel="noopener"`; `#gameModalClose` was an icon-only `✕` button with no
  accessible name. Both fixed.
- **Deploy drift:** `ariantra-deploy/` (the directory `check-links.sh` treats
  as the pre-deploy staging copy) was ~3 days behind root, missing the latest
  redesign and privacy disclosures. Synced `index.html`, `privacy.html`,
  `terms.html`, and `sitemap.xml` from root (owner-confirmed); also bumped
  `sitemap.xml` `lastmod` to today for the three pages actually changed.
- **Prevention:** all JS changes verified with a syntax check across every
  inline `<script>` block; every contrast fix re-computed against WCAG's
  relative-luminance formula rather than eyeballed; `check-links.sh` re-run
  clean after the sync.

### 2026-07-03 — Broken live menu + "links lead to the old site" (two bugs, one deploy)

- **Symptom:** (1) ariantra.com's header rendered as unstyled blue links. (2)
  Clicking nav "Videos" (and later footer FAQ / Our team) navigated to the
  previously-deployed site instead of scrolling the current page.
- **Root cause (1) — external-CSS dependency class:** commit `db85c38` swapped
  the landing's inline header for the generated `ar-nav` partial, whose styling
  loads from `https://api.ariantra.com/brand/ariantra-brand.v1.css`. That URL
  returns 403 (the platform's brand-publish step never shipped; the commit even
  said "Deploy AFTER the platform ships brand v1.1"). One dead external host =
  a naked menu in production.
- **Root cause (2) — absolute self-link class:** pages linked their own host
  absolutely (`https://ariantra.com/#videos`, `https://www.ariantra.com`,
  footer `https://ariantra.com/#faq`…). An absolute self-link navigates to
  whatever is *currently deployed* on that host — from a local preview or
  before a deploy, that is "the old site". The class recurred three times in
  one day (nav Videos → footer FAQ/team → footer company link) because the
  first two fixes were symptom-level.
- **Fix (class level):**
  - All CSS inline in every page — no external stylesheet can strip the menu
    (Google Fonts exempt: it degrades to fallback fonts, not a broken layout).
  - Same-host links are root-relative everywhere (`/#faq`, `/blog.html`,
    logo `/`; on index.html in-page anchors `#videos`…). Only cross-host links
    (games./studio./kidgemini.ariantra.com, wa.me, socials) are absolute.
    Metadata (canonical, og:, favicon, JSON-LD) stays absolute by design.
- **Prevention:** `scripts/check-links.sh` — fails on any absolute self-link or
  external stylesheet across all pages (incl. `ariantra-deploy/`). **Run it
  before every deploy.** It caught the third instance (footer company link)
  the first time it ran.
- **Class sweep of the app repos (same date):** the platform's shared footer
  linked `games.ariantra.com`/`studio.ariantra.com` absolutely — self-links on
  its own surfaces (and dev-mode ejection to prod) → now `/catalog`,`/studio`.
  KidGemini's footer linked itself absolutely → now `/`. `www.ariantra.com`
  normalized to the apex canonical in Footer.tsx, ArFooter.tsx, and the
  generated footer partial.
- **Related:** header/menu unification of the same date (canonical menu:
  Games · KidGemini · How it works · Videos · Sign in · Book CTA — mirrored in
  Ariantra-Platform `src/lib/ui/nav-links.ts` and the Game repo's `ArNav.tsx`;
  those repos' headers ship via their own deploys).
