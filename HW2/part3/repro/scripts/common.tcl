set repo [file normalize [file join [file dirname [info script]] ..]]
if {![info exists env(HW2_BUILD_DIR)]} {set env(HW2_BUILD_DIR) D:/hw2_rebuild}
set build [file normalize $env(HW2_BUILD_DIR)]
file mkdir $build
file mkdir $build/Evidence
file mkdir $build/Export/Board
