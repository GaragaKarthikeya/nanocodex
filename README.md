# fpga

Personal FPGA workstation repo. Layout:

```
boards/<board>/          board-level facts, reused across every project
  board.tcl                 part number and other board identity settings
  xdc/                       fixed hardware nets (clocks, LEDs, ...) as separate .xdc files
  docs/                      datasheets / user guides / pin-mapping notes

projects/<project>/      one FPGA design
  rtl/                      Verilog sources
  <project>.xdc              project-specific pin constraints only
  build/                    generated bitstream + reports (gitignored)

scripts/                  Vivado automation, board-agnostic
  build.tcl                 synth -> impl -> bitstream, given a project + board dir
  program.tcl                program a bitstream over JTAG
  new_project.sh             scaffold a new project directory
```

## Usage

```
make build PROJ=hello_world BOARD=zcu104
make program PROJ=hello_world BOARD=zcu104
make new PROJ=my_new_design
```

`PROJ` and `BOARD` default to `hello_world` and `zcu104`.

## Adding a new board

1. `mkdir -p boards/<board>/{xdc,docs}`
2. Drop the board's user guide/datasheet PDF into `boards/<board>/docs/`
3. Write `boards/<board>/board.tcl` with `set board_part_fpga <part>`
4. Add one `.xdc` file per fixed net group (clocks, LEDs, buttons, ...) under `boards/<board>/xdc/`
5. Verify every pin against real hardware before trusting it (see "Verifying pins"
   below) and keep an `errata.md` of anything the manual gets wrong

## Verifying pins on a new board

Manuals can be wrong, and not just as a one-off typo — UG1267 for the zcu104 has
*multiple* known text/schematic mismatches (clock pins, DDR4 SODIMM pins, FMC bank
assignments) that were never fixed in the PDF across its whole revision history. See
`boards/zcu104/docs/errata.md` for the one that cost hours here. **Don't hand-transcribe
pin tables from a PDF as ground truth.** In order of trust:

1. **Official board_part files first.** Xilinx publishes Apache-2.0 board definitions
   (schematic-derived) at `github.com/Xilinx/XilinxBoardStore` for most eval boards.
   Vendor the relevant `boards/<board>/<version>/` directory into
   `boards/<board>/vendor/board_files/<board>/`, register it in `board.tcl` via
   `board.repoPaths`, and query it with `scripts/lookup_pin.sh <board> <net-name>`
   before typing anything out of a manual by hand. This is real schematic data, not
   prose that can go stale.
2. If a net isn't covered by the official board interfaces (common for pins not tied
   to a named component, e.g. general-purpose clocks) — cross-check the manual's pin
   table against a *rendered image* of the actual PDF page (text extraction can
   misalign columns), then web-search `"<board name>" "<net name>" xdc` — community
   constraint files and vendor support-forum threads often have the known correction
   already documented.
3. Bring up new pins incrementally and prove each one independently regardless of
   source:
   - LEDs/outputs: drive them to a constant value first, no clock involved.
   - A clock: latch it into a register on an edge you control (e.g. a pushbutton)
     and read the value back — if repeated latches at different times always read
     the same, the clock isn't toggling, regardless of what Vivado/DRC/bitgen say.
4. A clean `write_bitstream` and successful `program_hw_devices` only prove the
   bitstream loaded — they prove nothing about whether the physical net you
   constrained actually carries the signal you think it does.

## Adding a new project

`make new PROJ=<name>` scaffolds `projects/<name>/rtl/<name>.v` and a stub
`.xdc`. Board-level pins (clock, LEDs, etc.) are pulled in automatically at
build time — only add pins here that are specific to this design.

## Current boards

- **zcu104** — Xilinx Zynq UltraScale+ MPSoC eval board (`xczu7ev-ffvc1156-2-e`).
  See `boards/zcu104/docs/pinout_notes.md` for the verified pin/net reference and
  `boards/zcu104/docs/errata.md` for manual mistakes and hardware gotchas already
  discovered on this board (boot mode switch, wrong CLK_125 pins in UG1267, LVDS
  termination).

## Current projects

- **hello_world** — blinks the 4 GPIO LEDs in a binary counter pattern off the
  board's 125 MHz clock.
