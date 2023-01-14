    proc sdps_generate {drv_handle} {
        set ip [hsi::get_cells -hier $drv_handle]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set clk_freq [get_ip_param_value $ip C_SDIO_CLK_FREQ_HZ]
        add_prop $node "clock-frequency" $clk_freq hexint $dts_file
        set_drv_conf_prop $drv_handle C_MIO_BANK xlnx,mio-bank $node hexint
        set_drv_conf_prop $drv_handle C_HAS_CD xlnx,card-detect $node int
        set_drv_conf_prop $drv_handle C_HAS_WP xlnx,write-protect $node int
        set_drv_conf_prop $drv_handle C_SLOT_TYPE xlnx,slot-type $node int
    }


