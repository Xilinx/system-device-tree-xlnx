    proc generic_generate {drv_handle} {
        set hsi_version [get_hsi_version]
        set ver [split $hsi_version "."]
        set value [lindex $ver 0]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$value >= 2018} {
                set generic_node [get_node $drv_handle]
        }
    }


