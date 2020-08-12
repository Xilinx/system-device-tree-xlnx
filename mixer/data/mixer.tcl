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

namespace eval mixer {
proc generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
#	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
#	set compatible [get_comp_str $drv_handle]
#	set compatible [append compatible " " "xlnx,mixer-3.0 xlnx,mixer-4.0 xlnx,mixer-5.0"]
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	pldt append $node compatible "\ \, \"xlnx,mixer-3.0\"\ \, \"xlnx,mixer-4.0\"\ \, \"xlnx,mixer-5.0\""
	set mixer_ip [hsi::get_cells -hier $drv_handle]
	set num_layers [get_property CONFIG.NR_LAYERS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,num-layers" $num_layers int $dts_file
	set samples_per_clock [get_property CONFIG.SAMPLES_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,ppc" $samples_per_clock int $dts_file
	set dma_addr_width [get_property CONFIG.AXIMM_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,dma-addr-width" $dma_addr_width int $dts_file
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,bpc" $max_data_width int $dts_file
	set logo_layer [get_property CONFIG.LOGO_LAYER [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $logo_layer "true"]} {
		add_prop "$node" "xlnx,logo-layer" boolean $dts_file
	}
	set enable_csc_coefficient_registers [get_property CONFIG.ENABLE_CSC_COEFFICIENT_REGISTERS [hsi::get_cells -hier $drv_handle]]
	if {$enable_csc_coefficient_registers == 1} {
		add_prop "$node" "xlnx,enable-csc-coefficient-register" boolean $dts_file
	}
}
}
