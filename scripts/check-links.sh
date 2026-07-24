#!/usr/bin/env bash
# Link-class gate — run before every deploy (bash scripts/check-links.sh).
#
# Pins the "absolute self-link" bug class (BUG-LOG.md 2026-07-03): every page
# in this repo is served from ariantra.com, so links to our own host must be
# root-relative (/#faq, /blog.html). An absolute https://ariantra.com/... link
# navigates to whatever is CURRENTLY DEPLOYED — from a local preview or a
# staging host that means "the old site". Cross-host links (games./studio./
# games-lab. — formerly kidgemini./ari., renamed 2026-07-17) are exempt; so are
# metadata URLs (canonical, og:, favicon, JSON-LD), which SHOULD be absolute.
#
# Also blocks any external stylesheet dependency (the api.ariantra.com brand
# CSS 403 broke the live menu on 2026-07-03 — all CSS must be inline).
#
# Self-test (BUG-LOG.md 2026-07-14: the external-CSS check was blind for 11
# days because a positional regex never matched real attribute order):
#   bash scripts/check-links.sh --self-test
# runs the checks against scripts/fixtures/ — two files that MUST be caught
# (one per bug class, including the URL-first <link> order the old regex
# missed) and one that MUST pass clean (fonts/metadata/cross-host exemptions).

set -euo pipefail
cd "$(dirname "$0")/.."

# Check one page; prints violations and returns 1 if any found.
check_page() {
  local f=$1 page_fail=0 bad ext_css

  # Navigation hrefs to our own host (absolute) — metadata lines are excluded
  # by only looking at href= occurrences that are NOT rel=canonical/icon lines.
  bad=$(grep -nE 'href="https?://(www\.)?ariantra\.com' "$f" \
        | grep -vE 'rel="(canonical|icon|apple-touch-icon)"' || true)
  if [ -n "$bad" ]; then
    echo "✗ $f — absolute self-link(s); make them root-relative:"
    echo "$bad" | sed 's/^/    /'
    page_fail=1
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
    page_fail=1
  fi

  return $page_fail
}

if [ "${1:-}" = "--self-test" ]; then
  st_fail=0

  # Every bad-*.html fixture must be caught.
  for f in scripts/fixtures/bad-*.html; do
    if check_page "$f" >/dev/null; then
      echo "✗ self-test: $f slipped past the checks (must be caught)"
      st_fail=1
    else
      echo "✓ self-test: $f correctly caught"
    fi
  done

  # good.html must pass clean (no false positive on the exemptions).
  if check_page scripts/fixtures/good.html; then
    echo "✓ self-test: good.html correctly clean"
  else
    echo "✗ self-test: false positive on scripts/fixtures/good.html (see above)"
    st_fail=1
  fi

  [ "$st_fail" -eq 0 ] && echo "✓ self-test passed"
  exit $st_fail
fi

PAGES=(index.html blog.html how-kids-build-games-with-ai.html privacy.html terms.html ariantra-deploy/*.html)
fail=0

for f in "${PAGES[@]}"; do
  check_page "$f" || fail=1
done

if [ "$fail" -eq 0 ]; then
  echo "✓ link audit clean — no absolute self-links, no external CSS (fonts exempt)"
fi
exit $fail
