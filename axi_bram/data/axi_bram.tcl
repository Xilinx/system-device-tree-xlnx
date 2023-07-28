    proc axi_bram_generate {drv_handle} {
        set r5 0
        set a53 0
        set pmu 0
        set psm 0
        set pmc 0
        set bram_ip ""
        set slave [hsi::get_cells -hier ${drv_handle}]
        set baseaddr [get_baseaddr $drv_handle noprefix]
        set memory_node [create_node -n "memory" -l "${drv_handle}_memory" -u $baseaddr -p root -d "system-top.dts"]
        set ip_mem_handles [hsi::get_mem_ranges $slave]
        set drv_ip [get_ip_property $drv_handle IP_NAME]
        set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
            foreach procc $proclist {

                set ip_mem_handles [hsi::get_mem_ranges $slave]
                set firstelement [lindex $ip_mem_handles 0]
                set index [lsearch [hsi::get_mem_ranges -of_objects $procc] [hsi::get_cells -hier $firstelement]]
                if {$index == "-1"} {
                        continue
                        }
                set have_ecc [hsi get_property CONFIG.C_ECC [hsi::get_cells -hier $drv_handle]]
                set ctrl_base [hsi get_property CONFIG.C_S_AXI_CTRL_BASEADDR [hsi::get_cells -hier $drv_handle]]
                if { $ctrl_base > 0 &&  $have_ecc == 1} {
                         set high [hsi get_property CONFIG.C_S_AXI_CTRL_HIGHADDR [hsi::get_cells -hier $drv_handle]]
                         set size [format 0x%x [expr {${high} - ${ctrl_base} + 1}]]
			 set_memmap "${drv_handle}" $procc "0x0 $ctrl_base 0x0 $size"
                }

                # TODO Fix this whole part, this is there in all memory IP tcls
                foreach bank ${ip_mem_handles} {
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_cortexr52"]} {
                                if {$r5 == 1} {
                                        continue
                                }
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_cortexr52"]} {
                                set r5 1
                        }

                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexa53"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_cortexa78"]} {
                                if {$a53 == 1} {
                                        continue
                                }
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexa53"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_cortexa78"]} {
                                set a53 1
                        }
                        if {$pmu == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psu_pmu"]} {
                                continue
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_pmu"]} {
                                set pmu 1
                        }
                        if {$pmc == 1 && ([string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_pmc"])} {
                                continue
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_pmc"]} {
                                set pmc 1
                        }
                        if {$psm == 1 && ([string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_psm"])} {
                                continue
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_psm"]} {
                                set psm 1
                        }

                        set index [lsearch -start $index [hsi::get_mem_ranges -of_objects $procc] [hsi::get_cells -hier $bank]]
                        set base [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
                        set high [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
                
                        if {1} {
                                if {[string match -nocase $drv_ip "lmb_bram_if_cntlr"] } {
                                        set base [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $drv_handle]]
                                        set high [hsi get_property CONFIG.C_HIGHADDR [hsi::get_cells -hier $drv_handle]]
                                        set addr [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $drv_handle]]
                                } else {
                                        set base [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $drv_handle]]
                                        set high [hsi get_property CONFIG.C_S_AXI_HIGHADDR [hsi::get_cells -hier $drv_handle]]
                                        set addr [hsi get_property CONFIG.C_S_AXI_BASEADDR [hsi::get_cells -hier $drv_handle]]
                                }
                        }
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]
                        set proctype [get_hw_family]
                        if {[is_zynqmp_platform $proctype] || \
                                [string match -nocase $proctype "versal"]} {
                                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                                        set temp $base
                                        set temp [string trimleft [string trimleft $temp 0] x]
                                        set len [string length $temp]
                                        set rem [expr {${len} - 8}]
                                        set high_base "0x[string range $temp $rem $len]"
                                        set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                                        set low_base [format 0x%08x $low_base]
                                        if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                                                set temp $size
                                                set temp [string trimleft [string trimleft $temp 0] x]
                                                set len [string length $temp]
                                                set rem [expr {${len} - 8}]
                                                set high_size "0x[string range $temp $rem $len]"
                                                set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
                                                set low_size [format 0x%08x $low_size]
                                                set reg "$low_base $high_base $low_size $high_size"
                                        } else {
                                                set reg "$low_base $high_base 0x0 $size"
                                        }
                                } else {
                                        set reg "0x0 $base 0x0 $size"
                                }
                        } else {
                                set reg "$base $size"
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_cortexr52"]} {
                                set_memmap "${drv_handle}_memory" $procc $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexa53"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_cortexa78"]} {
                                set_memmap "${drv_handle}_memory" a53 $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_pmu"]} {
                                set_memmap "${drv_handle}_memory" pmu $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_pmc"]} {
                                set_memmap "${drv_handle}_memory" pmc $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"] || [string match -nocase [hsi get_property IP_NAME $procc] "psx_psm"]} {
                                set_memmap "${drv_handle}_memory" psm $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "microblaze"]} {
                                set_memmap "${drv_handle}_memory" $procc "0x0 $base 0x0 $size"
                        }
                }
                add_prop "${memory_node}" "reg" $reg hexlist "system-top.dts" 1
                set dev_type memory
                add_prop "${memory_node}" "device_type" $dev_type string "system-top.dts" 1
        }
        if {0} {
        set ip_mem_handle [lindex [hsi::get_mem_ranges [hsi::get_cells -hier $slave]] 0]
        set addr [string tolower [hsi get_property BASE_VALUE $ip_mem_handle]]
        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handle]]
        set high [string tolower [hsi get_property HIGH_VALUE $ip_mem_handle]]
        set size [format 0x%x [expr {${high} - ${base} + 1}]]
        set proctype [get_hw_family]
        if {[is_zynqmp_platform $proctype] || \
                [string match -nocase $proctype "versal"]} {
                if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
                        set temp $base
                        set temp [string trimleft [string trimleft $temp 0] x]
                        set len [string length $temp]
                        set rem [expr {${len} - 8}]
                        set high_base "0x[string range $temp $rem $len]"
                        set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
                        set low_base [format 0x%08x $low_base]
                        if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
                                set temp $size
                                set temp [string trimleft [string trimleft $temp 0] x]
                                set len [string length $temp]
                                set rem [expr {${len} - 8}]
                                set high_size "0x[string range $temp $rem $len]"
                                set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
                                set low_size [format 0x%08x $low_size]
                                set reg "$low_base $high_base $low_size $high_size"
                        } else {
                                set reg "$low_base $high_base 0x0 $size"
                        }
                } else {
                        set reg "0x0 $base 0x0 $size"
                }
        } else {
                set reg "$base $size"
        }
    }

        set slave [hsi::get_cells -hier ${drv_handle}]
        set proctype [hsi get_property IP_TYPE $slave]
        set vlnv [split [hsi get_property VLNV $slave] ":"]
        set name [lindex $vlnv 2]
        set ver [lindex $vlnv 3]
        set comp_prop "xlnx,${name}-${ver}"
        regsub -all {_} $comp_prop {-} comp_prop

        add_prop ${memory_node} "compatible" $comp_prop string "system-top.dts"
    }


