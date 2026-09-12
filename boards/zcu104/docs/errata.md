# ZCU104 Gotchas / Manual Errata

Things that cost real debugging time on this board — read before trusting UG1267 at
face value on anything clock-related.

## 1. Boot mode switch defaults to QSPI32, not JTAG

SW6 (a 4-pole DIP switch near the PS section) ships from the factory set to QSPI32
boot mode. Programming the PL over JTAG requires it set to JTAG mode instead (all 4
poles ON — see `pinout_notes.md`). With the wrong boot mode and no valid QSPI image,
the PS lands in an error/reset lockdown state (status LEDs **DS35 `PS_ERR_OUT`** and
**DS1 `PS_INIT_B`** light red) and PL configuration silently doesn't take effect, even
though Vivado's `program_hw_devices` reports success.

**Fix:** power off, set SW6 to ON/ON/ON/ON, power back on (or press the POR button
SW4), confirm DS35 goes off and DS1 goes green.

## 2. UG1267 Table 3-13 lists the wrong pins for CLK_125

The user guide (rev 1.1, Oct 2018), page 44, Table 3-13, states:

| Net | Pin |
|---|---|
| CLK_125_P | H11 |
| CLK_125_N | G11 |

This is **wrong**. The actual schematic and XDC route `CLK_125_P/N` to **F23/E23**;
H11/G11 are not connected to this net at all. This is a confirmed, known discrepancy
between the user guide text and the schematic (see the AMD/Xilinx support forum
thread "ZCU104 CLK_125 Net/Pin Mapping User Guide/Schematic Discrepancy").

We only caught this after fully verifying everything else was correct — pin location
(cross-checked against a rendered image of the actual PDF page, so it wasn't a text-
extraction artifact), IOSTANDARD, DRC, DIFF_TERM, bank power, bitstream load (DONE=1,
no CRC/JTAG errors), and a from-scratch proof that the LED pins and sequential logic
both worked correctly (constant-1 test, then a pushbutton-clocked counter test). A
free-running counter clocked from H11/G11 stayed frozen at zero indefinitely — the
tell that the clock signal itself was never reaching the FPGA, not a logic or
constraint bug.

**Lesson:** when a supposedly-correct pin assignment produces "the design loaded fine
but does nothing," and every FPGA-side check passes, suspect the board documentation
itself before spending more time re-verifying the design. A quick web search for the
board name + net name often surfaces existing errata or community-corrected XDC files
faster than re-deriving everything from the manual.

## 3. LVDS clock inputs may need explicit on-chip termination

`CLK_125` (and likely other board-level LVDS inputs routed through non-dedicated
FMC/GT-adjacent banks) has no external termination resistor near the FPGA. The
`IBUFDS` primitive needs `DIFF_TERM("TRUE")` set explicitly — Vivado will report
`DIFF_TERM is not supported in UltraScale devices. Automatically translating
DIFF_TERM of TRUE to DIFF_TERM_ADV=TERM_100` (a benign warning, not an error). Without
it, signal integrity on a long/un-terminated LVDS trace can be poor enough that the
input never registers valid transitions.

## 4. ILA/VIO debug cores require a license above BASIC

`create_debug_core` fails with a licensing error on the BASIC Vivado license
installed here. When you need to prove a signal is actually toggling in hardware and
can't use an ILA, a cheap substitute: latch the suspect free-running signal into a
register on an edge you fully control (e.g. a pushbutton press) and display it on the
LEDs. If repeated presses at different real-world times always show the same value,
the signal isn't toggling — no debug core required.
