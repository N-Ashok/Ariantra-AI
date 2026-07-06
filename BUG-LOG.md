# Ariantra Site — Bug Log

Record of bugs that reached the deployed site, root causes, class-level fixes,
and the prevention gate. Same discipline as the MarksZen `docs/BUG-FIX-LOG.md`:
**read this before fixing anything; fix the class, not the symptom; the log
entry ships with the fix.** Newest first.

---

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
