    proc ernic_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set ernic_ip [hsi::get_cells -hier $drv_handle]
        set ip_name [hsi get_property IP_NAME $ernic_ip]

        set ethip [ernic_get_connected_ip $drv_handle "rx_pkt_hndler_s_axis"]
        if {[llength $ethip]} {
                set_drv_property $drv_handle eth-handle "$ethip" $node reference
        }
    }

    proc ernic_get_connected_ip {drv_handle dma_pin} {
        global connected_ip
        set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $drv_handle] $dma_pin]
        set valid_eth_list "l_ethernet"
        if {[string_is_empty ${intf}]} {
                return 0
        }
        set connected_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $intf]
        if {[string_is_empty ${connected_ip}]} {
                dtg_warning "$drv_handle connected ip is NULL for the pin $intf"
                return 0
        }
        set iptype [hsi get_property IP_NAME [hsi::get_cells -hier $connected_ip]]
        if {[string match -nocase $iptype "axis_data_fifo"] } {
                set dma_pin "M_AXIS"
                ernic_get_connected_ip $connected_ip $dma_pin
        } elseif {[lsearch -nocase $valid_eth_list $iptype] >= 0 } {
                return $connected_ip
        } else {
                set dma_pin "S_AXIS"
                ernic_get_connected_ip $connected_ip $dma_pin
        }
    }


