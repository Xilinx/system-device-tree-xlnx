    proc vtc_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,v-tc-6.1\""
        set generate_en [hsi get_property CONFIG.C_GENERATE_EN [hsi::get_cells -hier $drv_handle]]
        if {$generate_en == 1} {
                add_prop "${node}" "xlnx,generator" boolean $dts_file
        }
        set detect_en [hsi get_property CONFIG.C_DETECT_EN [hsi::get_cells -hier $drv_handle]]
        if {$detect_en == 1} {
                add_prop "${node}" "xlnx,detector" boolean $dts_file
        }
    }


