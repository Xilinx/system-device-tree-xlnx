#
# (C) Copyright 2019-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc ddrpsv_generate {drv_handle} {
	set ip_name [get_ip_property $drv_handle IP_NAME]
	set supported_ip_feature [list "ddr"]
	if {![string_is_empty [hsi get_mem_ranges -filter ADDRESS_BLOCK=~HBM*]]} {
		lappend supported_ip_feature "hbm"
	}

	foreach feature $supported_ip_feature {
		ddrpsv_node_info_map $drv_handle $feature
	}
}

proc ddrpsv_node_info_map {drv_handle feature} {
	set label "${drv_handle}_${feature}_memory"
	set hbm_ddr_filter ""
	if {$feature == "hbm"} {
		set hbm_ddr_filter "ADDRESS_BLOCK=~HBM*"
	} else {
		set hbm_ddr_filter "ADDRESS_BLOCK=~*DDR*"
	}
	set proclist [hsi::get_cells -hier -filter IP_TYPE==PROCESSOR]
	set a72 0
	foreach procc $proclist {
		set proc_name [get_ip_property $procc IP_NAME]
		# If the mappings have already been found for a72_0, then ignore the process for a72_1
		if {$a72 == 1 && ($proc_name in {"psv_cortexa72" "psx_cortexa78" "cortexa78"})} {
			continue
		}
		if {$proc_name in {"psv_cortexa72" "psx_cortexa78" "cortexa78"}} {
			set a72 1
		}
		# Get all the NOC memory block instances mapped to the particular processor
		set proc_noc_instances [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $procc] $drv_handle -filter $hbm_ddr_filter]
		# Generate merged non-overlapping address list for NOC instances mapped to a particular processor
		set addr_intervals [ddrpsv_process_addresses $proc_noc_instances]
		if {$proc_name in {"psv_cortexr5" "psx_cortexr52" "cortexr52"} && [llength $addr_intervals] > 0 } {
			set rpu_base_addr [lindex $addr_intervals 0 0]
			lset addr_intervals 0 0 [ddrpsv_check_r5_tcm_overlapping $rpu_base_addr]
		}
		# Generate reg_property for the merged address list of each processor
		set reg_val [ddrpsv_generate_reg_property $addr_intervals]
		switch $proc_name {
			"psv_cortexr5" - "psx_cortexr52" - "cortexr52" - "microblaze" - "microblaze_riscv" {
				set_memmap "${label}" $procc $reg_val
			}
			"psv_cortexa72" - "psx_cortexa78" - "cortexa78" {
				set_memmap "${label}" a53 $reg_val
			}
			"psv_psm" - "psx_psm" - "psm" {
				set_memmap "${label}" psm $reg_val
			}
			"asu" {
				set_memmap "${label}" asu $reg_val
			}
			default {
			}
		}
	}

	# Generate overall system level memory reg
	set overall_addr_intervals [ddrpsv_process_addresses [hsi get_mem_ranges $drv_handle -filter $hbm_ddr_filter]]
	set overall_reg [ddrpsv_generate_reg_property $overall_addr_intervals]

	if {[llength $overall_reg]} {
		set global_node_base_addr [lindex $overall_addr_intervals 0 0]
		set memory_node [create_node -n memory -l "${label}" -u [regsub -all {^0x} ${global_node_base_addr} {}] -p root -d "system-top.dts"]
		add_prop "${memory_node}" "compatible" [gen_compatible_string $drv_handle] string "system-top.dts"
		add_prop "${memory_node}" "device_type" "memory" string "system-top.dts"
		add_prop "${memory_node}" "xlnx,ip-name" [get_ip_property $drv_handle IP_NAME] string "system-top.dts"
		add_prop "${memory_node}" "memory_type" "memory" string "system-top.dts"
		add_prop "${memory_node}" "reg" $overall_reg  hexlist "system-top.dts"
	}
}

# Generate list of unique, merged address intervals
proc ddrpsv_process_addresses {instances} {
	set addresses {}
	for {set index 0} {$index < [llength $instances]} {incr index} {
		set base_address [hsi get_property BASE_VALUE [lindex ${instances} $index]]
                set high_address [hsi get_property HIGH_VALUE [lindex ${instances} $index]]
                set local_list [list $base_address $high_address]
                if {[lsearch -exact $addresses $local_list] == -1} {
                      lappend addresses $local_list
		}
	}
	set merged_intervals [ddrpsv_merge_intervals [lsort -index 0 -integer $addresses]]
	return $merged_intervals
}

# Merge overlapping address ranges
proc ddrpsv_merge_intervals {address} {
	if {[llength $address] == 0} {
		return {}
	}
	set union {}
	set current_start [lindex [lindex $address 0] 0]
	set current_end [lindex [lindex $address 0] 1]
	if {[llength $address] > 1} {
		foreach interval [lrange $address 1 end] {
			set start [lindex $interval 0]
			set end [lindex $interval 1]
			if {[expr $start] <= [expr {$current_end + 1}]} {
				set current_end [format "0x%lx" [expr {max($end, $current_end)}]]
			} else {
				lappend union [list $current_start $current_end]
				set current_start $start
				set current_end $end
			}
		}
	}
	lappend union [list $current_start $current_end]
	return $union
}

proc ddrpsv_generate_reg_property {addr_intervals} {
	set reg_val ""
	for {set i 0} {$i < [llength $addr_intervals]} {incr i} {
		set base_addr [lindex $addr_intervals $i 0]
		set high_addr [lindex $addr_intervals $i 1]
		set reg [ddrpsv_generate_reg_format $base_addr $high_addr]
		set reg_val [lappend reg_val $reg]
	}
	if {![string_is_empty $reg_val]} {
                set reg_val [join $reg_val ">, <"]
        }
	return $reg_val
}

proc ddrpsv_generate_reg_format {base high} {
	set size [format 0x%lx [expr {${high} - ${base} + 1}]]

	if {[regexp -nocase {0x([0-9a-f]{9})} "$base" match]} {
		set temp $base
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_base "0x[string range $temp $rem $len]"
		set low_base "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_base [format 0x%08x $low_base]
	} else {
		set high_base $base
		set low_base 0x0
	}

	if {[regexp -nocase {0x([0-9a-f]{9})} "$size" match]} {
		set temp $size
		set temp [string trimleft [string trimleft $temp 0] x]
		set len [string length $temp]
		set rem [expr {${len} - 8}]
		set high_size "0x[string range $temp $rem $len]"
		set low_size  "0x[string range $temp 0 [expr {${rem} - 1}]]"
		set low_size [format 0x%08x $low_size]
	} else {
		set high_size $size
		set low_size 0x0
	}

	set reg "$low_base $high_base $low_size $high_size"

	return $reg
}

# Vivado is allowing the DDR addresses accessible from RPU to start from 0.
# This leads to the DDR region's overlapping with the TCM region and results into linking error.
proc ddrpsv_check_r5_tcm_overlapping {r5_ddr_base_addr} {
	global is_versal_2ve_2vm_platform
	set tcm_ip [hsi::get_cells -hier -filter {NAME=~"*tcm_ram_global" || NAME=~"*tcm_alias"}]
	# For Versal_2VE_2VM, there are two TCM aliases coming, one generic and another mmi.
	# To avoid confusion, maintain a separate condition.
	if {[llength $tcm_ip] == 1} {
		set tcm_high_addr [get_highaddr $tcm_ip]
		set tcm_base_addr [get_baseaddr $tcm_ip]
		set tcm_size [format 0x%lx [expr {${tcm_high_addr} - ${tcm_base_addr} + 1}]]
		if {[scan $tcm_size %lx] > [scan $r5_ddr_base_addr %lx]} {
			set r5_ddr_base_addr $tcm_size
		}
	} elseif {$is_versal_2ve_2vm_platform && [expr {$r5_ddr_base_addr < "0x100000"}]} {
		set r5_ddr_base_addr "0x100000"
	}
	return $r5_ddr_base_addr
}
