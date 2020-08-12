#
# (C) Copyright 2017 Xilinx, Inc.
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
namespace eval ams {
proc generate {drv_handle} {
	global env
	global dtsi_fname
	set path $env(REPO)

	#set node [gen_peripheral_nodes $drv_handle]
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
#    set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	set drvname [get_drivers $drv_handle]
        #puts "drvname $drvname"

        set common_file "$path/device_tree/data/config.yaml"
        if {[file exists $common_file]} {
                #error "file not found: $common_file"
        }
        #set file "$path/${drvname}/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
    if {[string match -nocase $mainline_ker "none"]} {
          set ams_list "ams_ps ams_pl"
         # set dts_file [get_property CONFIG.pcw_dts [get_os]]
	set family [get_property FAMILY [hsi::current_hw_design]]
	set dts [set_drv_def_dts $drv_handle]
	if {[string match -nocase $family "versal"]} {
#		set dts "versal.dtsi"
	} elseif {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
#		set dts "zynqmp.dtsi"
	}
          foreach ams_name ${ams_list} {
#              set ams_node [add_or_get_dt_node -n "&${ams_name}" -d $dts_file]
		add_prop $node "status" "okay" string $dts
#              hsi::utils::add_new_dts_param "${ams_node}" "status" "okay" string
          }
    }
}
}
