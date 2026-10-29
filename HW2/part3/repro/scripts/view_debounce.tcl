source [file join [file dirname [info script]] common.tcl]
open_wave_database $build/Vivado/debounce_sim/debounce_sim.sim/sim_1/behav/xsim/tb_button_conditioner_behav.wdb
add_wave /tb_button_conditioner/clk /tb_button_conditioner/resetn /tb_button_conditioner/raw /tb_button_conditioner/dut/sync1 /tb_button_conditioner/dut/sync2 /tb_button_conditioner/dut/count /tb_button_conditioner/pressed /tb_button_conditioner/pressed_low
