    proc uartns_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set ip [hsi::get_cells -hier $drv_handle]
        set has_xin [get_ip_param_value $ip C_HAS_EXTERNAL_XIN]
        set clock_port "S_AXI_ACLK"
        if { [string match -nocase "$has_xin" "1"] } {
        set_drv_conf_prop $drv_handle C_EXTERNAL_XIN_CLK_HZ clock-frequency $node
        # TODO: update the clock-names and clocks properties and create a
        # fixed clock node. Currently this is causing any issue as the
        # driver only uses clock-frequency property

        } else {
        set freq [get_clk_pin_freq $ip "$clock_port"]
        add_prop $node "clock-frequency" $freq int $dts_file
        }

        set proctype [get_hw_family]
        if {[regexp "kintex*" $proctype match]} {
                 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
        }
    }


