source [file join [file dirname [info script]] common.tcl]
if {[version -short] ne "2018.3"} {error "Vivado 2018.3 required"}
create_project hw2 $build/Vivado/hw2 -part xc7z020clg484-1 -force
set_property target_language Verilog [current_project]
add_files $repo/src/button_conditioner.v
add_files -fileset sim_1 $repo/src/tb_button_conditioner.v
set_property top tb_button_conditioner [get_filesets sim_1]
create_bd_design system
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7]
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_USE_S_AXI_HP0 {0} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_IRQ_F2P_INTR {1} CONFIG.PCW_EN_CLK0_PORT {1} CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {50} CONFIG.PCW_UIPARAM_DDR_ENABLE {0} CONFIG.PCW_EN_DDR {0} CONFIG.PCW_CRYSTAL_PERIPHERAL_FREQMHZ {33.333333}] $ps
make_bd_intf_pins_external [get_bd_intf_pins ps7/FIXED_IO]
set led [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_led]
set_property -dict [list CONFIG.C_GPIO_WIDTH {1} CONFIG.C_ALL_OUTPUTS {1} CONFIG.C_DOUT_DEFAULT {0x00000001}] $led
set button [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_button]
set_property -dict [list CONFIG.C_GPIO_WIDTH {1} CONFIG.C_ALL_INPUTS {1} CONFIG.C_INTERRUPT_PRESENT {1}] $button
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto"} [get_bd_intf_pins axi_gpio_led/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/ps7/M_AXI_GP0" Clk "Auto"} [get_bd_intf_pins axi_gpio_button/S_AXI]
set cond [create_bd_cell -type module -reference button_conditioner button_conditioner_0]
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins button_conditioner_0/clk]
connect_bd_net [get_bd_pins rst_ps7_50M/peripheral_aresetn] [get_bd_pins button_conditioner_0/resetn]
connect_bd_net [get_bd_pins button_conditioner_0/pressed] [get_bd_pins axi_gpio_button/gpio_io_i]
set bp [create_bd_port -dir I button_raw]
connect_bd_net $bp [get_bd_pins button_conditioner_0/button_raw]
set lp [create_bd_port -dir O -from 0 -to 0 led_logical_on]
connect_bd_net $lp [get_bd_pins axi_gpio_led/gpio_io_o]
connect_bd_net [get_bd_pins axi_gpio_button/ip2intc_irpt] [get_bd_pins ps7/IRQ_F2P]
assign_bd_address
validate_bd_design
save_bd_design
add_files -fileset constrs_1 -norecurse $repo/src/ego_xz7_v12.xdc
generate_target all [get_files system.bd]
make_wrapper -files [get_files system.bd] -top
add_files $build/Vivado/hw2/hw2.srcs/sources_1/bd/system/hdl/system_wrapper.v
set_property top system_wrapper [get_filesets sources_1]
update_compile_order -fileset sources_1
write_bd_tcl -force $build/system_generated.tcl
file mkdir $build/Export
write_hwdef -force -file $build/Export/hw2_offline.hdf

puts "CREATE_DESIGN_COMPLETE"

