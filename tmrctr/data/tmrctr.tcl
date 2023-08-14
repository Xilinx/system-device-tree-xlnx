    proc tmrctr_generate {drv_handle} {
         set node [get_node $drv_handle]
         set dts_file [set_drv_def_dts $drv_handle]
         pldt append $node compatible "\ \, \"xlnx,xps-timer-1.00.a\""
        set proctype [get_hw_family]
        if {[regexp "microblaze" $proctype match]} {
                 gen_dev_ccf_binding $drv_handle "s_axi_aclk"
        }
    }


