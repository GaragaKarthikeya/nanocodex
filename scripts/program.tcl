# Program a bitstream onto the board over JTAG via hw_server.
# Usage: vivado -mode batch -source scripts/program.tcl -tclargs <path/to/top.bit>

if {$argc != 1} {
    puts "Usage: vivado -mode batch -source scripts/program.tcl -tclargs <path/to/top.bit>"
    exit 1
}

set bitfile [lindex $argv 0]

open_hw_manager
connect_hw_server
open_hw_target

set device [lindex [get_hw_devices] 0]
current_hw_device $device
set_property PROGRAM.FILE $bitfile $device
program_hw_devices $device

close_hw_target
disconnect_hw_server
