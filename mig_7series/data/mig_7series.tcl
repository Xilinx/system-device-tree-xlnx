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

proc generate {drv_handle} {
 	set r5 0
        set a53 0
        set pmu 0
        set pmc 0
        set psm 0

	set memory_node_node [create_node -n "memory" -l "${drv_handle}_memory" -u $baseaddr -p root -d "system-top.dts"]
	set ddr_ip ""
	set slave [hsi::get_cells -hier ${drv_handle}]

	set ddr_ip [hsi get_property IP_NAME [hsi::get_cells -hier $main_memory]]
	set drv_ip [hsi get_property IP_NAME [hsi::get_cells -hier $drv_handle]]
	set proclist [hsi::get_cells -hier -filter {IP_TYPE==PROCESSOR}]
        foreach procc $proclist {
		set ip_mem_handles [hsi::get_mem_ranges $slave]
		                        set firstelement [lindex $ip_mem_handles 0]
                set index [lsearch [hsi::get_mem_ranges -of_objects $procc] [hsi::get_cells -hier $firstelement]]
                if {$index == "-1"} {
                        continue
                }

                set main_memory "none"
                if {![string match -nocase $main_memory "none"]} {
                        set ocm_ip [hsi get_property IP_NAME [hsi::get_cells -hier $main_memory]]
                }

                foreach bank ${ip_mem_handles} {
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"]} {
                                if {$r5 == 1} {
                                         continue
                                }
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"]} {
                                set r5 1
                        }

                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexa53"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"]} {
                                if {$a53 == 1} {
                                        continue
                                }
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexa53"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"]} {
                                set a53 1
                        }
                        if {$pmu == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psu_pmu"]} {
                                continue
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_pmu"]} {
                                set pmu 1
                        }
                        if {$pmc == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"]} {
                                continue
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"]} {
                                set pmc 1
                        }
                        if {$psm == 1 && [string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"]} {
                                continue
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"]} {
                                set psm 1
                        }

                        set index [lsearch -start $index [hsi::get_mem_ranges -of_objects $procc] [hsi::get_cells -hier $bank]]
                       set base [hsi get_property BASE_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]
                        set high [hsi get_property HIGH_VALUE [lindex [hsi::get_mem_ranges -of_objects $procc] $index]]

                        set dts_file "system-top.dts"
                        set proctype [get_hw_family]
                        set size [format 0x%x [expr {${high} - ${base} + 1}]]

			if {[string match -nocase $proctype "zynqmp"] || [string match -nocase $proctype "versal"] || [string match -nocase $proctype "zynquplus"]} {
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
		       if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexr5"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexr5"]} {
                                set_memmap "${drv_handle}_memory" r5 $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_cortexa53"] || [string match -nocase [hsi get_property IP_NAME $procc] "psv_cortexa72"]} {
                                set_memmap "${drv_handle}_memory" a53 $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psu_pmu"]} {
                                set_memmap "${drv_handle}_memory" pmu $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_pmc"]} {
                                set_memmap "${drv_handle}_memory" pmc $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "psv_psm"]} {
                                set_memmap "${drv_handle}_memory" psm $reg
                        }
                        if {[string match -nocase [hsi get_property IP_NAME $procc] "microblaze"]} {
                                set_memmap "${drv_handle}_memory" $procc $reg
                        }
                }
		add_prop "${memory_node}" "reg" $reg hexlist "system-top.dts" 1
		set dev_type memory
		add_prop "${memory_node}" "device_type" $dev_type string "system-top.dts" 1

	}
	set addr [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $drv_handle]]
	regsub -all {^0x} $addr {} addr
	add_prop "${memory_node}" "reg" $reg hexlist "system-top.dts"
	set dev_type memory
	if {[string_is_empty $dev_type]} {set dev_type memory}
	add_prop "${memory_node}" "device_type" $dev_type string "system-top.dts"

	gen_compatible_property $drv_handle
	set prop [hsi get_property CONFIG.compatible $drv_handle]
	add_prop "${memory_node}" "compatible" $prop string "system-top.dts"
}
