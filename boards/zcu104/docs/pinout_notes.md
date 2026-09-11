# ZCU104 Pin/Net Reference (from ug1267-zcu104-eval-bd.pdf)

## Clock net: CLK_125 (Table 3-13)
| Net | FPGA Pin | Standard |
|---|---|---|
| CLK_125_P | H11 | LVDS |
| CLK_125_N | G11 | LVDS |

Source: Si5341 clock generator, 125 MHz differential output.

## GPIO LED nets (Table 3-24, active high, driven through U163 buffer)
| Net | FPGA Pin | LED |
|---|---|---|
| GPIO_LED_0 | D5 | DS38 |
| GPIO_LED_1 | D6 | DS37 |
| GPIO_LED_2 | A5 | DS39 |
| GPIO_LED_3 | B5 | DS40 |

All LVCMOS33.

## Design
`rtl/hello_world.v` buffers CLK_125 through IBUFDS, runs a 27-bit free-running
counter, and drives the top 4 counter bits onto the 4 user LEDs — a visible
binary counter blink pattern, the FPGA "hello world."
