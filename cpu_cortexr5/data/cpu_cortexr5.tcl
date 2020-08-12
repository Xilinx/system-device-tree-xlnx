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

namespace eval cpu_cortexr5 {
proc generate {drv_handle} {
	set nr [string index $drv_handle end]
	set dts_file [set_drv_def_dts $drv_handle]
#	set node [create_node -n cpu -l "cpu${nr}" -u $nr -p "cpus_r5: cpus_r5" -d $dts_file]
#	set cpu_node [create_node -n ${dev_type} -l "cpu${cpu_nr}" -d ${default_dts} -p "cpus: cpus" -u $cpu_nr]
	global dtsi_fname
	global env
        set path $env(REPO)

        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        if {[file exists $common_file]} {
                #error "file not found: $common_file"
        }
        #set file "$path/${drvname}/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        #set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	#set proc_type [get_sw_proc_prop IP_NAME]
	if {0} {
	set proc_type "psv_cortexr5"
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
	}
        set ip [hsi::get_cells -hier $drv_handle]
        set default_dts [set_drv_def_dts $drv_handle]
 #       set root_node [add_or_get_dt_node -n / -d ${default_dts}]
#	if {[string match -nocase $proc_type "psv_cortexr5"]} {
#		psdt set root model "Versal R5"
#	        hsi::utils::add_new_dts_param "${root_node}" model "Versal R5" string ""
#	} else {
#		psdt set root model "ZynqMP R5"
#	        hsi::utils::add_new_dts_param "${root_node}" model "ZynqMP R5" string ""
#	}
        # create root node
        set master_root_node [gen_root_node $drv_handle]
        set nodes [gen_cpu_nodes $drv_handle]
}
}
