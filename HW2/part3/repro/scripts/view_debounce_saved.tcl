source [file join [file dirname [info script]] common.tcl]
open_wave_database -noautoloadwcfg $repo/waveforms/tb_button_conditioner_behav.wdb
create_wave_config debounce_verified
add_wave /tb_button_conditioner/clk /tb_button_conditioner/resetn /tb_button_conditioner/raw /tb_button_conditioner/dut/sync1 /tb_button_conditioner/dut/sync2 /tb_button_conditioner/dut/count /tb_button_conditioner/pressed /tb_button_conditioner/pressed_low
