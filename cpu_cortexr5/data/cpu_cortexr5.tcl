#
# (C) Copyright 2014-2015 Xilinx, Inc.
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

global dtsi_fname
        foreach i [get_sw_cores device_tree] {
                set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
                if {[file exists $common_tcl_file]} {
                        source $common_tcl_file
                break
                }
        }
        set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set proc_type [get_sw_proc_prop IP_NAME]
        if {[string match -nocase "$mainline_ker" "v4.17"]} {
	        if {[string match -nocase $proc_type "psv_cortexr5"]} {
			set dtsi_fname "versal/versal.dtsi"
		} else {
	                set dtsi_fname "zynqmp/zynqmp.dtsi"
		}
        } else {
	        if {[string match -nocase $proc_type "psv_cortexr5"] } {
			set dtsi_fname "versal/versal.dtsi"
                } else {
			set dtsi_fname "zynqmp/zynqmp.dtsi"
		}
        }

        set ip [get_cells -hier $drv_handle]
        set default_dts [set_drv_def_dts $drv_handle]
        set root_node [add_or_get_dt_node -n / -d ${default_dts}]
	if {[string match -nocase $proc_type "psv_cortexr5"]} {
	        hsi::utils::add_new_dts_param "${root_node}" model "Versal R5" string ""
	} else {
	        hsi::utils::add_new_dts_param "${root_node}" model "ZynqMP R5" string ""
	}
        # create root node
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
}
