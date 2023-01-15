    proc axi_iic_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        pldt append $node compatible "\ \, \"xlnx,xps-iic-2.00.a\""
        set proctype [get_hw_family]
        if {[regexp "kintex*" $proctype match]} {
        gen_dev_ccf_binding $drv_handle "s_axi_aclk"
        }
    }


