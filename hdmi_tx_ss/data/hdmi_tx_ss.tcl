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

namespace eval ::tclapp::xilinx::devicetree::hdmi_tx_ss {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {
		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		if {$node == 0} {
			return
		}
		pldt append $node compatible "\ \, \"xlnx,v-hdmi-tx-ss-3.1\""
		set input_pixels_per_clock [get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock int $dts_file
		set max_bits_per_component [get_property CONFIG.C_MAX_BITS_PER_COMPONENT [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-bits-per-component" $max_bits_per_component int $dts_file
		set phy_names ""
		set phys ""
		set link_data0 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA0_OUT"]
		if {[llength $link_data0]} {
			set link_data0 [get_property IP_NAME $link_data0]
			if {[string match -nocase $link_data0 "vid_phy_controller"] || [string match -nocase $link_data0 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy0"
				append phys  "vphy_lane0 0 1 1 1>,"
			}
		} else {
			dtg_warning "connected stream of LINK_DATA0_IN is NULL...check the design"
		}
		set link_data1 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA1_OUT"]
		if {[llength $link_data1]} {
			set link_data1 [get_property IP_NAME $link_data1]
			if {[string match -nocase $link_data1 "vid_phy_controller"] || [string match -nocase $link_data1 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy1"
				append phys  " <&vphy_lane1 0 1 1 1>,"
			}
		} else {
			dtg_warning "Connected stream of LINK_DATA1_IN is NULL...check the design"
		}
		set link_data2 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA2_OUT"]
		if {[llength $link_data2]} {
			set link_data2 [get_property IP_NAME $link_data2]
			if {[string match -nocase $link_data2 "vid_phy_controller"] || [string match -nocase $link_data2 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy2"
				append phys " <&vphy_lane2 0 1 1 1"
			}
		} else {
			dtg_warning "Connected stream of LINK_DATA2_IN is NULL...check the design"
		}

		if {![string match -nocase $phy_names ""]} {
			add_prop "$node" "phy-names" $phy_names stringlist $dts_file
		}
		if {![string match -nocase $phys ""]} {
			add_prop "$node" "phys" $phys reference $dts_file
		}
		set include_hdcp_1_4 [get_property CONFIG.C_INCLUDE_HDCP_1_4 [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $include_hdcp_1_4 "true"]} {
			add_prop "${node}" "xlnx,include-hdcp-1-4" "" boolean $dts_file
		}
		set include_hdcp_2_2 [get_property CONFIG.C_INCLUDE_HDCP_2_2 [hsi::get_cells -hier $drv_handle]]
		if {[string match -nocase $include_hdcp_2_2 "true"]} {
			add_prop "${node}" "xlnx,include-hdcp-2-2" "" boolean $dts_file
		}
		if {[string match -nocase $include_hdcp_1_4 "true"] || [string match -nocase $include_hdcp_2_2 "true"]} {
			add_prop "${node}" "xlnx,hdcp-authenticate" 0x1 int $dts_file
			add_prop "${node}" "xlnx,hdcp-encrypt" 0x1 int $dts_file
		}
		set audio_in_connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "AUDIO_IN"]
		if {[llength $audio_in_connect_ip] != 0} {
			set audio_in_connect_ip_type [get_property IP_NAME $audio_in_connect_ip]
			if {[string match -nocase $audio_in_connect_ip_type "axis_switch"]} {
				set connected_ip [get_connected_stream_ip $audio_in_connect_ip "S00_AXIS"]
				if {[llength $connected_ip] != 0} {
					add_prop "$node" "xlnx,snd-pcm" $connected_ip reference $dts_file
					add_prop "${node}" "xlnx,audio-enabled" "" boolean $dts_file
				}
			} elseif {[string match -nocase $audio_in_connect_ip_type "audio_formatter"]} {
				add_prop "$node" "xlnx,snd-pcm" $audio_in_connect_ip reference $dts_file
				add_prop "${node}" "xlnx,audio-enabled" "" boolean $dts_file
			}
		} else {
			dtg_warning "$drv_handle pin AUDIO_IN is not connected... check your design"
		}
	}
}
