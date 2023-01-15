    proc pmups_generate {drv_handle} {
        set dts_file [set_drv_def_dts $drv_handle]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        if {[string match -nocase $ip_name "psu_pmu"]} {
                set node "&psu_pmu_0"
        } elseif {[string match -nocase $ip_name "psv_pmc"]} {
                set node "&psv_pmc_0"
        } else {
                set node "&psv_psm_0"
        }
        global env
        set path $env(REPO)

        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        global dtsi_fname
        set proc_type [get_ip_property $drv_handle IP_NAME]
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
        set ip [hsi::get_cells -hier $drv_handle]
        set clk ""
        set clkhandle [hsi::get_pins -of_objects $ip "CLK"]
        if { [string compare -nocase $clkhandle ""] != 0 } {
                set clk [hsi get_property CLK_FREQ $clkhandle]
        }
        if { [llength $ip]  } {
                if {$clk != ""} {
                add_prop $node "clock-freqeuency" $clk int $dts_file
                add_prop $node "timebase-frequency" $clk int $dts_file
                }
        }
        if {[string match -nocase $proc_type "psu_pmu"] } {
                add_prop $node "clock-frequency" [hsi get_property CONFIG.C_FREQ $ip] hexint $dts_file
        }
        set icache_size [get_ip_param_value $ip "C_CACHE_BYTE_SIZE"]
        set icache_base [get_ip_param_value $ip "C_ICACHE_BASEADDR"]
        set icache_high [get_ip_param_value $ip "C_ICACHE_HIGHADDR"]
        set dcache_size [get_ip_param_value $ip "C_DCACHE_BYTE_SIZE"]
        set dcache_base [get_ip_param_value $ip "C_DCACHE_BASEADDR"]
        set dcache_high [get_ip_param_value $ip "C_DCACHE_HIGHADDR"]
        set icache_line_size [expr 4*[get_ip_param_value $ip "C_ICACHE_LINE_LEN"]]
        set dcache_line_size [expr 4*[get_ip_param_value $ip "C_DCACHE_LINE_LEN"]]


        if { [llength $icache_size] != 0 } {
        add_prop $node "i-cache-baseaddr"  "$icache_base" hexint $dts_file
        add_prop $node "i-cache-highaddr" $icache_high hexint $dts_file
        add_prop $node "i-cache-size" $icache_size int $dts_file
        add_prop $node "i-cache-line-size" $icache_line_size int $dts_file
        }
        if { [llength $dcache_size] != 0 } {
        add_prop $node "d-cache-baseaddr"  "$dcache_base" hexint $dts_file
        add_prop $node "d-cache-highaddr" $dcache_high hexint $dts_file
        add_prop $node "d-cache-size" $dcache_size int $dts_file
        add_prop $node "d-cache-line-size" $dcache_line_size int $dts_file

        }
    }


