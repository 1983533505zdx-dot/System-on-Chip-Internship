source [file join [file dirname [info script]] common.tcl]
open_project -read_only $build/Vivado/hw2/hw2.xpr
open_bd_design [get_files system.bd]
write_bd_layout -force -format pdf -orientation landscape $build/Evidence/block_design.pdf
write_bd_layout -force -format svg -orientation landscape $build/Evidence/block_design.svg
