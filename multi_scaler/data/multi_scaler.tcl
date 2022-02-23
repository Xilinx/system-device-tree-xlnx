#
# (C) Copyright 2018-2021 Xilinx, Inc.
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
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	pldt append $node compatible "\ \, \"xlnx,v-multi-scaler-v1.0\""
	set ip [hsi::get_cells -hier $drv_handle]
	set max_outs [hsi get_property CONFIG.MAX_OUTS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-chan" $max_outs int $dts_file
	set max_cols [hsi get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-width" $max_cols int $dts_file
	set max_rows [hsi get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
	set taps [hsi get_property CONFIG.TAPS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,num-taps" $taps int $dts_file
	set aximm_addr_width [hsi get_property CONFIG.AXIMM_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,dma-addr-width" $aximm_addr_width hexint $dts_file
	set pixes_per_clock [hsi get_property CONFIG.SAMPLES_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
	set pixel $pixes_per_clock
	append pixel_per_clock "/bits/ 8 <$pixel>"
	add_prop "$node" "xlnx,pixels-per-clock" $pixel_per_clock string $dts_file
	set has_bgr8 [hsi get_property CONFIG.HAS_BGR8 [hsi::get_cells -hier $drv_handle]]
	set vid_formats ""
	if {$has_bgr8 == 1} {
		append vid_formats " " "rgb888"
	}
	set has_bgra8 [hsi get_property CONFIG.HAS_BGRA8 [hsi::get_cells -hier $drv_handle]]
	if {$has_bgra8 == 1} {
		append vid_formats " " "argb8888"
	}
	set has_bgrx8 [hsi get_property CONFIG.HAS_BGRX8 [hsi::get_cells -hier $drv_handle]]
	if {$has_bgrx8 == 1} {
		append vid_formats " " "xrgb8888"
	}
	set has_rgb8 [hsi get_property CONFIG.HAS_RGB8 [hsi::get_cells -hier $drv_handle]]
	if {$has_rgb8 == 1} {
		append vid_formats " " "bgr888"
	}
	set has_rgbx8 [hsi get_property CONFIG.HAS_RGBX8 [hsi::get_cells -hier $drv_handle]]
	if {$has_rgbx8 == 1} {
		append vid_formats " " "xbgr8888"
	}
	set has_rgba8 [hsi get_property CONFIG.HAS_RGBA8 [hsi::get_cells -hier $drv_handle]]
	if {$has_rgba8 == 1} {
		append vid_formats " " "abgr8888"
	}
	set has_rgbx10 [hsi get_property CONFIG.HAS_RGBX10 [hsi::get_cells -hier $drv_handle]]
	if {$has_rgbx10 == 1} {
		append vid_formats " " "xbgr2101010"
	}
	set has_uyuy8 [hsi get_property CONFIG.HAS_UYVY8 [hsi::get_cells -hier $drv_handle]]
	if {$has_uyuy8 == 1} {
		append vid_formats " " "uyvy"
	}
	set has_y8 [hsi get_property CONFIG.HAS_Y8 [hsi::get_cells -hier $drv_handle]]
	if {$has_y8 == 1} {
		append vid_formats " " "y8"
	}
	set has_y10 [hsi get_property CONFIG.HAS_Y10 [hsi::get_cells -hier $drv_handle]]
	if {$has_y10 == 1} {
		append vid_formats " " "y10"
	}
	set has_yuv8 [hsi get_property CONFIG.HAS_YUV8 [hsi::get_cells -hier $drv_handle]]
	if {$has_yuv8 == 1} {
		append vid_formats " " "vuy888"
	}
	set has_yuvx8 [hsi get_property CONFIG.HAS_YUVX8 [hsi::get_cells -hier $drv_handle]]
	if {$has_yuvx8 == 1} {
		append vid_formats " " "xvuy8888"
	}
	set has_yuva8 [hsi get_property CONFIG.HAS_YUVA8 [hsi::get_cells -hier $drv_handle]]
	if {$has_yuva8 == 1} {
		append vid_formats " " "avuy8888"
	}
	set has_yuvx10 [hsi get_property CONFIG.HAS_YUVX10 [hsi::get_cells -hier $drv_handle]]
	if {$has_yuvx10 == 1} {
		append vid_formats " " "yuvx2101010"
	}
	set has_yuyv8 [hsi get_property CONFIG.HAS_YUYV8 [hsi::get_cells -hier $drv_handle]]
	if {$has_yuyv8 == 1} {
		append vid_formats " " "yuyv"
	}
	set has_y_uv8_420 [hsi get_property CONFIG.HAS_Y_UV8_420 [hsi::get_cells -hier $drv_handle]]
	if {$has_y_uv8_420 == 1} {
		append vid_formats " " "nv12"
	}
	set has_y_uv8 [hsi get_property CONFIG.HAS_Y_UV8 [hsi::get_cells -hier $drv_handle]]
	if {$has_y_uv8 == 1} {
		append vid_formats " " "nv16"
	}
	set has_y_uv10 [hsi get_property CONFIG.HAS_Y_UV10 [hsi::get_cells -hier $drv_handle]]
	if {$has_y_uv10 == 1} {
		append vid_formats " " "xv20"
	}
	set has_y_uv10_420 [hsi get_property CONFIG.HAS_Y_UV10_420 [hsi::get_cells -hier $drv_handle]]
	if {$has_y_uv10_420 == 1} {
		append vid_formats " " "xv15"
	}
	add_prop "${node}" "xlnx,vid-formats" $vid_formats stringlist $dts_file
}
