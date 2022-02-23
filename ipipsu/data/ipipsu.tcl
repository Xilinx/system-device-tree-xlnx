#
# (C) Copyright 2019-2021 Xilinx, Inc.
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
	if {0} {
    foreach i [get_sw_cores device_tree] {
	set common_tcl_file "[hsi get_property "REPOSITORY" $i]/data/common_proc.tcl"
	if {[file exists $common_tcl_file]} {
	    source $common_tcl_file
	    break
	}
    }
    set proc_type [get_sw_proc_prop IP_NAME]
    if {[string match -nocase $proc_type "psv_pmc"]} {
	set cpumap [hsi get_property CONFIG.C_CPU_NAME [get_cells -hier $drv_handle]]
	if {![string match -nocase $cpumap "PMC"]} {
	    return
	}
    }
    if {[string match -nocase $proc_type "psv_cortexa72"] } {
	set cpumap [hsi get_property CONFIG.C_CPU_NAME [get_cells -hier $drv_handle]]
	if {![string match -nocase $cpumap "A72"]} {
	    return
	}
    } 
    if {[string match -nocase $proc_type "psv_cortexr5"] } {
	set cpumap [hsi get_property CONFIG.C_CPU_NAME [get_cells -hier $drv_handle]]
	if {![string match -nocase $cpumap "R5_0"] || ![string match -nocase $cpumap "R5_1"]} {
	    return
	}
    } else {
	set default_dts [hsi get_property CONFIG.pcw_dts [get_os]]
	set node [add_or_get_dt_node -n "&$drv_handle" -d $default_dts]
	add_new_dts_param "$node" "status" "okay" string
    }
}
}
