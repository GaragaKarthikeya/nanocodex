# ZCU104 Pin/Net Reference

Primary source: `ug1267-zcu104-eval-bd.pdf` (UG1267 rev 1.1, Oct 2018), cross-checked
against the AMD/Xilinx support forum and community-maintained constraint files where
the manual is known to be wrong — see `errata.md` for the one place that mattered.

## Clock net: CLK_125 — verified working pins

| Net | FPGA Pin | Standard | Notes |
|---|---|---|---|
| CLK_125_P | **F23** | LVDS | Bank 28, `IO_L13P_T2L_N0_GC_QBC_28` — global-clock-capable |
| CLK_125_N | **E23** | LVDS | Bank 28, `IO_L13N_T2L_N1_GC_QBC_28` |

125 MHz differential clock from the IDT8T49N287A clock generator (U182), always
free-running once the board has power — no PS/I2C bring-up required.

**Do not use H11/G11** — UG1267 Table 3-13 lists these for CLK_125, but they are not
connected to this net on actual hardware. See `errata.md`.

`IBUFDS` for this clock must set `DIFF_TERM("TRUE")` (Vivado auto-translates this to
`DIFF_TERM_ADV=TERM_100` on UltraScale parts) since there's no board-level termination
resistor near the FPGA on this route.

## GPIO LED nets (Table 3-24, active high, driven through U163 buffer) — verified working

| Net | FPGA Pin | LED | Standard |
|---|---|---|---|
| GPIO_LED_0 | D5 | DS38 | LVCMOS33 |
| GPIO_LED_1 | D6 | DS37 | LVCMOS33 |
| GPIO_LED_2 | A5 | DS39 | LVCMOS33 |
| GPIO_LED_3 | B5 | DS40 | LVCMOS33 |

Bank 88, VCC3V3. Confirmed by lighting all 4 solid with a constant-1 test bitstream.

## GPIO pushbuttons (Table 3-24) — GPIO_PB_SW1 verified working

| Net | FPGA Pin | Switch | Standard | Clock-buffer capable? |
|---|---|---|---|---|
| GPIO_PB_SW0 | B4 | SW14 | LVCMOS33 | No — N-side of a diff pair, DRC rejects it as a clock source |
| GPIO_PB_SW1 | C4 | SW15 | LVCMOS33 | Yes — P-side, used as a manual "clock" in debugging |
| GPIO_PB_SW2 | B3 | SW17 | LVCMOS33 | No — N-side |
| GPIO_PB_SW3 | C3 | SW18 | LVCMOS33 | Yes — P-side |

## Boot mode switch SW6 (Table 2-4)

Must be set to **JTAG mode** (all 4 poles ON) to program the PL over JTAG. The
factory-default switch position is QSPI32, not JTAG — if the board hasn't been
touched since it shipped, this needs to be changed once. See `errata.md`.

| Boot Mode | SW6 [4:1] |
|---|---|
| JTAG | ON, ON, ON, ON |
| QSPI32 (factory default) | ON, ON, OFF, ON |
| SD1 | OFF, OFF, OFF, ON |

## Design

`projects/hello_world/rtl/hello_world.v` buffers CLK_125 through `IBUFDS` (with
`DIFF_TERM("TRUE")`), runs a 27-bit free-running counter, and drives the top 4
counter bits onto the 4 user LEDs — a visible binary counter blink pattern.
