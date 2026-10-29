source [file join [file dirname [info script]] common.tcl]
if {[version -short] ne "2018.3"} {error "Vivado 2018.3 required"}
create_project debounce_sim $build/Vivado/debounce_sim -part xc7z020clg484-1 -force
add_files $repo/src/button_conditioner.v
add_files -fileset sim_1 $repo/src/tb_button_conditioner.v
set_property top tb_button_conditioner [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation
log_wave -r /
open_vcd $build/Evidence/debounce.vcd
log_vcd [get_objects [list /tb_button_conditioner/clk /tb_button_conditioner/resetn /tb_button_conditioner/raw /tb_button_conditioner/pressed /tb_button_conditioner/pressed_low /tb_button_conditioner/dut/sync1 /tb_button_conditioner/dut/sync2 /tb_button_conditioner/dut/count]]
run all
close_vcd
close_sim
file copy -force $build/Vivado/debounce_sim/debounce_sim.sim/sim_1/behav/xsim/simulate.log $build/Evidence/debounce_simulation.log
set f [open $build/Evidence/debounce_simulation.log r]
set result [read $f]; close $f
if {[string first "PASS: bounce rejected" $result] < 0 || [string first "Fatal:" $result] >= 0} {error "Debounce simulation failed"}
close_project
create_project irq_ip_sim $build/Vivado/irq_ip_sim -part xc7z020clg484-1 -force
set_property target_language Verilog [current_project]
# Identical input IP VLNV and parameters to the main block design.
create_ip -name axi_gpio -vendor xilinx.com -library ip -version 2.0 -module_name system_axi_gpio_button_0
set_property -dict [list CONFIG.C_GPIO_WIDTH {1} CONFIG.C_ALL_INPUTS {1} CONFIG.C_INTERRUPT_PRESENT {1}] [get_ips system_axi_gpio_button_0]
generate_target all [get_ips system_axi_gpio_button_0]
add_files $repo/src/button_conditioner.v
add_files -fileset sim_1 $repo/src/tb_axi_gpio_irq.v
set_property top tb_axi_gpio_irq [get_filesets sim_1]
set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
launch_simulation
log_wave -r /
open_vcd $build/Evidence/axi_gpio_irq.vcd
log_vcd [get_objects [list /tb_axi_gpio_irq/clk /tb_axi_gpio_irq/resetn /tb_axi_gpio_irq/raw /tb_axi_gpio_irq/pressed /tb_axi_gpio_irq/irq /tb_axi_gpio_irq/awvalid /tb_axi_gpio_irq/awaddr /tb_axi_gpio_irq/wdata /tb_axi_gpio_irq/araddr /tb_axi_gpio_irq/rdata]]
run all
close_vcd
close_sim
set f [open $build/Vivado/irq_ip_sim/irq_ip_sim.sim/sim_1/behav/xsim/simulate.log r]
set s [read $f]; close $f
file copy -force $build/Vivado/irq_ip_sim/irq_ip_sim.sim/sim_1/behav/xsim/simulate.log $build/Evidence/axi_gpio_irq_simulation.log
if {[string first "PASS: actual AXI GPIO" $s] < 0 || [string first "Fatal:" $s]>=0} {error "AXI GPIO IRQ test failed"}
puts "AXI_GPIO_SIMULATION_COMPLETE"
close_project

puts "ALL_SIMULATIONS_COMPLETE"
