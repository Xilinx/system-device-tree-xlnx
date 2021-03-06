#
# (C) Copyright 2020-2021 Xilinx, Inc.
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
	set audio_channels [get_property CONFIG.AUDIO_CHANNELS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,audio-channels" $audio_channels int $dts_file
	set audio_enable [get_property CONFIG.AUDIO_ENABLE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dts_file
	set bits_per_color [get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dts_file
	set hdcp22_enable [get_property CONFIG.HDCP22_ENABLE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,hdcp22-enable" $hdcp22_enable int $dts_file
	set hdcp_enable [get_property CONFIG.HDCP_ENABLE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,hdcp-enable" $hdcp_enable int $dts_file
	set include_fec_ports [get_property CONFIG.INCLUDE_FEC_PORTS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dts_file
	set lane_count [get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,lane-count" $lane_count int $dts_file
	set link_rate [get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
	set link_rate [expr {${link_rate} * 1000}]
	set link_rate [expr int ($link_rate)]
	add_prop "${node}" "xlnx,linkrate" $link_rate int $dts_file
	set mode [get_property CONFIG.MODE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,mode" $mode int $dts_file
	set num_streams [get_property CONFIG.NUM_STREAMS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,num-streams" $num_streams int $dts_file
	set phy_data_width [get_property CONFIG.PHY_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,phy-data-width" $phy_data_width int $dts_file
	set pixel_mode [get_property CONFIG.PIXEL_MODE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,pixel-mode" $pixel_mode int $dts_file
	set sim_mode [get_property CONFIG.SIM_MODE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,sim-mode" $sim_mode string $dts_file
	set video_interface [get_property CONFIG.VIDEO_INTERFACE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,video-interface" $video_interface int $dts_file
}
