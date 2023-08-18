    proc pmups_generate {drv_handle} {
        set ip_name [get_ip_property $drv_handle IP_NAME]
        if {[string match -nocase $ip_name "psu_pmu"]} {
                set node [pcwdt insert root end "&psu_pmu_0"]
                add_prop $node "clock-frequency" [hsi get_property CONFIG.C_FREQ $drv_handle] hexint "pcw.dtsi"
                add_prop $node "microblaze_ddr_reserve_ea" [hsi get_property CONFIG.C_DDR_RESERVE_EA $drv_handle] int "pcw.dtsi"
                add_prop $node "microblaze_ddr_reserve_sa" [hsi get_property CONFIG.C_DDR_RESERVE_SA $drv_handle] int "pcw.dtsi"
                gen_pss_ref_clk_freq $drv_handle $node $ip_name
        } elseif {[string match -nocase $ip_name "psv_pmc"]} {
                set node [pcwdt insert root end "&psv_pmc_0"]
                gen_pss_ref_clk_freq $drv_handle $node $ip_name
        } elseif {[string match -nocase $ip_name "psv_psm"]} {
                set node [pcwdt insert root end "&psv_psm_0"]
        } elseif {[string match -nocase $ip_name "psx_pmc"]} {
                set node [pcwdt insert root end "&psx_pmc_0"]
                gen_pss_ref_clk_freq $drv_handle $node $ip_name
        } elseif {[string match -nocase $ip_name "psx_psm"]} {
                set node [pcwdt insert root end "&psx_psm_0"]
        } else {
                error "Driver pmups is not valid for given handle $drv_handle"
        }
        add_prop $node "bus-handle" "amba" reference "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle
        add_prop $node "xlnx,ip-name" $ip_name string "pcw.dtsi"

        set clk ""
        set clkhandle [hsi::get_pins -of_objects $drv_handle "CLK"]
        if { [string compare -nocase $clkhandle ""] != 0 } {
                set clk [hsi get_property CLK_FREQ $clkhandle]
        }
        if { [llength $drv_handle]  } {
                if {$clk != ""} {
                        add_prop $node "clock-freqeuency" $clk int $dts_file
                        add_prop $node "timebase-frequency" $clk int $dts_file
                }
        }
        set icache_size [get_ip_param_value $drv_handle "C_CACHE_BYTE_SIZE"]
        set icache_base [get_ip_param_value $drv_handle "C_ICACHE_BASEADDR"]
        set icache_high [get_ip_param_value $drv_handle "C_ICACHE_HIGHADDR"]
        set dcache_size [get_ip_param_value $drv_handle "C_DCACHE_BYTE_SIZE"]
        set dcache_base [get_ip_param_value $drv_handle "C_DCACHE_BASEADDR"]
        set dcache_high [get_ip_param_value $drv_handle "C_DCACHE_HIGHADDR"]
        set icache_line_size [expr 4*[get_ip_param_value $drv_handle "C_ICACHE_LINE_LEN"]]
        set dcache_line_size [expr 4*[get_ip_param_value $drv_handle "C_DCACHE_LINE_LEN"]]


        if { [llength $icache_size] != 0 } {
                add_prop $node "i-cache-baseaddr"  "$icache_base" hexint "pcw.dtsi"
                add_prop $node "i-cache-highaddr" $icache_high hexint "pcw.dtsi"
                add_prop $node "i-cache-size" $icache_size int "pcw.dtsi"
                add_prop $node "i-cache-line-size" $icache_line_size int "pcw.dtsi"
        }
        if { [llength $dcache_size] != 0 } {
                add_prop $node "d-cache-baseaddr"  "$dcache_base" hexint "pcw.dtsi"
                add_prop $node "d-cache-highaddr" $dcache_high hexint "pcw.dtsi"
                add_prop $node "d-cache-size" $dcache_size int "pcw.dtsi"
                add_prop $node "d-cache-line-size" $dcache_line_size int "pcw.dtsi"
        }
    }