    proc axi_clk_wiz_generate {drv_handle} {
        global env
        global dtsi_fname
        set path $env(REPO)

        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set keyval [pldt append $node compatible "\ \, \"xlnx,clocking-wizard\""]
        set ip [hsi::get_cells -hier $drv_handle]
        axi_clk_wiz_gen_speedgrade $drv_handle
        set output_names ""
        for {set i 1} {$i < 8} {incr i} {
                if {[hsi get_property CONFIG.C_CLKOUT${i}_USED $ip] != 0} {
                        set freq [hsi get_property CONFIG.C_CLKOUT${i}_OUT_FREQ $ip]
                        set pin_name [hsi get_property CONFIG.C_CLK_OUT${i}_PORT $ip]
                        set basefrq [string tolower [hsi get_property CONFIG.C_BASEADDR $ip]]
                        set pin_name "$basefrq-$pin_name"
                        lappend output_names $pin_name
                }
        }
        if {![string_is_empty $output_names]} {
                add_prop $node "clock-output-names" $output_names string "pl.dtsi"
        }
        add_prop $node "#clock-cells" 1 int "pl.dtsi"

        set family [get_hw_family]
        if {[regexp "microblaze" $family match]} {
                gen_dev_ccf_binding $drv_handle "clk_in1 s_axi_aclk" "clocks clock-names"
        }
    }

    proc axi_clk_wiz_gen_speedgrade {drv_handle} {
        set speedgrade [hsi get_property SPEEDGRADE [hsi::get_hw_designs]]
        set num [regexp -all -inline -- {[0-9]} $speedgrade]
        if {![string equal $num ""]} {
                set node [get_node $drv_handle]
                add_prop $node "speed-grade" $num int "pl.dtsi"
        }
    }

    set connected_ip 0


