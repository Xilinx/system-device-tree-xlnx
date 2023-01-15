    proc emaclite_generate {drv_handle} {
        set node [get_node $drv_handle]
        add_prop $node compatible "\ \, \"xlnx,xps-ethernetlite-1.00.a\""
        update_eth_mac_addr $drv_handle
        gen_mdio_node $drv_handle $node
    }

