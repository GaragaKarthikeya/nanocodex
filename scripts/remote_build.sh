#!/usr/bin/env bash
# Offload synth/impl/bitgen to a beefier remote workstation over Tailscale,
# then sync the resulting bitstream back so `make program` (which needs the
# board's physically-attached hw_server) still runs locally.
#
# The build itself runs inside a detached tmux session on the remote host, so
# it survives a dropped connection or you closing this terminal. Output is
# unbuffered and tee'd to a log file, which this script tails live -- if you
# Ctrl-C or disconnect partway through, just re-run the same command: it
# detects the still-running tmux session and reattaches to the log instead
# of restarting the build.
#
# Usage: scripts/remote_build.sh <proj_dir> <board_dir> <top>
# Env vars (with defaults for the current remote workstation):
#   REMOTE_HOST     (required) hostname or IP of the build machine
#   REMOTE_USER     (required) username on that machine
#   REMOTE_VIVADO_SETTINGS (default: 2026.1/Vivado/settings64.sh on the remote)
#   REMOTE_DIR      (default: nanocodex on the remote)
set -euo pipefail

if [ $# -ne 3 ]; then
    echo "Usage: $0 <proj_dir> <board_dir> <top>" >&2
    exit 1
fi

proj_dir="$1"
board_dir="$2"
top="$3"

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
remote_vivado_settings="${REMOTE_VIVADO_SETTINGS:-2026.1/Vivado/settings64.sh}"
remote_dir="${REMOTE_DIR:-nanocodex}"
remote="${remote_user}@${remote_host}"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

session="nanocodex_build_$(echo "$proj_dir" | tr '/.' '__')"
remote_log="$remote_dir/$proj_dir/build/build.log"
remote_runner="$remote_dir/.remote_build_runner_${session}.sh"

if ssh "$remote" "tmux has-session -t $session 2>/dev/null"; then
    echo "==> Build already running on $remote_host in tmux session '$session' -- reattaching to log"
else
    echo "==> Syncing repo to $remote:$remote_dir"
    rsync -az --delete \
        --exclude '.git/' \
        --exclude '*/build/' \
        --exclude '.Xil/' \
        --exclude '*.jou' \
        --exclude '*.log' \
        ./ "$remote:$remote_dir/"

    echo "==> Launching build on $remote_host ($(ssh "$remote" nproc) cores) in tmux session '$session'"
    # The heredoc is deliberately unquoted: every variable in the runner
    # script below is local configuration that has to be baked in here, since
    # the remote shell never sees this script's environment.
    # shellcheck disable=SC2087
    ssh "$remote" "mkdir -p $remote_dir/$proj_dir/build && cat > $remote_runner" <<EOF
#!/bin/bash
source $remote_vivado_settings
cd $remote_dir
stdbuf -oL -eL vivado -mode batch -source scripts/build.tcl -tclargs $proj_dir $board_dir $top 2>&1 | tee $proj_dir/build/build.log
echo "BUILD_EXIT_CODE:\${PIPESTATUS[0]}" >> $proj_dir/build/build.log
EOF
    ssh "$remote" "chmod +x $remote_runner && tmux new-session -d -s $session bash $remote_runner"
fi

echo "==> Streaming $remote:$remote_log (Ctrl-C is safe -- the remote build keeps running; re-run this script to reattach)"
ssh "$remote" "tail -n +1 -f $remote_log" | while IFS= read -r line; do
    echo "$line"
    if [[ "$line" == BUILD_EXIT_CODE:* ]]; then
        break
    fi
done

exit_code=$(ssh "$remote" "grep -o 'BUILD_EXIT_CODE:[0-9]*' $remote_log | tail -1 | cut -d: -f2")
ssh "$remote" "tmux kill-session -t $session 2>/dev/null; rm -f $remote_runner" || true

if [ "$exit_code" != "0" ]; then
    echo "Remote build failed (exit $exit_code) -- see $remote_log on $remote_host"
    exit 1
fi

echo "==> Syncing bitstream + reports back"
mkdir -p "$proj_dir/build"
rsync -az "$remote:$remote_dir/$proj_dir/build/" "$proj_dir/build/"

echo "Remote build complete: $proj_dir/build/$top.bit"
