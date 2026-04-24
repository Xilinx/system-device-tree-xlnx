#
# (C) Copyright 2022-2026 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc xram_generate {drv_handle} {
	set proclist [get_proc_list_without_pmc]

	set xram_banks {}
	foreach procc $proclist {
		set mem_ranges [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $procc] -filter {MEM_TYPE == "MEMORY"}]
		foreach mem_range $mem_ranges {
			set ip_handle [hsi::get_cells -hier $mem_range]
			if {[string_is_empty $ip_handle]} { continue }
			set ip_name [get_ip_property $ip_handle IP_NAME]
			if {[string match "psv_xram_bank*" $ip_name] || [string match "xram*" $ip_name]} {
				if {[lsearch $xram_banks $mem_range] < 0} {
					lappend xram_banks $mem_range
				}
			}
		}
	}

	foreach bank $xram_banks {
		generate_memory_node_for_ip $bank
	}
}
