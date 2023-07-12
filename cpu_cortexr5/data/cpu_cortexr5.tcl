    proc cpu_cortexr5_generate {drv_handle} {
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set cpu_nr [string index [get_ip_property $drv_handle NAME] end]
        if {[string match -nocase $ip_name "psu_cortexr5"]} {
                set node [pcwdt insert root end "&psu_cortexr5_${cpu_nr}"]
        } elseif {[string match -nocase $ip_name "psv_cortexr5"]} {
                set node [pcwdt insert root end "&psv_cortexr5_${cpu_nr}"]
        } elseif {[string match -nocase $ip_name "psx_cortexr52"]} {
                set node [pcwdt insert root end "&psx_cortexr52_${cpu_nr}"]
        } else {
                error "Driver cpu_cortexr5 is not valid for given handle $drv_handle"
        }
        add_prop $node "cpu-frequency" [hsi get_property CONFIG.C_CPU_CLK_FREQ_HZ $drv_handle] int "pcw.dtsi"
        add_prop $node "xlnx,ip-name" $ip_name string "pcw.dtsi"
        gen_drv_prop_from_ip $drv_handle

        add_prop $node "bus-handle" "amba" reference "pcw.dtsi"
    }

