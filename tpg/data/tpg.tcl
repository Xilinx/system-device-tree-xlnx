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

namespace eval tpg {
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		if {$node == 0} {
			return
		}
		set tpg_count [get_count "tpg_count"]
		if { [llength $tpg_count] == 0 } {
			set tpg_count 0
		}
		pldt append $node compatible "\ \, \"xlnx,v-tpg-7.0\""	
		set ip [hsi::get_cells -hier $drv_handle]
		set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int $dts_file 1
		set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int $dts_file 1
		set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		set pixels_per_clock [get_property CONFIG.SAMPLES_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,ppc" $pixels_per_clock int $dts_file
		set max_cols [get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
		set max_rows [get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
		
		set ports_node [create_node -n "ports" -l tpg_ports$drv_handle -p $node -d $dts_file]
                puts "ports_node:$ports_node"
                add_prop "$ports_node" "#address-cells" 1 int $dts_file
                puts "ports1_node:$ports_node"
                add_prop "$ports_node" "#size-cells" 0 int $dts_file
                puts "ports2_node:$ports_node"
                set port1_node [create_node -n "port" -l tpg_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
                puts "port1_node:$port1_node"
                add_prop "$port1_node" "reg" 1 int $dts_file
                #add_prop "${port1_node}" "/* Fill the field xlnx,video-format based on user requirement */" "" comment
                add_prop "$port1_node" "xlnx,video-format" 12 int $dts_file
                add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file
	}
}
