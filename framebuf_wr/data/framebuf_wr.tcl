#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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
    proc framebuf_wr_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,axi-frmbuf-wr-v2.2\""
        set ip [hsi::get_cells -hier $drv_handle]
        set_drv_conf_prop $drv_handle C_S_AXI_CTRL_ADDR_WIDTH xlnx,s-axi-ctrl-addr-width $node
        set_drv_conf_prop $drv_handle C_S_AXI_CTRL_DATA_WIDTH xlnx,s-axi-ctrl-data-width $node
        set vid_formats ""
        set has_bgr8 [hsi get_property CONFIG.HAS_BGR8 [hsi::get_cells -hier $drv_handle]]
        if {$has_bgr8 == 1} {
                append vid_formats " " "rgb888"
        }
        set has_rgb8 [hsi get_property CONFIG.HAS_RGB8 [hsi::get_cells -hier $drv_handle]]
        if {$has_rgb8 == 1} {
                append vid_formats " " "bgr888"
        }
        set has_rgbx8 [hsi get_property CONFIG.HAS_RGBX8 [hsi::get_cells -hier $drv_handle]]
        if {$has_rgbx8 == 1} {
                append vid_formats " " "xbgr8888"
        }
        set has_bgrx8 [hsi get_property CONFIG.HAS_BGRX8 [hsi::get_cells -hier $drv_handle]]
        if {$has_bgrx8 == 1} {
                append vid_formats " " "xrgb8888"
        }
        set has_bgrx10 [hsi get_property CONFIG.HAS_RGBX10 [hsi::get_cells -hier $drv_handle]]
        if {$has_bgrx10 == 1} {
                append vid_formats " " "xbgr2101010"
        }
        set has_uyvy8 [hsi get_property CONFIG.HAS_UYVY8 [hsi::get_cells -hier $drv_handle]]
        if {$has_uyvy8 == 1} {
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
            set has_y_u_v8 [hsi get_property CONFIG.HAS_Y_U_V8 [hsi::get_cells -hier $drv_handle]]
            if {$has_y_u_v8 == 1} {
                    append vid_formats " " "y_u_v8"
            }
        if {![string match $vid_formats ""]} {
                add_prop "${node}" "xlnx,vid-formats" $vid_formats stringlist $dts_file
        }
        set samples_per_clk [hsi get_property CONFIG.SAMPLES_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,pixels-per-clock" $samples_per_clk int $dts_file 
        set dma_align [expr $samples_per_clk * 8]
        add_prop "$node" "xlnx,dma-align" $dma_align int $dts_file
        set has_interlaced [hsi get_property CONFIG.HAS_INTERLACED [hsi::get_cells -hier $drv_handle]]
        if {$has_interlaced == 1} {
                add_prop "$node" "xlnx,fid" boolean $dts_file
        }
        set dma_addr_width [hsi get_property CONFIG.AXIMM_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,dma-addr-width" $dma_addr_width int $dts_file
        add_prop "$node" "#dma-cells" 1 int $dts_file
        set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,video-width" $max_data_width int $dts_file
        set max_rows [hsi get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
        set max_cols [hsi get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,max-width" $max_cols int $dts_file

    }


