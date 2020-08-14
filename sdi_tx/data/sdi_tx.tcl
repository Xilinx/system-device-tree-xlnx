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

namespace eval sdi_tx {
	proc generate {drv_handle} {

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		set dts_file [set_drv_def_dts $drv_handle]
		pldt append $node compatible "\ \, \"xlnx,sdi-tx\""
		set exdes_board [get_property CONFIG.C_EXDES_BOARD [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,exdes-board" $exdes_board string $dts_file
		set exdes_config [get_property CONFIG.C_EXDES_CONFIG [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,exdes-config" $exdes_config string $dts_file
		set adv_features [get_property CONFIG.C_INCLUDE_ADV_FEATURES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,include-adv-features" $adv_features string $dts_file
		set axilite [get_property CONFIG.C_INCLUDE_AXILITE [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,include-axilite" $axilite string $dts_file
		set edh [get_property CONFIG.C_INCLUDE_EDH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,include-edh" $edh string $dts_file
		set linerate [get_property CONFIG.C_LINE_RATE [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,line-rate" $linerate string $dts_file
		set pixelclock [get_property CONFIG.C_PIXELS_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,pixels-per-clock" $pixelclock string $dts_file
		set video_intf [get_property CONFIG.C_VIDEO_INTF [hsi::get_cells -hier $drv_handle]]
		add_prop "$node" "xlnx,video-intf" $video_intf string $dts_file
	}
}
