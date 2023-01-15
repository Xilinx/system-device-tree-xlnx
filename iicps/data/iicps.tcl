    proc iicps_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        ps7_reset_handle $drv_handle CONFIG.C_I2C_RESET CONFIG.i2c-reset
        set_drv_conf_prop $drv_handle C_I2C_CLK_FREQ_HZ xlnx,clock-freq $node int

    }


