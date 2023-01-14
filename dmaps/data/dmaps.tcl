    proc dmaps_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set ip [hsi::get_cells -hier $drv_handle]

        set ip_name [get_ip_property $drv_handle IP_NAME]
        set req_dma_list "psu_gdma psu_adma psu_csudma"
        if {[lsearch  -nocase $req_dma_list $ip_name] >= 0} {
        set_drv_conf_prop $drv_handle C_DMA_MODE xlnx,dma-type  $node int
        if {[string match -nocase $ip_name "psu_csudma"]} {
           add_prop $node "xlnx,dma-type" 0 int $dts_file
        }
        }
    }


