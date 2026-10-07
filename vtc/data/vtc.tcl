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

    proc vtc_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        if {[vtc_connected_to_tpg $drv_handle]} {
                pldt append $node compatible "\ \, \"xlnx,v-tc-6.1\""
        } else {
                pldt append $node compatible "\ \, \"xlnx,bridge-v-tc-6.1\""
        }
        set generate_en [hsi get_property CONFIG.C_GENERATE_EN [hsi::get_cells -hier $drv_handle]]
        if {$generate_en == 1} {
                add_prop "${node}" "xlnx,generator" boolean $dts_file
        }
        set detect_en [hsi get_property CONFIG.C_DETECT_EN [hsi::get_cells -hier $drv_handle]]
        if {$detect_en == 1} {
                add_prop "${node}" "xlnx,detector" boolean $dts_file
        }
	set arbitrary_res_en [hsi get_property CONFIG.C_ARBITRARY_RES_EN [hsi::get_cells -hier $drv_handle]]
	if {[string length $arbitrary_res_en] > 0} {
		set inhex [format %x $arbitrary_res_en]
		append arbitrary "/bits/ 8 <0x$inhex>"
		add_prop "${node}" "xlnx,arbitrary-res-en" $arbitrary noformating $dts_file 1
	}

	set ppc [hsi get_property CONFIG.VID_PPC [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,pixels-per-clock" $ppc hexint $dts_file 1
    }

    # Reverse of the lookup in tpg.tcl: follow active_video_out to
    # v_vid_in_axi4s, then its video_out stream to a v_tpg.
    proc vtc_connected_to_tpg {drv_handle} {
        set vtc [hsi::get_cells -hier $drv_handle]
        set av_pin [hsi::get_pins -of_objects $vtc "active_video_out"]
        set av_net [hsi::get_nets -of_objects $av_pin]
        set pins [hsi::get_pins -of_objects $av_net]
        foreach pin $pins {
                set sink_periph [hsi::get_cells -of_objects $pin]
                if {![llength $sink_periph]} {
                        continue
                }
                if {![string match -nocase [hsi get_property IP_NAME $sink_periph] "v_vid_in_axi4s"]} {
                        continue
                }
                set tpg [get_connected_stream_ip $sink_periph "video_out"]
                if {[llength $tpg] && [string match -nocase [hsi get_property IP_NAME $tpg] "v_tpg"]} {
                        return 1
                }
        }
        return 0
    }

