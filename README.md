# nanocodex

[![CI](https://github.com/GaragaKarthikeya/nanocodex/actions/workflows/ci.yml/badge.svg)](https://github.com/GaragaKarthikeya/nanocodex/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

> **Looking for the RISC-V core?** It lives in
> [nanoriscv](https://github.com/GaragaKarthikeya/nanoriscv) — an emulator that
> boots Linux and passes 236/236 of the official riscv-tests — and is tracked
> here as a submodule, with the pointer kept current automatically. This
> repository is the FPGA workstation it will run on. Clone with `--recursive`.

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
starting over.

Point it at your own build machine first — the scripts require this and will
tell you so if you forget:

```
export REMOTE_HOST=your-build-machine
export REMOTE_USER=your-username
```

`REMOTE_DIR` (default `nanocodex`) and `REMOTE_VIVADO_SETTINGS` are optional;
see `scripts/remote_build.sh` for details. The remote needs Vivado, `tmux` and
`rsync`, plus key-based ssh access — nothing here ever prompts for a password.

## Watching a build's progress

**Local build (`make build`):** Vivado's output prints directly to your terminal
as it runs — nothing extra needed, just watch it or scroll back through it after.

**Remote build (`make remote-build`):** the log streams live to your terminal the
same way, but since the build actually runs on the far machine independent of
whether you're watching, you've got two more options:

- **Reattach to the live stream:** just run `make remote-build` again with the
  same `PROJ`/`BOARD` — if a build is already running, it detects that and starts
  streaming the log from the top instead of launching a new build.
- **Quick peek without attaching:** `make remote-status PROJ=hello_world` — tells
  you whether it's still running and shows the last 15 lines, without committing
  to watching the whole thing. Good for "did it finish yet?" checks from another
  terminal, your phone over SSH, etc.

Either way, the underlying log is a plain file on the remote machine at
`<proj_dir>/build/build.log` — `ssh`-ing in and `tail -f`-ing it yourself works
too, if you want.

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

## Research roadmap: RowHammer / near-memory compute

The reason this board is here at all, beyond board bring-up practice.

**What's on the zcu104 relevant to this.** It's a Zynq UltraScale+ MPSoC — a real
FPGA fabric (the PL) plus hardened ARM cores (the PS) on one chip. Two DDR4
interfaces exist: a 2GB PS-side DDR4 soldered on the board (goes through the ARM
cores' fixed memory controller — not useful here, no low-level access), and a
PL-side DDR4 SODIMM socket (J1) wired straight into FPGA fabric banks 64/65/66 —
**this is the one that matters**, because it means a custom memory controller
written in our own RTL can get direct, cycle-precise control over row activation
and refresh timing, which is exactly what RowHammer work and near-memory compute
both require and what software running on a normal CPU/OS cannot give you.

**The DIMM.** The board ships with the PL-side socket empty. Needed: a 4GB DDR4-2666
260-pin SODIMM, single rank, x8 organization, unbuffered, non-ECC, 1.2V (a Crucial
`CT4G4SFS8266` or equivalent — Crucial is Micron's own consumer brand, matching the
board's originally-recommended Micron part). No DIMM in the socket means no PL-side
DRAM work is possible at all — this is the literal prerequisite, not an optimization.

**RowHammer vs. near-memory compute — same starting point, different destination.**
Both need the DIMM installed and a working custom PL-side memory controller (built
from Xilinx's MIG IP, then calibrated and verified with a memory test before
anything else). They diverge after that:
- *RowHammer* is about repeatedly activating one DRAM row until electrical
  interference flips bits in a neighboring row — the research problem is crafting
  an access *pattern* sophisticated enough to work despite modern DRAM's built-in
  defenses (Target Row Refresh).
- *Near-memory compute* is about placing actual computation (not just an attack
  pattern) in the data path near or inside memory, instead of shipping all data to
  a CPU first — an architecture problem, not an adversarial-timing one.

**What the literature actually says (so buying a DIMM isn't overthought).** The
major public RowHammer studies (TRRespass 2020, Blacksmith 2021, U-TRR 2021,
ZenHammer 2024) deliberately anonymize exact vendor/part numbers — there's no
"buy this exact SKU, guaranteed vulnerable" list. But their actual finding is
useful: across every DDR4 module they tested (all three major vendors, 2016-2020
manufacture dates), a sufficiently sophisticated access pattern broke *all* of
them — no DIMM in any of these studies was fully immune. So the DIMM choice isn't
the hard part; a naive/simple hammering pattern likely won't produce flips on a
modern module, and building a pattern good enough to beat TRR is the actual open
engineering problem — and the more interesting one, since it's squarely in RTL/
FPGA territory rather than a component-shopping problem.

**Where a genuine contribution is more likely to come from.** Not "discover a new
RowHammer pattern" — that's a crowded space with research groups running automated
fuzzers across racks of DIMMs for weeks, hard to beat with one board and one DIMM.
More realistic: something that leans on what this specific setup uniquely gives —
full custom control of the memory controller — like characterizing a mitigation's
behavior at a timing precision software-based hammering can't reach, or treating
the near-memory-compute RTL itself as the contribution rather than an attack.
Getting there needs real literature depth (dozens of papers, not a handful) before
a genuine gap is recognizable versus rediscovering something already published.

**What this is worth even without a novel result.** Real RTL/Vivado fluency, direct
DDR4/MIG experience (genuinely rare at the undergrad level), and hardware-debugging
discipline under real ambiguity (see `boards/zcu104/docs/errata.md` — that CLK_125
saga was this skill in action) are all concrete, demonstrable outcomes on their
own. Computer architecture research in practice spans both this RTL/hardware end
*and* a Python/simulator end (gem5, Ramulator, ChampSim, used for fast design-space
exploration once a mechanism is understood) — they're complementary, not
competing, and the real published RowHammer/DRAM work tends to use both at
different stages.

**Concrete next milestone:** install the DIMM, regenerate the Xilinx MIG IP core
for its exact spec, and get its built-in memory test passing — that's the proof
the PL-side memory path works at all, before any RowHammer- or compute-specific
RTL gets built on top of it.

## License

Apache-2.0 — see [LICENSE](LICENSE).

The vendored Xilinx board files under
`boards/zcu104/vendor/board_files/` are Xilinx's own, redistributed under the
same licence; their copyright notice is kept alongside them.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
