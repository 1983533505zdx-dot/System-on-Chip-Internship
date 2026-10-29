# EGO-XZ7 Hardware Manual V1.2, printed pp.26-27, Fig.22 and Table15.
# Source supplied by user: https://www.scribd.com/document/804631016/EGO-XZ7硬體手册V1-2
# LED0: series resistor -> LED -> ground, active high.
# BTNC: switch to 3V3, external pull-down, active high.
set_property PACKAGE_PIN T22 [get_ports {led_logical_on[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_logical_on[0]}]
set_property DRIVE 8 [get_ports {led_logical_on[0]}]
set_property SLEW SLOW [get_ports {led_logical_on[0]}]
set_property PACKAGE_PIN P16 [get_ports button_raw]
set_property IOSTANDARD LVCMOS33 [get_ports button_raw]
# Asynchronous mechanical button enters the marked two-FF synchronizer.
set_false_path -from [get_ports button_raw] -to [get_cells -hier -filter {NAME =~ *sync1_reg}]
