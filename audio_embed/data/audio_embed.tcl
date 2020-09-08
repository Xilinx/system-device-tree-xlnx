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
namespace eval audio_embed {
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		set dts_file [set_drv_def_dts $drv_handle]
		pldt append $node compatible "\ \, \"xlnx,v-uhdsdi-audio-2.0\""
		set connected_embed_ip [hsi::utils::get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "SDI_EMBED_ANC_DS_IN"]
		if {[llength $connected_embed_ip] != 0} {
			set connected_embed_ip_type [get_property IP_NAME $connected_embed_ip]
			if {[string match -nocase $connected_embed_ip_type "v_smpte_uhdsdi_tx_ss"]} {
				set sdi_av_port [create_node -n "port" -l sdi_av_port -u 0 -p $node -d $dts_file]
				add_prop "$sdi_av_port" "reg" 0 int $dts_file
				set sdi_embed_node [create_node -n "endpoint" -l sditx_audio_embed_src -p $sdi_av_port -d $dts_file]
				add_prop "$sdi_embed_node" "remote-endpoint" sdi_audio_sink_port reference $dts_file
			}
		} else {
			dtg_warning "$drv_handle connected_ip is NULL for the pin SDI_EMBED_ANC_DS_IN"
		}
		set connected_extract_ip [hsi::utils::get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "SDI_EXTRACT_ANC_DS_IN"]
		if {[llength $connected_extract_ip] != 0} {
			add_prop "$node" "xlnx,sdi-rx-video" $connected_extract_ip reference $dts_file
		} else {
			dtg_warning "$drv_handle connected_extract_ip is NULL for the pin SDI_EXTRACT_ANC_DS_IN"
		}
		set connected_ip [hsi::utils::get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_DATA"]
		if {[llength $connected_ip] != 0} {
			add_prop "$node" "xlnx,snd-pcm" $connected_ip reference $dts_file
		} else {
			dtg_warning "$drv_handle connected ip is NULL for the pin S_AXIS_DATA"
		}
		set connect_ip [hsi::utils::get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "M_AXIS_DATA"]
		if {[llength $connect_ip] != 0} {
			add_prop "$node" "xlnx,snd-pcm" $connect_ip reference $dts_file
		} else {
			dtg_warning "$drv_handle connected ip is NULL for the pin M_AXIS_DATA"
		}
	}
}
