#!/bin/bash
#
# Fix-Wine-TLS.sh
# Restores Wine's builtin crypt32 in a prefix where it was overridden
# with native (e.g. by installers or winetricks recipes).
#
# Background: Microsoft's native crypt32.dll running under Wine cannot
# validate certificate chains against Wine's registry certificate stores,
# so every TLS handshake that reaches cert verification fails with
# ERROR_INTERNET_SECURITY_CHANNEL_ERROR (12157). Symptoms in Affinity:
# update check fails ("Could not establish trust relationship"), CanvaAI /
# cloud features fail, asset downloads fail. Wine's builtin crypt32 reads
# the prefix ROOT store correctly.
#
# This only touches HKCU\Software\Wine\DllOverrides in the target prefix.
# Running processes keep their loaded DLLs; new processes pick up the fix.
# No Wine rebuild required.
#
# Usage:
#   ./Fix-Wine-TLS.sh                                  # uses $WINEPREFIX
#   WINEPREFIX=/path/to/prefix ./Fix-Wine-TLS.sh
#   WINEPREFIX=/path/to/prefix WINE=/path/to/wine ./Fix-Wine-TLS.sh
#

set -e

WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
WINE="${WINE:-$(command -v wine || true)}"

if [ -z "$WINE" ]; then
  echo "ERROR: no wine binary found. Set WINE=/path/to/wine" >&2
  exit 1
fi

if [ ! -d "$WINEPREFIX" ]; then
  echo "ERROR: prefix not found: $WINEPREFIX" >&2
  exit 1
fi

export WINEPREFIX
export WINEDEBUG="${WINEDEBUG:--all}"

echo "Prefix: $WINEPREFIX"
echo "Wine:   $WINE"

current="$(wine reg query 'HKCU\Software\Wine\DllOverrides' /v '*crypt32' 2>/dev/null | grep -i 'crypt32' || true)"
if [ -n "$current" ]; then
  echo "Current override: $current"
else
  echo "Current override: (none, Wine default = builtin)"
fi

# Explicit builtin beats deleting: survives tools that re-add native.
wine reg add 'HKCU\Software\Wine\DllOverrides' /v '*crypt32' /t REG_SZ /d builtin /f >/dev/null 2>&1

echo "Set '*crypt32' = builtin."
echo "Done. New processes in this prefix now use Wine's crypt32."
echo "Note: already-running apps keep going until restarted."
