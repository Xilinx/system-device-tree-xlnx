#
# (C) Copyright 2021 Xilinx, Inc.
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
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set dts_file [set_drv_def_dts $drv_handle]
	set ip_ver     [get_comp_ver $drv_handle]
	if {[string match -nocase $ip_ver "2.0"]} {
		set keyval [pldt append $node compatible "\ \, \"xlnx,timer-syncer-1588-2.0\""]
	} else {
		set keyval [pldt append $node compatible "\ \, \"xlnx,timer-syncer-1588-1.0\""]
	}
	set_drv_prop $drv_handle compatible "$compatible" stringlist
}

proc get_comp_ver {drv_handle} {
       set slave [hsi get_cells -hier ${drv_handle}]
       set vlnv [split [hsi get_property VLNV $slave] ":"]
       set ver [lindex $vlnv 3]
       return $ver
}

