#
# (C) Copyright 2017-2021 Xilinx, Inc.
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
	global env
	global dtsi_fname
	set path $env(REPO)

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set drvname [get_drivers $drv_handle]

	set common_file "$path/device_tree/data/config.yaml"
	set mainline_ker [get_user_config $common_file --mainline_kernel]
	if {[string match -nocase $mainline_ker "none"]} {
	  set ams_list "ams_ps ams_pl"
	set family [get_property FAMILY [hsi::current_hw_design]]
	set dts [set_drv_def_dts $drv_handle]
	if {[string match -nocase $family "versal"]} {
	} elseif {[string match -nocase $family "zynqmp"] || [string match -nocase $family "zynquplus"]} {
	}
	  foreach ams_name ${ams_list} {
		set node [create_node -n "&${ams_name}" -p root -d "pcw.dtsi"]
		add_prop $node "status" "okay" string "pcw.dtsi"
	  }
    }
}
