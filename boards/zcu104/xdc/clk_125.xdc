# ZCU104 board-level clock net — fixed by hardware, reused across all projects
# Source: ug1267-zcu104-eval-bd.pdf, Table 3-13 (Clock Connections, Source to XCZU7EV MPSoC)
# Net: CLK_125 — Si5341 clock generator, 125 MHz differential output

set_property PACKAGE_PIN H11 [get_ports clk_125_p]
set_property PACKAGE_PIN G11 [get_ports clk_125_n]
set_property IOSTANDARD LVDS [get_ports clk_125_p]
set_property IOSTANDARD LVDS [get_ports clk_125_n]
create_clock -period 8.000 -name clk_125 [get_ports clk_125_p]
