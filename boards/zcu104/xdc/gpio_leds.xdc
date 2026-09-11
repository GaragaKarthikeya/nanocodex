# ZCU104 GPIO user LEDs — fixed by hardware, reused across all projects
# Source: ug1267-zcu104-eval-bd.pdf, Table 3-24 (GPIO LEDs, active high, driven through U163 buffer)
# Nets: GPIO_LED_0..3 -> DS38, DS37, DS39, DS40

set_property PACKAGE_PIN D5 [get_ports {gpio_led[0]}]
set_property PACKAGE_PIN D6 [get_ports {gpio_led[1]}]
set_property PACKAGE_PIN A5 [get_ports {gpio_led[2]}]
set_property PACKAGE_PIN B5 [get_ports {gpio_led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_led[*]}]
