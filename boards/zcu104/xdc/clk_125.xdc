# ZCU104 board-level clock net — fixed by hardware, reused across all projects
# Source: Si5341/IDT8T49N287 clock generator, 125 MHz differential output.
#
# NOTE: UG1267 rev 1.1 Table 3-13 lists CLK_125_P/N as pins H11/G11 — this is
# a documented erratum in the manual. The actual schematic/XDC (confirmed via
# AMD/Xilinx support forum and independently-generated community constraint
# files) routes CLK_125_P/N to F23/E23; H11/G11 are not connected to this net.

set_property PACKAGE_PIN F23 [get_ports clk_125_p]
set_property PACKAGE_PIN E23 [get_ports clk_125_n]
set_property IOSTANDARD LVDS [get_ports clk_125_p]
set_property IOSTANDARD LVDS [get_ports clk_125_n]
create_clock -period 8.000 -name clk_125 [get_ports clk_125_p]
