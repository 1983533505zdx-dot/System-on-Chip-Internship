source [file join [file dirname [info script]] common.tcl]
setws $build/SDK
if {![file exists $build/SDK/hw2_hardware/system.hdf]} {
 createhw -name hw2_hardware -hwspec $build/Export/Board/hw2_board.hdf
 createbsp -name hw2_bsp -hwproject hw2_hardware -proc ps7_cortexa9_0 -os standalone
 createapp -name hw2_interrupt -hwproject hw2_hardware -proc ps7_cortexa9_0 -os standalone -lang C -app {Empty Application} -bsp hw2_bsp
} else {
 updatehw -hw hw2_hardware -newhwspec $build/Export/Board/hw2_board.hdf
}
file copy -force $repo/src/main.c $build/SDK/hw2_interrupt/src/main.c
file copy -force $repo/src/lscript.ld $build/SDK/hw2_interrupt/src/lscript.ld
projects -build
file copy -force $build/SDK/hw2_interrupt/Debug/hw2_interrupt.elf $build/Export/Board/hw2_interrupt.elf
puts "SDK_BOARD_BUILD_COMPLETE"
exit
