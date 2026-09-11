# Generic non-project-mode Vivado build script.
# Usage: vivado -mode batch -source scripts/build.tcl -tclargs <project_dir> <board_dir> <top_module>
#   <project_dir>  e.g. projects/hello_world   (must contain rtl/*.v and *.xdc)
#   <board_dir>    e.g. boards/zcu104          (must contain board.tcl and xdc/*.xdc)
#   <top_module>   e.g. hello_world

if {$argc != 3} {
    puts "Usage: vivado -mode batch -source scripts/build.tcl -tclargs <project_dir> <board_dir> <top_module>"
    exit 1
}

set proj_dir  [lindex $argv 0]
set board_dir [lindex $argv 1]
set top       [lindex $argv 2]

source [file join $board_dir board.tcl]

set build_dir [file join $proj_dir build]
file mkdir $build_dir

set_part $board_part_fpga

read_verilog [glob -nocomplain [file join $proj_dir rtl *.v]]
read_xdc [glob -nocomplain [file join $board_dir xdc *.xdc]]
read_xdc [glob -nocomplain [file join $proj_dir *.xdc]]

synth_design -top $top -part $board_part_fpga
opt_design
place_design
route_design

write_checkpoint -force [file join $build_dir "${top}_routed.dcp"]
report_timing_summary -file [file join $build_dir "timing_summary.rpt"]
report_utilization -file [file join $build_dir "utilization.rpt"]
write_bitstream -force [file join $build_dir "${top}.bit"]

puts "Build complete: [file join $build_dir "${top}.bit"]"
