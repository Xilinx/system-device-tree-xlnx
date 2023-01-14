    proc sdfec_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set compatible [get_comp_str $drv_handle]
        set_drv_prop $drv_handle compatible "$compatible" $node stringlist
        set ldpc_decode [hsi get_property CONFIG.LDPC_Decode [hsi::get_cells -hier $drv_handle]]
        set ldpc_encode [hsi get_property CONFIG.LDPC_Encode [hsi::get_cells -hier $drv_handle]]
        set turbo_decode [hsi get_property CONFIG.Turbo_Decode [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $turbo_decode "true"]} {
                set sdfec_code "turbo"
        } else {
                set sdfec_code "ldpc"
        }
        set_drv_property $drv_handle xlnx,sdfec-code $sdfec_code $node string
        set sdfec_dout_words [hsi get_property CONFIG.C_S_DOUT_WORDS_MODE [hsi::get_cells -hier $drv_handle]]
        set sdfec_dout_width [hsi get_property CONFIG.DOUT_Lanes [hsi::get_cells -hier $drv_handle]]
        set sdfec_din_words [hsi get_property CONFIG.C_S_DIN_WORDS_MODE [hsi::get_cells -hier $drv_handle]]
        set sdfec_din_width [hsi get_property CONFIG.DIN_Lanes [hsi::get_cells -hier $drv_handle]]
        set_drv_property $drv_handle xlnx,sdfec-dout-words $sdfec_dout_words $node int
        set_drv_property $drv_handle xlnx,sdfec-dout-width $sdfec_dout_width $node int
        set_drv_property $drv_handle xlnx,sdfec-din-words  $sdfec_din_words $node int
        set_drv_property $drv_handle xlnx,sdfec-din-width  $sdfec_din_width $node int
    }


