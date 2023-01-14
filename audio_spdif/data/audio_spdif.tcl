    proc audio_spdif_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,spdif-2.0\""
        
        set spdif_mode [hsi get_property CONFIG.SPDIF_Mode [hsi::get_cells -hier $drv_handle]]
        add_prop $node "xlnx,spdif-mode" $spdif_mode int $dts_file
        set cstatus_reg [hsi get_property CONFIG.CSTATUS_REG [hsi::get_cells -hier $drv_handle]]
        add_prop $node "xlnx,chstatus-reg" $cstatus_reg int $dts_file
        set userdata_reg [hsi get_property CONFIG.USERDATA_REG [hsi::get_cells -hier $drv_handle]]
        add_prop $node "xlnx,userdata-reg" $userdata_reg int $dts_file
        set axi_buffer_size [hsi get_property CONFIG.AXI_BUFFER_Size [hsi::get_cells -hier $drv_handle]]
        add_prop $node "xlnx,fifo-depth" $axi_buffer_size int $dts_file
        set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "aud_clk_i"]
        if {[llength $clk_freq] != 0} {
                add_prop $node "clock-frequency" $clk_freq int $dts_file
        }
    }


