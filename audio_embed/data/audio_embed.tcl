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

    proc audio_embed_generate {drv_handle} {
        set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

	set line_rate [hsi get_property CONFIG.C_LINE_RATE [hsi get_cells -hier $drv_handle]]
	switch $line_rate {
		"3G_SDI" {
			add_prop "${node}" "xlnx,line-rate" 0 int $dts_file 1
		}
		"6G_SDI" {
			add_prop "${node}" "xlnx,line-rate" 1 int $dts_file 1
		}
		"12G_SDI_8DS" {
			add_prop "${node}" "xlnx,line-rate" 2 int $dts_file 1
		}
		"12G_SDI_16DS" {
			add_prop "${node}" "xlnx,line-rate" 3 int $dts_file 1
		}
		default {
			add_prop "${node}" "xlnx,line-rate" 4 int $dts_file 1
		}
	}

        pldt append $node compatible "\ \, \"xlnx,v-uhdsdi-audio-2.0\""
        set connected_extract_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "SDI_EXTRACT_ANC_DS_IN"]
        if {[llength $connected_extract_ip] != 0} {
                add_prop "$node" "xlnx,sdi-rx-video" $connected_extract_ip reference $dts_file
        } else {
                dtg_warning "$drv_handle connected_extract_ip is NULL for the pin SDI_EXTRACT_ANC_DS_IN"
        }

	set afunction [hsi get_property CONFIG.C_AUDIO_FUNCTION [hsi get_cells -hier $drv_handle]]
	if {[string match -nocase $afunction "embed"]} {
		add_prop "$node" "xlnx,audio-function" 0 int $dts_file 1
	} elseif {[string match -nocase $afunction "extract"]} {
		add_prop "$node" "xlnx,audio-function" 1 int $dts_file 1
	} else {
		dtg_warning "undefined audio-function "
	}


	#Error : pl.dtsi:238.57-262.5: ERROR (phandle_references): /amba_pl/v_uhdsdi_audio@a40b0000: Reference to non-existent node or label "axis_data_fifo_Audio"
	#issue due to below lines: Its cdding logic address as axis_data_fifo_audio but there is not such node
#        set connected_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_DATA"]
#        if {[llength $connected_ip] != 0} {
#   #             set index [lsearch [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $connected_ip]
#		set index [lsearch [hsi get_cells -hier] $connected_ip]
#                if {$index != -1 } {
#                        add_prop "$node" "xlnx,snd-pcm" $connected_ip reference $dts_file
#                }
#        } else {
#                dtg_warning "$drv_handle connected ip is NULL for the pin S_AXIS_DATA"
#        }
#        set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "M_AXIS_DATA"]
#        if {[llength $connect_ip] != 0} {
#   #             set index [lsearch [get_mem_ranges -of_objects [get_cells -hier [get_sw_processor]]] $connect_ip]
#		set index [lsearch [hsi get_cells -hier] $connected_ip]
#                if {$index != -1 } {
#                        add_prop "$node" "xlnx,snd-pcm" $connect_ip reference $dts_file
#                }
#        } else {
#                dtg_warning "$drv_handle connected ip is NULL for the pin M_AXIS_DATA"
#        }
    }


