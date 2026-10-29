source [file join [file dirname [info script]] create_design.tcl]
launch_runs synth_1 -jobs 2
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {error "Synthesis failed"}
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] ne "100%"} {error "Implementation/bitstream failed"}
open_run impl_1
report_drc -file $build/Evidence/board_drc.rpt
report_timing_summary -file $build/Evidence/board_timing.rpt
report_utilization -file $build/Evidence/board_utilization.rpt
if {[llength [get_drc_violations -quiet -filter {SEVERITY == Error || SEVERITY == "Critical Warning"}]] > 0} {error "DRC not clean"}
set setup [get_timing_paths -quiet -delay_type max -max_paths 1]
set hold [get_timing_paths -quiet -delay_type min -max_paths 1]
if {[llength $setup] && [get_property SLACK $setup]<0} {error "Setup timing failed"}
if {[llength $hold] && [get_property SLACK $hold]<0} {error "Hold timing failed"}
file mkdir $build/Export/Board
write_hwdef -force -file $build/Export/Board/hw2_board.hwdef
set bitfile $build/Vivado/hw2/hw2.runs/impl_1/system_wrapper.bit
file copy -force $bitfile $build/Export/Board/system_wrapper.bit
write_sysdef -force -hwdef $build/Export/Board/hw2_board.hwdef -bitfile $bitfile -file $build/Export/Board/hw2_board.hdf
puts "BOARD_BITSTREAM_BUILD_COMPLETE"
close_project
