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

namespace eval mipi_dsi_tx {
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		if {$node == 0} {
			return
		}
		pldt append $node compatible "\ \, \"xlnx,dsi\""
		set dsi_num_lanes [get_property CONFIG.DSI_LANES [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,dsi-num-lanes" $dsi_num_lanes int $dts_file
		set dsi_pixels_perbeat [get_property CONFIG.DSI_PIXELS [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,dsi-pixels-perbeat" $dsi_pixels_perbeat int $dts_file
		set dsi_datatype [get_property CONFIG.DSI_DATATYPE [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $dsi_datatype "RGB888"]} {
			add_prop "$node" "xlnx,dsi-data-type" 0 int $dts_file
		} elseif {[string match -nocase $dsi_datatype "RGB666_L"]} {
			add_prop "$node" "xlnx,dsi-data-type" 1 int $dts_file
		} elseif {[string match -nocase $dsi_datatype "RGB666_P"]} {
			add_prop "$node" "xlnx,dsi-data-type" 2 int $dts_file
		} elseif {[string match -nocase $dsi_datatype "RGB565"]} {
			add_prop "$node" "xlnx,dsi-data-type" 3 int $dts_file
		}
		set panel_node [create_node -n "simple_panel" -l simple_panel$drv_handle -u 0 -p $node -d $dts_file]
# 		hsi::utils::add_new_dts_param "${panel_node}" "/* User needs to add the panel node based on their requirement */" "" comment
		add_prop "$panel_node" "reg" 0 int $dts_file
		add_prop "$panel_node" "compatible" "auo,b101uan01" string $dts_file
	}
}
