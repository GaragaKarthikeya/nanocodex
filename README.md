# nanocodex

A personal FPGA research workstation. This isn't a one-off project — it's meant to
keep growing: more boards, more projects, eventually RowHammer / near-memory-compute
work. This doc walks through how it's organized and how to actually use it, in the
order you'd type things.

## The shape of the repo

```
boards/<board>/          everything specific to one physical board, shared by every project that targets it
projects/<project>/      one FPGA design (your Verilog + its pin constraints)
scripts/                 the automation that turns a project into a bitstream and gets it onto the board
```

The idea: a `project` is just Verilog + a couple of project-only pin constraints.
Everything about the *board* (which chip, which pin is which LED, which clock is
available) lives once in `boards/<board>/` and gets reused by every project — you
never re-type a pin number for a net you've already wired up in a previous project.

## Your first build (using the example project)

There's already one working project, `hello_world`, which blinks the board's 4 LEDs
in a binary counter pattern off its 125 MHz clock. Walking through it end to end:

**1. Build it.**

```
make build
```

This runs `scripts/build.tcl` in Vivado (headless, no GUI) using the defaults —
`PROJ=hello_world BOARD=zcu104`. It reads the Verilog in `projects/hello_world/rtl/`,
applies the pin constraints from `boards/zcu104/xdc/` and
`projects/hello_world/hello_world.xdc`, and runs synthesis → implementation →
bitstream generation. Output lands in `projects/hello_world/build/hello_world.bit`
(this folder is gitignored — it's a build artifact, not something to commit).

**2. Program the board.**

```
make program
```

This loads that `.bit` file onto the physically-connected board over JTAG (USB).
Needs `hw_server` running and the board connected to *this* machine specifically —
programming can't be done remotely, only building can (see below).

**3. Check it worked.** The 4 LEDs on the board should be visibly counting in
binary. If you build a different project or board, override the defaults:

```
make build PROJ=my_project BOARD=zcu104
make program PROJ=my_project BOARD=zcu104
```

## Starting your own project

```
make new PROJ=my_project
```

This scaffolds `projects/my_project/rtl/my_project.v` (a stub module wired to the
board's clock, ready to fill in) and `projects/my_project/my_project.xdc` (empty —
only add pins here that are *specific to this project*; board-level pins like the
clock and LEDs are already pulled in automatically by `build.tcl`). Then:

```
make build PROJ=my_project
make program PROJ=my_project
```

## Offloading a build to a bigger machine

Synthesis/implementation can be slow once designs get bigger than a blinky. If you
have another machine on the same Tailscale network with Vivado installed, you can
run the heavy compute there instead of on this laptop — the board still has to be
programmed from wherever it's physically plugged in, so that step always stays local:

```
make remote-build PROJ=hello_world BOARD=zcu104   # Vivado runs on the remote machine
make program PROJ=hello_world BOARD=zcu104        # still local -- this is where the board is
```

The remote build runs inside a `tmux` session on the far end and streams its log
back live. If your connection drops or you Ctrl-C, the build itself keeps running —
just re-run the same `make remote-build` command and it reattaches instead of
starting over. Defaults to a specific machine on our Tailscale network; override
with `REMOTE_HOST` / `REMOTE_USER` / `REMOTE_DIR` env vars if you're pointing it
somewhere else (see `scripts/remote_build.sh` for details).

## Adding a new board

1. `mkdir -p boards/<board>/{xdc,docs}`
2. Drop the board's user guide/datasheet PDF into `boards/<board>/docs/`
3. Write `boards/<board>/board.tcl` — at minimum, `set board_part_fpga <part-number>`
4. Add pin constraints under `boards/<board>/xdc/` — one `.xdc` file per group of
   related pins (clocks, LEDs, buttons, ...)

**Before typing a single pin number from a PDF: don't.** Board manuals get things
wrong more often than you'd expect — see `boards/zcu104/docs/errata.md` for a real
example that cost hours here (the manual listed the wrong pins for the board's
clock, and every other part of the design was correct). The reliable order of
trust:

1. **Official `board_part` files, if the vendor publishes them** (Xilinx does, at
   `github.com/Xilinx/XilinxBoardStore`, Apache-2.0). These are generated from the
   actual schematic, not prose that can go stale. `boards/zcu104/` has one vendored
   in and wired up — copy that pattern for a new board, and look nets up with:
   ```
   scripts/lookup_pin.sh <board> <net-name>
   ```
2. If a net isn't in the official files (common for general-purpose pins not tied
   to a named component), cross-check the manual against a *rendered image* of the
   actual PDF page — text extraction can misalign table columns — then web-search
   `"<board name>" "<net name>" xdc`. Community-corrected constraint files and
   vendor support-forum threads often already document the exact mistake.
3. Whatever the source, prove new pins against real hardware before trusting them:
   drive outputs to a constant value first (no clock involved), and for a clock,
   latch it into a register on an edge you fully control (like a pushbutton) and
   read it back — a signal that never changes no matter when you sample it isn't
   toggling, regardless of what a clean `write_bitstream` and successful
   `program_hw_devices` seem to say.
4. Write down whatever you find in `boards/<board>/docs/errata.md`, same format as
   the zcu104 one — so the next project on this board doesn't rediscover it.

## Current boards

- **zcu104** — Xilinx Zynq UltraScale+ MPSoC eval board (`xczu7ev-ffvc1156-2-e`).
  `boards/zcu104/docs/pinout_notes.md` has the verified pin reference;
  `boards/zcu104/docs/errata.md` has the hardware/manual gotchas already found on
  this board (worth reading before touching a new pin on it).

## Current projects

- **hello_world** — the walkthrough example above: blinks the 4 GPIO LEDs in a
  binary counter pattern off the board's 125 MHz clock.
