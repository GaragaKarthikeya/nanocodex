#!/usr/bin/env bash
# Quick peek at a remote build without attaching to its live log -- shows
# whether it's still running and the last few lines of progress.
#
# Usage: scripts/remote_status.sh <proj_dir> [board_dir]
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <proj_dir>" >&2
    exit 1
fi

proj_dir="$1"

if [ -z "${REMOTE_HOST:-}" ] || [ -z "${REMOTE_USER:-}" ]; then
    cat >&2 <<'MSG'
Remote builds need a host to build on. Set these first:

    export REMOTE_HOST=your-build-machine   # hostname or IP reachable over ssh
    export REMOTE_USER=your-username

Optional:
    export REMOTE_DIR=nanocodex             # checkout path on the remote (default: nanocodex)
    export REMOTE_VIVADO_SETTINGS=2026.1/Vivado/settings64.sh

The remote needs Vivado, tmux and rsync installed, and you need key-based ssh
access to it (this script never prompts for a password).
MSG
    exit 1
fi

remote_host="$REMOTE_HOST"
remote_user="$REMOTE_USER"
remote_dir="${REMOTE_DIR:-nanocodex}"
remote="${remote_user}@${remote_host}"

session="nanocodex_build_$(echo "$proj_dir" | tr '/.' '__')"
remote_log="$remote_dir/$proj_dir/build/build.log"

if ssh "$remote" "tmux has-session -t $session 2>/dev/null"; then
    echo "== still running (tmux session '$session' on $remote_host) =="
else
    echo "== not currently running on $remote_host =="
fi

echo "== last 15 lines of $remote_log =="
ssh "$remote" "tail -15 $remote_log 2>/dev/null" || echo "(no log yet)"
