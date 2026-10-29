source [file join [file dirname [info script]] common.tcl]
open_wave_database $build/Vivado/irq_ip_sim/irq_ip_sim.sim/sim_1/behav/xsim/tb_axi_gpio_irq_behav.wdb
add_wave /tb_axi_gpio_irq/clk /tb_axi_gpio_irq/raw /tb_axi_gpio_irq/pressed /tb_axi_gpio_irq/irq /tb_axi_gpio_irq/awaddr /tb_axi_gpio_irq/wdata /tb_axi_gpio_irq/araddr /tb_axi_gpio_irq/rdata
