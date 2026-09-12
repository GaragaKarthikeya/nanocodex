#!/usr/bin/env bash
# Look up a net's package pin against the official Xilinx board_part XML data
# (schematic-derived, not the UG1267 PDF text -- see boards/*/docs/errata.md
# for why the PDF text cannot be trusted on its own).
#
# Usage: scripts/lookup_pin.sh <board> <search-term>
# Example: scripts/lookup_pin.sh zcu104 clk_125
#          scripts/lookup_pin.sh zcu104 GPIO_LED
set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <board> <search-term>" >&2
    exit 1
fi

board="$1"
term="$2"
xml_dir="boards/$board/vendor/board_files/$board"

if [ ! -d "$xml_dir" ]; then
    echo "No vendored board files at $xml_dir" >&2
    echo "(Not every board has one -- fall back to independently cross-checking the manual: see README.md 'Verifying pins on a new board'.)" >&2
    exit 1
fi

found=0
while IFS= read -r -d '' pins_xml; do
    matches=$(grep -i "$term" "$pins_xml" || true)
    if [ -n "$matches" ]; then
        found=1
        echo "== $pins_xml =="
        echo "$matches"
    fi
done < <(find "$xml_dir" -name "part0_pins.xml" -print0)

if [ "$found" -eq 0 ]; then
    echo "No match for '$term' in official board_part pin data." >&2
    echo "This net may not be exposed by the official board interface (e.g. CLK_125 on zcu104 -- see errata.md)." >&2
    echo "Cross-check against the manual AND a web search for known errata before trusting the PDF alone." >&2
    exit 2
fi
