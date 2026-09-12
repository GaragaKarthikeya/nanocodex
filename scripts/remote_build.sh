#!/usr/bin/env bash
# Offload synth/impl/bitgen to a beefier remote workstation over Tailscale,
# then sync the resulting bitstream back so `make program` (which needs the
# board's physically-attached hw_server) still runs locally.
#
# Usage: scripts/remote_build.sh <proj_dir> <board_dir> <top>
# Env vars (with defaults for the current remote workstation):
#   REMOTE_HOST     (default: redhatacademy23)
#   REMOTE_USER     (default: digital3)
#   REMOTE_VIVADO_SETTINGS (default: ~/2026.1/Vivado/settings64.sh on the remote)
#   REMOTE_DIR      (default: ~/nanocodex on the remote)
set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <proj_dir> <board_dir> <top>" >&2
    exit 1
fi

proj_dir="$1"
board_dir="$2"
top="$3"

remote_host="${REMOTE_HOST:-redhatacademy23}"
remote_user="${REMOTE_USER:-digital3}"
remote_vivado_settings="${REMOTE_VIVADO_SETTINGS:-2026.1/Vivado/settings64.sh}"
remote_dir="${REMOTE_DIR:-nanocodex}"
remote="${remote_user}@${remote_host}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

echo "==> Syncing repo to $remote:$remote_dir"
rsync -az --delete \
    --exclude '.git/' \
    --exclude '*/build/' \
    --exclude '.Xil/' \
    --exclude '*.jou' \
    --exclude '*.log' \
    ./ "$remote:$remote_dir/"

echo "==> Building on $remote_host ($(ssh "$remote" nproc) cores)"
ssh "$remote" "source $remote_vivado_settings && cd $remote_dir && vivado -mode batch -source scripts/build.tcl -tclargs $proj_dir $board_dir $top"

echo "==> Syncing bitstream + reports back"
mkdir -p "$proj_dir/build"
rsync -az "$remote:$remote_dir/$proj_dir/build/" "$proj_dir/build/"

echo "Remote build complete: $proj_dir/build/$top.bit"
