    proc dpu_eu_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"deephi,dpu\""
    }


