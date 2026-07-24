#!/usr/bin/env bash
# Link-class gate — run before every deploy (bash scripts/check-links.sh).
#
# Pins the "absolute self-link" bug class (BUG-LOG.md 2026-07-03): every page
# in this repo is served from ariantra.com, so links to our own host must be
# root-relative (/#faq, /blog.html). An absolute https://ariantra.com/... link
# navigates to whatever is CURRENTLY DEPLOYED — from a local preview or a
# staging host that means "the old site". Cross-host links (games./studio./
# ari. — formerly kidgemini., renamed 2026-07-17) are exempt; so are metadata
# URLs (canonical, og:, favicon, JSON-LD), which SHOULD be absolute.
#
# Also blocks any external stylesheet dependency (the api.ariantra.com brand
# CSS 403 broke the live menu on 2026-07-03 — all CSS must be inline).

set -euo pipefail
cd "$(dirname "$0")/.."

PAGES=(index.html privacy.html terms.html ariantra-deploy/*.html)
fail=0

for f in "${PAGES[@]}"; do
  # Navigation hrefs to our own host (absolute) — metadata lines are excluded
  # by only looking at href= occurrences that are NOT rel=canonical/icon lines.
  bad=$(grep -nE 'href="https?://(www\.)?ariantra\.com' "$f" \
        | grep -vE 'rel="(canonical|icon|apple-touch-icon)"' || true)
  if [ -n "$bad" ]; then
    echo "✗ $f — absolute self-link(s); make them root-relative:"
    echo "$bad" | sed 's/^/    /'
    fail=1
  fi

  # Order-independent: match <link> tags that carry BOTH rel="stylesheet" and
  # an https?:// URL, regardless of which attribute comes first (href="https://
  # ..." rel="stylesheet" is how every page in this repo actually writes it —
  # a positional regex silently never matches that order).
  ext_css=$(grep -nE '<link[^>]*>' "$f" \
        | grep -E 'rel="stylesheet"' \
        | grep -E 'https?://' \
        | grep -v fonts.googleapis || true)
  if [ -n "$ext_css" ]; then
    echo "✗ $f — external stylesheet dependency (must be inline):"
    echo "$ext_css" | sed 's/^/    /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "✓ link audit clean — no absolute self-links, no external CSS (fonts exempt)"
fi
exit $fail
