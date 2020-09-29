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

namespace eval ::tclapp::xilinx::devicetree::dp_rx {
namespace import ::tclapp::xilinx::devicetree::common::\*
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set dts_file [set_drv_def_dtds $drv_handle]
	set audio_channels [get_property CONFIG.AUDIO_CHANNELS [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,audio-channels" $audio_channels int $dtds_file
	set audio_enable [get_property CONFIG.AUDIO_ENABLE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dtds_file
	set bits_per_color [get_property CONFIG.BITS_PER_COLOR [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dtds_file
	set hdcp22_enable [get_property CONFIG.HDCP22_ENABLE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,hdcp22-enable" $hdcp22_enable int $dtds_file
	set hdcp_enable [get_property CONFIG.HDCP_ENABLE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,hdcp-enable" $hdcp_enable int $dtds_file
	set include_fec_ports [get_property CONFIG.INCLUDE_FEC_PORTS [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dtds_file
	set lane_count [get_property CONFIG.LANE_COUNT [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,lane-count" $lane_count int $dtds_file
	set link_rate [get_property CONFIG.LINK_RATE [get_cells -hier $drv_handle]]
	set link_rate [expr {${link_rate} * 1000}]
	set link_rate [expr int $dtds_file ($link_rate)]
	add_prop "${node}" "xlnx,linkrate" $link_rate int $dtds_file
	set mode [get_property CONFIG.MODE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,mode" $mode int $dtds_file
	set num_streams [get_property CONFIG.NUM_STREAMS [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,num-streams" $num_streams int $dtds_file
	set phy_data_width [get_property CONFIG.PHY_DATA_WIDTH [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,phy-data-width" $phy_data_width int $dtds_file
	set pixel_mode [get_property CONFIG.PIXEL_MODE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,pixel-mode" $pixel_mode int $dtds_file
	set sim_mode [get_property CONFIG.SIM_MODE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,sim-mode" $sim_mode string $dts_file
	set video_interface [get_property CONFIG.VIDEO_INTERFACE [get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,video-interface" $video_interface int $dtds_file
}
}
