    proc qspips_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set slave [hsi::get_cells -hier $drv_handle]
        set qspi_mode [get_ip_param_value $slave "C_QSPI_MODE"]
        set pspmc [hsi get_cells -hier -filter {IP_NAME =~ "*pspmc*"}]
        if {[string compare -nocase $pspmc ""] != 0} {
                set fbclk [hsi get_property CONFIG.PMC_QSPI_FBCLK [hsi get_cells -hier -filter {IP_NAME =~ "*pspmc*"}]]
                   if {[regexp "ENABLE 0" $fbclk matched]} {
                       set node [gen_peripheral_nodes $drv_handle]
                       if {$node == 0} {
                            return
                       }
                       add_prop "${node}" "/* hw design is missing feedback clock that's why spi-max-frequency is 40MHz */" "" comment $dts_file
                       add_prop $drv_handle spi-max-frequency 40000000 int $dts_file
                   }
           }
        set is_stacked 0
        if { $qspi_mode == 2} {
                set is_dual 1
        } elseif { $qspi_mode == 1} {
                   set is_dual 0
                   set is_stacked 1
            } elseif { $qspi_mode == 0} {
                set is_dual 0
        }
        add_prop $node "is-dual" $is_dual int $dts_file
        if {$is_stacked} {
                add_prop $node "is-stacked" $is_stacked int $dts_file
        }
        set bus_width [hsi get_property CONFIG.C_QSPI_BUS_WIDTH [hsi::get_cells -hier $drv_handle]]

        switch $bus_width {
                "3" {
                        add_prop $node "spi-tx-bus-width" 8 int $dts_file
                        add_prop $node "spi-rx-bus-width" 8 int $dts_file
                }
                "2" {
                        add_prop $node "spi-tx-bus-width" 4 int $dts_file
                        add_prop $node "spi-rx-bus-width" 4 int $dts_file
                }
                "1" {
                        add_prop $node "spi-tx-bus-width" 2 int $dts_file
                        add_prop $node "spi-rx-bus-width" 2 int $dts_file
                }
                "0" {
                        add_prop $node "spi-tx-bus-width" 1 int $dts_file
                        add_prop $node "spi-rx-bus-width" 1 int $dts_file
                }
                default {
                        dtg_warning "Unsupported bus_width:$bus_width"
                }
        }
        set_drv_conf_prop $drv_handle C_QSPI_BUS_WIDTH xlnx,bus-width $node int
        set_drv_conf_prop $drv_handle C_QSPI_MODE xlnx,connection-mode $node int
        set_drv_conf_prop $drv_handle C_QSPI_CLK_FREQ_HZ xlnx,clock-freq $node int
    }


