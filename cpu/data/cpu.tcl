    proc cpu_generate {drv_handle} {
        set proctype [get_hw_family]
        set bus_name [detect_bus_name $drv_handle]
        set nr [get_microblaze_nr $drv_handle]
        set ip_name [get_ip_property $drv_handle IP_NAME]
        set node [create_node -n "cpus_microblaze" -l "cpus_microblaze_${nr}" -u $nr -d "pl.dtsi" -p $bus_name]
        add_prop $node "compatible" "cpus,cluster" string "pl.dtsi"
        add_prop $node "#cpu-mask-cells" 1 int "pl.dtsi"

        set node [create_node -n "cpu" -l "$drv_handle" -u $nr -d "pl.dtsi" -p $node]
        set comp_prop [gen_compatible_string $drv_handle]
        add_prop $node compatible "$comp_prop xlnx,microblaze" stringlist "pl.dtsi"
        add_prop $node "xlnx,ip-name" $ip_name string "pl.dtsi"
        set model "$ip_name,[get_ip_version $drv_handle]"
        add_prop $node "model" $model string "pl.dtsi"
        set family [hsi get_property C_FAMILY $drv_handle]
        add_prop $node "xlnx,family" $family string "pl.dtsi"
        add_prop $node "reg" $nr hexint "pl.dtsi"
        add_prop $node "bus-handle" "amba_pl" reference "pl.dtsi"

        set clk ""
        set clkhandle [hsi::get_pins -of_objects $drv_handle "CLK"]

        if { [string compare -nocase $clkhandle ""] != 0 } {
                set clk [hsi get_property CLK_FREQ $clkhandle]
        }
        if { [llength $drv_handle]  } {
                add_prop $node "clock-frequency" $clk int "pl.dtsi"
                add_prop $node "timebase-frequency" $clk int "pl.dtsi"
        }

        set icache_size [get_ip_param_value $drv_handle "C_CACHE_BYTE_SIZE"]
        set isize  [cpu_check_64bit $icache_size]
        set icache_base [get_ip_param_value $drv_handle "C_ICACHE_BASEADDR"]
        set ibase  [cpu_check_64bit $icache_base]
        set icache_high [get_ip_param_value $drv_handle "C_ICACHE_HIGHADDR"]
        set ihigh_base  [cpu_check_64bit $icache_high]
        set dcache_size [get_ip_param_value $drv_handle "C_DCACHE_BYTE_SIZE"]
        set dsize  [cpu_check_64bit $dcache_size]
        set dcache_base [get_ip_param_value $drv_handle "C_DCACHE_BASEADDR"]
        set dbase  [cpu_check_64bit $dcache_base]
        set dcache_high [get_ip_param_value $drv_handle "C_DCACHE_HIGHADDR"]
        set dhigh_base  [cpu_check_64bit $dcache_high]
        set icache_line_size [expr 4*[get_ip_param_value $drv_handle "C_ICACHE_LINE_LEN"]]
        set dcache_line_size [expr 4*[get_ip_param_value $drv_handle "C_DCACHE_LINE_LEN"]]


        if { [llength $icache_size] != 0 } {
                add_prop $node "i-cache-baseaddr"  "$ibase" hexint "pl.dtsi"
                add_prop $node "i-cache-highaddr" $ihigh_base hexint "pl.dtsi"
                add_prop $node "i-cache-size" $isize int "pl.dtsi"
                add_prop $node "i-cache-line-size" $icache_line_size int "pl.dtsi"
        }
        if { [llength $dcache_size] != 0 } {
                add_prop $node "d-cache-baseaddr"  "$dbase" hexint "pl.dtsi"
                add_prop $node "d-cache-highaddr" $dhigh_base hexint "pl.dtsi"
                add_prop $node "d-cache-size" $dsize int "pl.dtsi"
                add_prop $node "d-cache-line-size" $dcache_line_size int "pl.dtsi"
        }

        gen_mb_interrupt_property $drv_handle
        gen_drv_prop_from_ip $drv_handle
        generate_mb_ccf_node $drv_handle
    }

    proc cpu_check_64bit {base} {
        if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                        set temp $base
                   set temp [string trimleft [string trimleft $temp 0] x]
                   set len [string length $temp]
                   set rem [expr {${len} - 8}]
                   set high_base "0x[string range $temp $rem $len]"
                   set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                   set low_base [format 0x%08x $low_base]
               if {$low_base == 0x0} {
                   set reg "$high_base"
                } else {
                        set reg "$low_base $high_base"
                }
           } else {
                set reg "$base"
        }
           return $reg
    }
