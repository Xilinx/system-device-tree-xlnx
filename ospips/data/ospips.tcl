    proc ospips_generate {drv_handle} {
        set node [get_node $drv_handle]
        set_drv_conf_prop $drv_handle C_OSPI_CLK_FREQ_HZ xlnx,clock-freq $node int
        set ospi_handle [hsi::get_cells -hier $drv_handle]
        set ospi_mode [get_ip_param_value $ospi_handle "C_OSPI_MODE"]
        set is_stacked 0
        set is_dual 0
        if {$ospi_mode == 1} {
             set is_stacked 1
        }
        add_prop $node "is-dual" $is_dual int "pcw.dtsi"
        add_prop $node "is-stacked" $is_stacked int "pcw.dtsi"
    }


