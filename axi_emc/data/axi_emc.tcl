    proc axi_emc_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

        set ip [hsi::get_cells -hier $drv_handle]
        pldt append $node compatible "\ \, \"cfi-flash\""
        set count [get_ip_param_value $ip "C_NUM_BANKS_MEM"]
        if { [llength $count] == 0 } {
                set count 1
        }
        for {set x 0} { $x < $count} {incr x} {
                set datawidth [get_ip_param_value $ip [format "C_MEM%d_WIDTH" $x]]
                add_prop $node "bank-width" [expr ($datawidth/8)] int "pl.dtsi"
        }
    }

