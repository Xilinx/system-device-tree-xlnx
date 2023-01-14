    proc axi_usb2_device_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,usb2-device-4.00.a\""
        set ip [hsi::get_cells -hier $drv_handle]
        set include_dma [hsi get_property CONFIG.C_INCLUDE_DMA $ip]
        if { $include_dma eq "1"} {
                set_drv_conf_prop $drv_handle C_INCLUDE_DMA xlnx,has-builtin-dma $node boolean
        }

    }


