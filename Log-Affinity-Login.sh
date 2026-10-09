#!/bin/bash
# Capture Affinity login-flow logs under the patched Wine.
# Usage: ./Log-Affinity-Login.sh [WINEPREFIX]
# Log: /tmp/opencode/affinity-login-<timestamp>.log
set -u
PREFIX="${1:-/home/matt/Music/.AffinityLinux}"
WINE="$PREFIX/ElementalWarriorWine/bin/wine"
AFFINITY="$PREFIX/drive_c/Program Files/Affinity/Affinity/Affinity.exe"
LOG="/tmp/opencode/affinity-login-$(date +%Y%m%d-%H%M%S).log"

export WINEPREFIX="$PREFIX"
export DXVK_ASYNC=0 DXVK_LOG_LEVEL=none
export VKD3D_DEBUG=none VKD3D_FEATURE_LEVEL=12_1 VKD3D_SHADER_DEBUG=none
export VKD3D_SHADER_MODEL=6_5 VKD3D_CONFIG=swapchain_legacy
export WINEDEBUG="+combase,+twinapi,+process"

echo "prefix=$PREFIX"
echo "wine=$WINE ($("$WINE" --version 2>/dev/null))"
echo "log=$LOG"
echo "Click 'Log in or sign up' in Affinity, complete the browser side,"
echo "then approve the 'Open Affinity?' handoff."
echo ""
"$WINE" "$AFFINITY" >"$LOG" 2>&1 &
echo "pid=$! watching $LOG"
echo "--- login-relevant lines (live) ---"
grep --line-buffered -i -E "SharedStorage|RedeemToken|AddFile|RemoveFile|affinity://|RoGetActivationFactory.*(SharedStorage|DataTransfer)" "$LOG" | tail -n 30
