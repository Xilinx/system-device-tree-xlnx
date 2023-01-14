    proc RM_generate {drv_handle} {
        set val [hsi get_property FAMILY [hsi::get_hw_designs]]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts]
        switch -glob $val {
                "zynq" {
                        add_prop $node "fpga-mgr" "<&devcfg>" string $dts_file
                }
        }
    }

