source [file join [file dirname [info script]] common.tcl]
open_wave_database -noautoloadwcfg $repo/waveforms/tb_axi_gpio_irq_behav.wdb
create_wave_config axi_gpio_irq_verified
add_wave /tb_axi_gpio_irq/raw /tb_axi_gpio_irq/pressed /tb_axi_gpio_irq/irq /tb_axi_gpio_irq/awvalid /tb_axi_gpio_irq/awaddr /tb_axi_gpio_irq/wdata /tb_axi_gpio_irq/araddr /tb_axi_gpio_irq/rdata
