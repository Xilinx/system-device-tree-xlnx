#
# (C) Copyright 2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc dfemix_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set count 0
	foreach handle [hsi::get_cells -hier] {
		set ip_name [hsi get_property IP_NAME $handle]
		if {[string match -nocase $ip_name "xdfe_cc_mixer"] } {
			set count [expr $count + 1]
		}
	}
	add_prop $node "num-insts" $count hexlist $dts_file

	set value [hsi get_property "CONFIG.C_MODE" $drv_handle]
	if {[string compare -nocase "downlink" $value] == 0} {
		set value 0
	} elseif {[string compare -nocase "uplink" $value] == 0} {
		set value 1
	} elseif {[string compare -nocase "switchable" $value] == 0} {
		set value 2
	}
	add_prop $node "xlnx,modeint" $value hexint $dts_file
}