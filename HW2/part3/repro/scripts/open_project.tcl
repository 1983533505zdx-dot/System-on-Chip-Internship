source [file join [file dirname [info script]] common.tcl]
open_project $build/Vivado/hw2/hw2.xpr
open_bd_design [get_files system.bd]
