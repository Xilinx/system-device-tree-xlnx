#
# (C) Copyright 2018 Xilinx, Inc.
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

namespace eval i2s_transmitter {
proc generate {drv_handle} {
#	set node [gen_peripheral_nodes $drv_handle]
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
#	set compatible [get_comp_str $drv_handle]
#	set compatible [append compatible " " "xlnx,i2s-transmitter-1.0"]
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	pldt append $node compatible "\ \, \"xlnx,i2s-transmitter-1.0\""
	set dwidth [get_property CONFIG.C_DWIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,dwidth" $dwidth hexint $dts_file
	set num_channels [get_property CONFIG.C_NUM_CHANNELS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,num-channels" $num_channels hexint $dts_file
	set depth [get_property CONFIG.C_DEPTH [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,depth" $depth hexint $dts_file
	set ip [hsi::get_cells -hier $drv_handle]
	set freq ""
	set clk [get_pins -of_objects $ip "aud_mclk"]
	if {[llength $clk] } {
		set freq [get_property CLK_FREQ $clk]
		add_prop $node "aud_mclk" "$freq" int $dts_file
	}
}
}
