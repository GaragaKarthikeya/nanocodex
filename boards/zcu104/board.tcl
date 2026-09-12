# Board identity for the ZCU104 evaluation board (UG1267)
set board_part_fpga xczu7ev-ffvc1156-2-e

# Official Xilinx board_part definition (Apache-2.0, vendored from
# github.com/Xilinx/XilinxBoardStore) — the actual schematic-derived pin/
# interface data. Register it so `set_property board_part xilinx.com:zcu104:part0:1.1`
# is usable, and so scripts/lookup_pin.sh has a machine-readable ground truth
# to check net names against instead of transcribing UG1267 by hand.
set board_files_dir [file join [file dirname [info script]] vendor board_files]
set current_repo_paths [lsearch -all -inline -not -exact [get_param board.repoPaths] {}]
if {[lsearch -exact $current_repo_paths $board_files_dir] == -1} {
    set_param board.repoPaths [concat $current_repo_paths [list $board_files_dir]]
}
set board_part xilinx.com:zcu104:part0:1.1
