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

namespace eval gamma_lut {
proc generate {drv_handle} {
#	set node [gen_peripheral_nodes $drv_handle]
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $dtv_handle]
	if {$node == 0} {
		return
	}
#	set compatible [get_comp_str $drv_handle]
#	set compatible [append compatible " " "xlnx,v-gamma-lut"]
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	pldt append $node compatible "\ \, \"xlnx,v-gamma-lut\""
	set gamma_ip [hsi::get_cells -hier $drv_handle]
	set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int $dts_file
#	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int
	set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int $dts_file
#	hsi::utils::add_new_dts_param "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	set max_rows [get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
#	hsi::utils::add_new_dts_param "$node" "xlnx,max-height" $max_rows int
	set max_cols [get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-width" $max_cols int $dts_file
#	hsi::utils::add_new_dts_param "$node" "xlnx,max-width" $max_cols int
}
}
