#!/usr/bin/env bash
# Scaffold a new project under projects/<name>/ with an rtl/ dir and a stub top-level module + XDC.
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <project_name>"
    exit 1
fi

name="$1"
dir="projects/$name"

if [ -e "$dir" ]; then
    echo "Error: $dir already exists" >&2
    exit 1
fi

mkdir -p "$dir/rtl"

cat > "$dir/rtl/$name.v" <<EOF
module $name (
    input  wire clk_125_p,
    input  wire clk_125_n
);

    wire clk;
    IBUFDS clk_ibufds (
        .I  (clk_125_p),
        .IB (clk_125_n),
        .O  (clk)
    );

    // TODO: design goes here

endmodule
EOF

cat > "$dir/$name.xdc" <<EOF
# Project-specific pin constraints for $name.
# Board-level fixed nets (clock, LEDs, ...) live in boards/<board>/xdc/ and
# are pulled in automatically by scripts/build.tcl.
EOF

echo "Created $dir"
