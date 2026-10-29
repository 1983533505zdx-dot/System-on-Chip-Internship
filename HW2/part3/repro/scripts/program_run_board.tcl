# Volatile JTAG programming only. Does not write QSPI or SD card.
source [file join [file dirname [info script]] common.tcl]
connect -url tcp:localhost:3121
puts "TARGETS_BEFORE=[targets]"
targets -set -filter {name =~ "APU"}
rst -system
after 1000
fpga -file $build/Export/Board/system_wrapper.bit
targets -set -filter {name =~ "ARM*#0"}
loadhw -hw $build/Export/Board/hw2_board.hdf -mem-ranges [list {0x41200000 0x4121ffff}]
rst -processor
source $build/SDK/hw2_hardware/ps7_init.tcl
ps7_init
ps7_post_config
dow $build/SDK/hw2_interrupt/Debug/hw2_interrupt.elf
con
after 1000
stop
set nm [file join $env(HW2_SDK_ROOT) gnu/aarch32/nt/gcc-arm-none-eabi/bin/arm-none-eabi-nm.exe]
set symbols [exec $nm -n $build/SDK/hw2_interrupt/Debug/hw2_interrupt.elf]
foreach sym {app_status led_state irq_count press_count last_button} {
    set pattern [format {(?m)^([0-9a-fA-F]+) [A-Za-z] %s\r?$} $sym]
    if {![regexp $pattern $symbols -> address]} {error "Missing symbol $sym"}
    puts "INITIAL $sym ADDRESS=0x$address VALUE=[mrd -value 0x$address]"
}
puts "LED_DATA=[mrd -value 0x41200000] BUTTON_DATA=[mrd -value 0x41210000]"
con
puts "BOARD_PROGRAM_RUN_COMPLETE"
disconnect
exit
