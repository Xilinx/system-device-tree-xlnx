    proc mipi_dsi_tx_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,dsi\""
        set dsi_num_lanes [hsi get_property CONFIG.DSI_LANES [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,dsi-num-lanes" $dsi_num_lanes int $dts_file
        set dsi_pixels_perbeat [hsi get_property CONFIG.DSI_PIXELS [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,dsi-pixels-perbeat" $dsi_pixels_perbeat int $dts_file
        set dsi_datatype [hsi get_property CONFIG.DSI_DATATYPE [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $dsi_datatype "RGB888"]} {
                add_prop "$node" "xlnx,dsi-data-type" 0 int $dts_file
        } elseif {[string match -nocase $dsi_datatype "RGB666_L"]} {
                add_prop "$node" "xlnx,dsi-data-type" 1 int $dts_file
        } elseif {[string match -nocase $dsi_datatype "RGB666_P"]} {
                add_prop "$node" "xlnx,dsi-data-type" 2 int $dts_file
        } elseif {[string match -nocase $dsi_datatype "RGB565"]} {
                add_prop "$node" "xlnx,dsi-data-type" 3 int $dts_file
        }
        set panel_node [create_node -n "simple_panel" -l simple_panel$drv_handle -u 0 -p $node -d $dts_file]
        add_prop "$panel_node" "reg" 0 int $dts_file
        add_prop "$panel_node" "compatible" "auo,b101uan01" string $dts_file
    }


