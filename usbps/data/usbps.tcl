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

namespace eval usbps {
proc generate {drv_handle} {
    ps7_reset_handle $drv_handle CONFIG.C_USB_RESET CONFIG.usb-reset
	set proctype [get_hw_family]
	set node [get_node $drv_handle]
    set default_dts [set_drv_def_dts $drv_handle]
    if {[string match -nocase $proctype "zynq"] } {
        set_drv_prop $drv_handle phy_type ulpi string
    } else {
	global env
        set path $env(REPO)

        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        if {[file exists $common_file]} {
                #error "file not found: $common_file"
        }
        #set file "$path/${drvname}/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]

#	set mainline_ker [get_property CONFIG.mainline_kernel [get_os]]
	if {[string match -nocase $proctype "versal"] || [string match -nocase $proctype "psv_cortexr5"] || [string match -nocase $proctype "psv_pmc"]} {
		#TODO:Remove this once the versal dts is fully updated.
		return
	}
	if {[string match -nocase $mainline_ker "none"]} {
             set index [string index $drv_handle end]
#             set rt_node [create_node -n usb -l psu_usb_$index -d $default_dts -p $]
	     add_prop $node "status" "okay" string $default_dts
#             hsi::utils::add_new_dts_param "${rt_node}" "status" "okay" string
        }
    }
}
}
