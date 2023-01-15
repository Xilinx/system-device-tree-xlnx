    proc axi_timebase_wdt_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,xps-timebase-wdt-1.00.a\""
        # get bus clock frequency
        set clk_freq [get_clock_frequency [hsi::get_cells -hier $drv_handle] "S_AXI_ACLK"]
        if {![string equal $clk_freq ""]} {
                add_prop $node "clock-frequency" $clk_freq int "pl.dtsi"
        }
        set_drv_conf_prop $drv_handle "C_WDT_ENABLE_ONCE" "xlnx,wdt-enable-once" $node
        set_drv_conf_prop $drv_handle "C_WDT_INTERVAL" "xlnx,wdt-interval" $node
        set_drv_conf_prop $drv_handle "C_ENABLE_WINDOW_WDT" "xlnx,enable-window-wdt" $node

    }


