#
# (C) Copyright 2014-2021 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

# workaround for ps7 ddrc has none zero start address

proc gen_ps7_ddr_reg_property {drv_handle system_node} {
    proc_called_by
    set regprop [get_count "regp"]
    set psu_cortexa53 ""
    set slave [hsi::get_cells -hier ${drv_handle}]
    set ip_mem_handles [hsi::get_mem_ranges $slave]
     set proctype [get_hw_family]
    if {[string match -nocase $proctype "zynq"]} {
	set value 0
    } elseif {[string match -nocase $proctype "psu_pmu"]} {
	set value [generate_secure_memory_pmu $drv_handle]
    } elseif {[string match -nocase $proctype "psu_cortexr5"]} {
	set value [generate_secure_memory_r5 $drv_handle]
    } else {
	set value [generate_secure_memory $drv_handle]
    }
    if { $value !=0} {
	add_prop $system_node reg $value hexlist "system-top.dts"
    } else {
	foreach mem_handle ${ip_mem_handles} {
	    set base 0x0
	    set high [get_property HIGH_VALUE $mem_handle]
	    set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
	    if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "zynquplus"]} {
		# Check if memory crossing 4GB map, then split 2GB below 32 bit limit
		# and remaining above 32 bit limit
		if { [expr {${mem_size} + ${base}}] >= [expr 0x100000000] } {
		    set low_mem_size [expr {0x80000000 - ${base}}]
		    set high_mem_size [expr {${mem_size} - ${low_mem_size}}]
		    set low_mem_size [format "0x%x" ${low_mem_size}]
		    set high_mem_size [get_high_mem_size $high_mem_size]
		    set regval "0x0 ${base} 0x0 $low_mem_size>, <0x8 0x00000000 $high_mem_size"
		} else {
		    set regval "0x0 ${base} 0x0 ${mem_size}"
		}
	} else {
	    set regval "$base $mem_size"
	}
	if {[string_is_empty $regprop]} {
		set regprop $regval
	} else {
	    # ensure no duplication
	    if {![regexp ".*${regprop}.*" "$regval" matched]} {
		set regprop "$regval"
	    }
	}
    }
    add_prop $system_node reg $value intlist "system-top.dts"
    }
}

proc generate_secure_memory {drv_handle} {
    set regprop ""
    set psu_cortexa53 ""
    set r5 0
    set a53 0
    set pmu 0
    set slave [hsi::get_cells -hier ${drv_handle}]
    set name [get_property NAME [hsi::get_cells -hier $drv_handle]]
    set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
    foreach procc $proclist {
    set ip_mem_handles [hsi::get_mem_ranges $slave]
    set firstelement [lindex $ip_mem_handles 0]
    set index [lsearch [hsi::get_mem_ranges -of_objects $procc] [hsi::get_cells -hier $firstelement]]
    if {$index == "-1"} {
	continue
    }
    set avail_param [list_property [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
    set addr_64 "0"
    set size_64 "0"
	foreach bank ${ip_mem_handles} {
	if {$r5 == 1 && [string match -nocase [get_property IP_NAME $procc] "psu_cortexr5"]} {
		continue
	}
	if {[string match -nocase [get_property IP_NAME $procc] "psu_cortexr5"]} {
		set r5 1
	}
	if {$a53 == 1 && [string match -nocase [get_property IP_NAME $procc] "psu_cortexa53"]} {
		continue
	}
	if {[string match -nocase [get_property IP_NAME $procc] "psu_cortexa53"]} {
		set a53 1
	}
	if {$pmu == 1 && [string match -nocase [get_property IP_NAME $procc] "psu_pmu"]} {
		continue
	}
	if {[string match -nocase [get_property IP_NAME $procc] "psu_pmu"]} {
		set pmu 1
	}

	    set state [get_property TRUSTZONE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
		set index [lsearch -start $index [hsi::get_mem_ranges -of_objects $procc] [hsi::get_cells -hier $bank]]
		set base [get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
		set high [get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
		set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
		if {[string match -nocase $name "psu_r5_ddr_0"]} {
                        set mem_size $high
                }

		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		    set addr_64 "1"
		    set temp $base
		    set temp [string trimleft [string trimleft $temp 0] x]
		    set len [string length $temp]
		    set rem [expr {${len} - 8}]
		    set high_base "0x[string range $temp $rem $len]"
		    set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		    set low_base [format 0x%08x $low_base]
		}
		if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
		    set size_64 "1"
		    set temp $mem_size
		    set temp [string trimleft [string trimleft $temp 0] x]
		    set len [string length $temp]
		    set rem [expr {${len} - 8}]
		    set high_size "0x[string range $temp $rem $len]"
		    set low_size "0x[string range $temp 0 [expr {${rem} - 1}]]"
		    set low_size [format 0x%08x $low_size]
		}
		if {[string match $regprop ""]} {
		    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
			set regprop "$low_base $high_base $low_size $high_size"
		    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
			set regprop "${low_base} ${high_base} 0x0 ${mem_size}"
		    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
			set regprop "0x0 ${base} 0x0 ${mem_size}"
		    } else {
			set regprop "0x0 ${base} 0x0 ${mem_size}"
		    }
		} else {
		    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
			append regprop ">, " "<$low_base $high_base $low_size $high_size"
		    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
			append regprop ">, " "<${low_base} ${high_base} 0x0 ${mem_size}"
		    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
			append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
		    } else {
			append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
		    }
		}
		if {[string match -nocase [get_property IP_NAME $procc] "psu_cortexr5"]} {
			set_memmap "${drv_handle}_memory" r5 $regprop
		}
		if {[string match -nocase [get_property IP_NAME $procc] "psu_cortexa53"]} {
			set_memmap "${drv_handle}_memory" a53 $regprop
		}
		if {[string match -nocase [get_property IP_NAME $procc] "psu_pmu"]} {
			set_memmap "${drv_handle}_memory" pmu $regprop
		}
		if {[string match -nocase [get_property IP_NAME $procc] "microblaze"]} {
			set_memmap "${drv_handle}_memory" $procc $regprop
		}

	    }
	    set addr_64 "0"
	    set size_64 "0"
	    set index [expr $index + 1]
      }
	    return $regprop
}
proc generate_secure_memory_pmu {drv_handle} {
    set regprop [ get_os_parameter_value "regp"]
    set psu_cortexa53 ""
    set slave [get_cells -hier ${drv_handle}]
    set ip_mem_handles [get_ip_mem_ranges $slave]
    set firstelement [lindex $ip_mem_handles 0]
    set index [lsearch [get_mem_ranges -of_objects [get_cells -hier psu_pmu_0]] [get_cells $firstelement]]
    set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier psu_pmu_0]] $index]]
    set addr_64 "0"
    set size_64 "0"
    if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
	foreach bank ${ip_mem_handles} {
	    set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_pmu_0]] $index]]
	    if {[string match -nocase $state "NonSecure"]} {
		set index [lsearch -start $index [get_mem_ranges -of_objects [get_cells -hier psu_pmu_0]] [get_cells -hier $bank]]
		set base [get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_pmu_0]] $index]]
		set high [get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_pmu_0]] $index]]
		set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		    set addr_64 "1"
		    set temp $base
		    set temp [string trimleft [string trimleft $temp 0] x]
		    set len [string length $temp]
		    set rem [expr {${len} - 8}]
		    set high_base "0x[string range $temp $rem $len]"
		    set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		    set low_base [format 0x%08x $low_base]
		}
		if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
		    set size_64 "1"
		    set temp $mem_size
		    set temp [string trimleft [string trimleft $temp 0] x]
		    set len [string length $temp]
		    set rem [expr {${len} - 8}]
		    set high_size "0x[string range $temp $rem $len]"
		    set low_size "0x[string range $temp 0 [expr {${rem} - 1}]]"
		    set low_size [format 0x%08x $low_size]
		}
		if {[string match $regprop ""]} {
		    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
			set regprop "$low_base $high_base $low_size $high_size"
		    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
			set regprop "${low_base} ${high_base} 0x0 ${mem_size}"
		    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
			set regprop "0x0 ${base} 0x0 ${mem_size}"
		    } else {
			set regprop "0x0 ${base} 0x0 ${mem_size}"
		    }
		} else {
		    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
			append regprop ">, " "<$low_base $high_base $low_size $high_size"
		    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
			append regprop ">, " "<${low_base} ${high_base} 0x0 ${mem_size}"
		    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
			append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
		    } else {
			append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
		    }
		}
	    }
	    set addr_64 "0"
	    set size_64 "0"
	    set index [expr $index + 1]
	}
	return $regprop
    } else {
	return 0
    }
}

proc generate_secure_memory_r5 {drv_handle} {
    set regprop [ get_os_parameter_value "regp"]
    set psu_cortexa53 ""
    set slave [get_cells -hier ${drv_handle}]
    set ip_mem_handles [get_ip_mem_ranges $slave]
    set firstelement [lindex $ip_mem_handles 0]
    set index [lsearch [get_mem_ranges -of_objects [get_cells -hier psu_cortexr5_0]] [get_cells $firstelement]]
    set avail_param [list_property [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexr5_0]] $index]]
    set addr_64 "0"
    set size_64 "0"
    if {[lsearch -nocase $avail_param "TRUSTZONE"] >= 0} {
	foreach bank ${ip_mem_handles} {
	    set state [get_property TRUSTZONE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexr5_0]] $index]]
	    if {[string match -nocase $state "NonSecure"]} {
		set index [lsearch -start $index [get_mem_ranges -of_objects [get_cells -hier psu_cortexr5_0]] [get_cells -hier $bank]]
		set base [get_property BASE_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexr5_0]] $index]]
		set high [get_property HIGH_VALUE [lindex [get_mem_ranges -of_objects [get_cells -hier psu_cortexr5_0]] $index]]
		set mem_size [format 0x%x [expr {${high} - ${base} + 1}]]
		if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		    set addr_64 "1"
		    set temp $base
		    set temp [string trimleft [string trimleft $temp 0] x]
		    set len [string length $temp]
		    set rem [expr {${len} - 8}]
		    set high_base "0x[string range $temp $rem $len]"
		    set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		    set low_base [format 0x%08x $low_base]
		}
		if {[regexp -nocase {0x([0-9a-f]{9})} "$mem_size" match]} {
		    set size_64 "1"
		    set temp $mem_size
		    set temp [string trimleft [string trimleft $temp 0] x]
		    set len [string length $temp]
		    set rem [expr {${len} - 8}]
		    set high_size "0x[string range $temp $rem $len]"
		    set low_size "0x[string range $temp 0 [expr {${rem} - 1}]]"
		    set low_size [format 0x%08x $low_size]
		}
		if {[string match $regprop ""]} {
		    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
			set regprop "$low_base $high_base $low_size $high_size"
		    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
			set regprop "${low_base} ${high_base} 0x0 ${mem_size}"
		    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
			set regprop "0x0 ${base} 0x0 ${mem_size}"
		    } else {
			set regprop "0x0 ${base} 0x0 ${mem_size}"
		    }
		} else {
		    if {[string match $addr_64 "1"] && [string match $size_64 "1"]} {
			append regprop ">, " "<$low_base $high_base $low_size $high_size"
		    } elseif {[string match $addr_64 "1"] && [string match $size_64 "0"]} {
			append regprop ">, " "<${low_base} ${high_base} 0x0 ${mem_size}"
		    } elseif {[string match $addr_64 "0"] && [string match $size_64 "1"]} {
			append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
		    } else {
			append regprop ">, " "<0x0 ${base} 0x0 ${mem_size}"
		    }
		}
	    }
	    set addr_64 "0"
	    set size_64 "0"
	    set index [expr $index + 1]
	}
	return $regprop
    } else {
	return 0
    }
}

proc generate {drv_handle} {
	set baseaddr [get_baseaddr $drv_handle noprefix]
    set system_node [create_node -l "${drv_handle}_memory" -n "memory" -u $baseaddr -p root -d "system-top.dts"]
    gen_ps7_ddr_reg_property $drv_handle $system_node
	set dts_file "system-top.dts"
	add_prop $system_node "device_type" "memory" string $dts_file
	set slave [hsi::get_cells -hier ${drv_handle}] 
	set vlnv [split [get_property VLNV $slave] ":"] 
	set name [lindex $vlnv 2] 
	set ver [lindex $vlnv 3] 
	set comp_prop "xlnx,${name}-${ver}" 
	regsub -all {_} $comp_prop {-} comp_prop 
	add_prop $system_node "compatible" $comp_prop string $dts_file
}

proc get_high_mem_size {high_mem_size} {
	set size "0x0 0x0"
	set high_mem_size [format "0x%x" ${high_mem_size}]
	if {[regexp -nocase {0x([0-9a-f]{9})} "$high_mem_size" match]} {
		set temp $high_mem_size
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_mem "0x[string range $temp $rem $len]"
		set low_mem "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_mem [format 0x%08x $low_mem]
		set size "$low_mem $high_mem"
	} else {
		set size "0x0 $high_mem_size"
	}
	return $size
}
