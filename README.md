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

## Adding a new project

`make new PROJ=<name>` scaffolds `projects/<name>/rtl/<name>.v` and a stub
`.xdc`. Board-level pins (clock, LEDs, etc.) are pulled in automatically at
build time — only add pins here that are specific to this design.

## Current boards

- **zcu104** — Xilinx Zynq UltraScale+ MPSoC eval board (`xczu7ev-ffvc1156-2-e`).
  See `boards/zcu104/docs/pinout_notes.md` for the extracted pin/net reference.

## Current projects

- **hello_world** — blinks the 4 GPIO LEDs in a binary counter pattern off the
  board's 125 MHz clock.
