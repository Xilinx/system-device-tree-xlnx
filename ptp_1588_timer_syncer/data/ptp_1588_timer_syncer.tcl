    proc ptp_1588_timer_syncer_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set ip_ver     [get_comp_ver $drv_handle]
        if {[string match -nocase $ip_ver "2.0"]} {
                set keyval [pldt append $node compatible "\ \, \"xlnx,timer-syncer-1588-2.0\""]
        } else {
                set keyval [pldt append $node compatible "\ \, \"xlnx,timer-syncer-1588-1.0\""]
        }
        set_drv_prop $drv_handle compatible "$compatible" $node stringlist
    }



