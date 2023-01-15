    proc ttcps_generate {drv_handle} {
        set node [get_node $drv_handle]
        set_drv_conf_prop $drv_handle C_TTC_CLK0_FREQ_HZ xlnx,clock-freq $node int
    }


