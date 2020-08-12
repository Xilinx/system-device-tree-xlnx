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

namespace eval vproc_ss {
proc generate {drv_handle} {

#	set node [gen_peripheral_nodes $drv_handle]
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set dts_file [set_drv_def_dts $drv_handle]
	set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
	if {$topology == 0} {
	#scaler
		set name [get_property NAME [hsi::get_cells -hier $drv_handle]]
	#	set compatible [get_comp_str $drv_handle]
	#	set compatible [append compatible " " "xlnx,vpss-scaler-2.2 xlnx,v-vpss-scaler-2.2 xlnx,vpss-scaler"]
	#	set_drv_prop $drv_handle compatible "$compatible" stringlist
		pldt append $node compatible "\ \, \"xlnx,vpss-scaler-2.2\"\ \, \"xlnx,v-vpss-scaler-2.2\"\ \, \"xlnx,vpss-scaler\""
		set ip [hsi::get_cells -hier $drv_handle]
		set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
		set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set v_scaler_phases [get_property CONFIG.C_V_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int $dts_file
		set v_scaler_taps [get_property CONFIG.C_V_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int $dts_file
		add_prop "${node}" "xlnx,num-vert-taps" $v_scaler_taps int $dts_file
		set h_scaler_phases [get_property CONFIG.C_H_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,h-scaler-phases" $h_scaler_phases int $dts_file
		add_prop "${node}" "xlnx,max-num-phases" $h_scaler_phases int $dts_file
		set h_scaler_taps [get_property CONFIG.C_H_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,h-scaler-taps" $h_scaler_taps int $dts_file
		add_prop "${node}" "xlnx,num-hori-taps" $h_scaler_taps int $dts_file
		set max_cols [get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
		set max_rows [get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
		set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
		add_prop "${node}" "xlnx,pix-per-clk" $samples_per_clk int $dts_file
		set scaler_algo [get_property CONFIG.C_SCALER_ALGORITHM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,scaler-algorithm" $scaler_algo int $dts_file
		set enable_csc [get_property CONFIG.C_ENABLE_CSC [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,enable-csc" $enable_csc string $dts_file
		set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
		set use_uram [get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
		set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
	}
	if {$topology == 3} {
	#CSC
		set name [get_property NAME [hsi::get_cells -hier $drv_handle]]
#		set compatible [get_comp_str $drv_handle]
#		set compatible [append compatible " " "xlnx,vpss-csc xlnx,v-vpss-csc"]
		pldt append $node compatible "\ \, \"xlnx,vpss-csc\"\ \, \"xlnx,v-vpss-csc\""
#		set_drv_prop $drv_handle compatible "$compatible" stringlist
		set ip [hsi::get_cells -hier $drv_handle]
		set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
		set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
		set max_cols [get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
		set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
		set max_rows [get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
		set num_video_comp [get_property CONFIG.C_NUM_VIDEO_COMPONENTS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,num-video-components" $num_video_comp int $dts_file
		set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
		set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set use_uram [get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
	}
}
}
