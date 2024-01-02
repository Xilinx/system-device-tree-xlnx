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

    proc hdmi_txss1_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	hdmi_txss_add_hier_instances $drv_handle

        pldt append $node compatible "\ \, \"xlnx,v-hdmi-tx-ss-3.1\""
        set input_pixels_per_clock [hsi get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
        set max_bits_per_component [hsi get_property CONFIG.C_MAX_BITS_PER_COMPONENT [hsi::get_cells -hier $drv_handle]]
            set vid_interface [hsi get_property CONFIG.C_VID_INTERFACE [hsi::get_cells -hier $drv_handle]]
            add_prop "${node}" "xlnx,vid-interface" $vid_interface int $dts_file 1
        set phy_names ""
        set phys ""
        set link_data0 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA0_OUT"]
        if {[llength $link_data0]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data0]
                if {[llength $ip_mem_handles]} {
                        set link_data0 [hsi get_property IP_NAME $link_data0]
                        if {[string match -nocase $link_data0 "vid_phy_controller"] || [string match -nocase $link_data0 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy0"
                                append phys  "vphy_lane0 0 1 1 1>,"
                        }
                }
        } else {
                dtg_warning "connected stream of LINK_DATA0_IN is NULL...check the design"
        }
        set link_data1 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA1_OUT"]
        if {[llength $link_data1]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data1]
                if {[llength $ip_mem_handles]} {
                        set link_data1 [hsi get_property IP_NAME $link_data1]
                        if {[string match -nocase $link_data1 "vid_phy_controller"] || [string match -nocase $link_data1 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy1"
                                append phys  " <&vphy_lane1 0 1 1 1>,"
                        }
                }
        } else {
                dtg_warning "Connected stream of LINK_DATA1_IN is NULL...check the design"
        }
        set link_data2 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA2_OUT"]
        if {[llength $link_data2]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data2]
                if {[llength $ip_mem_handles]} {
                        set link_data2 [hsi get_property IP_NAME $link_data2]
                        if {[string match -nocase $link_data2 "vid_phy_controller"] || [string match -nocase $link_data2 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy2"
                                append phys " <&vphy_lane2 0 1 1 1"
                        }
                }
        } else {
                dtg_warning "Connected stream of LINK_DATA2_IN is NULL...check the design"
        }
	#Above the logic is return but this section is not required that why removing plus causing a issue. reason is mention in line 74

	#if {![string match -nocase $phy_names ""]} {
	#	add_prop "$node" "phy-names" $phy_names stringlist $dts_file
	#}
	#if {![string match -nocase $phys ""]} {
	#below line is casuing the issue: """" ERROR (phandle_references): /amba_pl/v_hdmi_txss1@a4020000: Reference to non-existent node or label "vphy_lane1" """""
	#	add_prop "$node" "phys" $phys reference $dts_file
	#}

        set include_hdcp_1_4 [hsi get_property CONFIG.C_INCLUDE_HDCP_1_4 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $include_hdcp_1_4 "true"]} {
                add_prop "${node}" "xlnx,include-hdcp-1-4" "" boolean $dts_file
        }
        set include_hdcp_2_2 [hsi get_property CONFIG.C_INCLUDE_HDCP_2_2 [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $include_hdcp_2_2 "true"]} {
                add_prop "${node}" "xlnx,include-hdcp-2-2" "" boolean $dts_file
        }
        if {[string match -nocase $include_hdcp_1_4 "true"] || [string match -nocase $include_hdcp_2_2 "true"]} {
                add_prop "${node}" "xlnx,hdcp-authenticate" 0x1 int $dts_file
                add_prop "${node}" "xlnx,hdcp-encrypt" 0x1 int $dts_file
        }
        set audio_in_connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "AUDIO_IN"]
        if {[llength $audio_in_connect_ip] != 0} {
                set audio_in_connect_ip_type [hsi get_property IP_NAME $audio_in_connect_ip]
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
        set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "acr_cts"]]
           foreach pin $pins {
           set sink_periph [hsi::get_cells -of_objects $pin]
           if {[llength $sink_periph]} {
                  if {[string match -nocase "[hsi get_property IP_NAME $sink_periph]" "hdmi_acr_ctrl"]} {
                          add_prop "$node" "xlnx,xlnx-hdmi-acr-ctrl" $sink_periph reference $dts_file
                  }
           } else {
                  dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
           }
    }
	set highaddr [hsi get_property CONFIG.C_HIGHADDR  [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" $highaddr hexint $dts_file 1

	set freq [get_clk_pin_freq  $drv_handle "s_axi_cpu_aclk"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
       add_prop "${node}" "xlnx,axi-lite-freq-hz" $freq hexint $dts_file 1


    }

proc hdmi_txss_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	hsi::current_hw_instance $drv_handle

	#hsi::get_cells -hier -filter {IP_NAME==v_tc}
	#hsi get_property IP_NAME [hsi::get_cells -hier v_hdmi_txss1_hdcp_1_4]
	#

	set ip_subcores [dict create]
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_tx" "hdcp22"
	dict set ip_subcores "v_hdmi_tx1" "hdmitx1"
	dict set ip_subcores "v_tc" "vtc"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [hsi::get_cells -filter "IP_NAME==$ip"]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

	set timers [hsi::get_cells -filter {IP_NAME==axi_timer}]
	#zynq_us_ss_0_sys_timer_0 zynq_us_ss_0_sys_timer_1 v_hdmi_rxss1_axi_timer v_hdmi_txss1_axi_timer v_hdmi_rxss1_hdcp22_rx_ss_hdcp22_timer v_hdmi_txss1_hdcp22_tx_ss_hdcp22_timer
	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dts_file
	} else {
		foreach timer $timers {
			set name [hsi get_property NAME [hsi::get_cells -hier $timer]]
			if {[regexp "v_hdmi_txss1_axi_timer" $name match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}
	hsi::current_hw_instance



}
