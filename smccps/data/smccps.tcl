    proc smccps_generate {drv_handle} {
        set handle [hsi::get_cells -hier -filter {IP_NAME==ps7_smcc}]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set reg [get_baseaddr [hsi::get_cells -hier $handle]]
        add_prop $node "flashbase" $reg int $dts_file
        set bus_width [hsi get_property CONFIG.C_NAND_WIDTH [hsi::get_cells -hier $handle]]
        add_prop $node "nand-bus-width" $bus_width int $dts_file
    }


