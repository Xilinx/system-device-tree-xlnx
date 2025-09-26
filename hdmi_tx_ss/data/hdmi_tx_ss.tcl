#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2023-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

source [file join [file dirname [info script]] "../../device_tree/data/video_utils.tcl"]

proc hdmi_tx_ss_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	hdmitxss_add_hier_instances $drv_handle
	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,v-hdmi-tx-ss-3.1\""

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

	set phy_names ""
	set phys ""
	set link_data0 [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "LINK_DATA0_OUT"]
	set link_data1 [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "LINK_DATA1_OUT"]
	set link_data2 [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "LINK_DATA2_OUT"]
	set link_data3 [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "LINK_DATA3_OUT"]
        if {[llength $link_data0]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data0]
                if {[llength $ip_mem_handles]} {
			set link_data0_inst $link_data0
                        set link_data0 [hsi get_property IP_NAME $link_data0]
                        if {[string match -nocase $link_data0 "vid_phy_controller"] || [string match -nocase $link_data0 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy0"
                                if {[llength $link_data1]} {
					append phys  "${link_data0_inst}txphy_lane0 0 1 1 1>,"
				} else {
					append phys  "${link_data0_inst}txphy_lane0 0 1 1 1"
				}
                        }
                } else {
			dtg_warning "connected stream of LINK_DATA0_IN is NULL...check the design"
		}
        }

        if {[llength $link_data1]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data1]
                if {[llength $ip_mem_handles]} {
			set link_data1_inst $link_data1
                        set link_data1 [hsi get_property IP_NAME $link_data1]
                        if {[string match -nocase $link_data1 "vid_phy_controller"] || [string match -nocase $link_data1 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy1"
                                if {[llength $link_data2]} {
					append phys  " <&${link_data1_inst}txphy_lane1 0 1 1 1>,"
				} else {
					append phys  " <&${link_data1_inst}txphy_lane1 0 1 1 1"
				}
                        }
                } else {
			dtg_warning "Connected stream of LINK_DATA1_IN is NULL...check the design"
		}
        }
        set link_data2 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA2_OUT"]
        if {[llength $link_data2]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data2]
                if {[llength $ip_mem_handles]} {
			set link_data2_inst $link_data2
                        set link_data2 [hsi get_property IP_NAME $link_data2]
                        if {[string match -nocase $link_data2 "vid_phy_controller"] || [string match -nocase $link_data2 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy2"
                                if {[llength $link_data3]} {
					append phys  " <&${link_data2_inst}txphy_lane2 0 1 1 1>,"
				} else {
					append phys  " <&${link_data2_inst}txphy_lane2 0 1 1 1"
				}
                        }
                } else {
			dtg_warning "Connected stream of LINK_DATA2_IN is NULL...check the design"
		}
        }
        set link_data3 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA3_OUT"]
        if {[llength $link_data3]} {
                set ip_mem_handles [hsi::get_mem_ranges $link_data3]
                if {[llength $ip_mem_handles]} {
			set link_data3_inst $link_data3
                        set link_data3 [hsi get_property IP_NAME $link_data3]
                        if {[string match -nocase $link_data3 "vid_phy_controller"] || [string match -nocase $link_data3 "hdmi_gt_controller"]} {
                                append phy_names " " "hdmi-phy3"
                                append phys " <&${link_data3_inst}txphy_lane3 0 1 1 1"
                        }
                } else {
			dtg_warning "Connected stream of LINK_DATA3_IN is NULL...check the design"
		}
        }

	if {![string match -nocase $phy_names ""]} {
		add_prop "$node" "phy-names" $phy_names stringlist $dts_file 1
	}
	if {![string match -nocase $phys ""]} {
		add_prop "$node" "phys" $phys reference $dts_file 1
	}
	set include_hdcp_1_4 [hsi::get_property CONFIG.C_INCLUDE_HDCP_1_4 [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $include_hdcp_1_4 "true"]} {
		add_prop "${node}" "xlnx,include-hdcp-1-4" "" boolean $dts_file 1
	}
	set include_hdcp_2_2 [hsi::get_property CONFIG.C_INCLUDE_HDCP_2_2 [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $include_hdcp_2_2 "true"]} {
		add_prop "${node}" "xlnx,include-hdcp-2-2" "" boolean $dts_file 1
	}
	if {[string match -nocase $include_hdcp_1_4 "true"] || [string match -nocase $include_hdcp_2_2 "true"]} {
		add_prop "${node}" "xlnx,hdcp-authenticate" 0x1 int $dts_file 1
		add_prop "${node}" "xlnx,hdcp-encrypt" 0x1 int $dts_file 1
	}
	set audio_in_connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "AUDIO_IN"]
	if {[llength $audio_in_connect_ip] != 0} {
		set audio_in_connect_ip_type [hsi::get_property IP_NAME $audio_in_connect_ip]
		if {[string match -nocase $audio_in_connect_ip_type "axis_switch"]} {
			set connected_ip [hsi::get_connected_stream_ip $audio_in_connect_ip "S00_AXIS"]
			if {[llength $connected_ip] != 0} {
				add_prop "$node" "xlnx,snd-pcm" $connected_ip reference $dts_file 1
				add_prop "${node}" "xlnx,audio-enabled" "" boolean $dts_file 1
			}
		} elseif {[string match -nocase $audio_in_connect_ip_type "audio_formatter"]} {
			add_prop "$node" "xlnx,snd-pcm" $audio_in_connect_ip reference $dts_file 1
			add_prop "${node}" "xlnx,audio-enabled" "" boolean $dts_file 1
		}
	} else {
		dtg_warning "$drv_handle pin AUDIO_IN is not connected... check your design"
	}
	set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "acr_cts"]]
	foreach pin $pins {
		set sink_periph [hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			if {[string match -nocase "[hsi::get_property IP_NAME $sink_periph]" "hdmi_acr_ctrl"]} {
				add_prop "$node" "xlnx,xlnx-hdmi-acr-ctrl" $sink_periph reference $dts_file 1
			}
		} else {
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}

}

proc hdmi_tx_ss_update_endpoints {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {[string_is_empty $node]} {
		return
	}
	global end_mappings
	global remo_mappings
	set ports_node [create_node -n "ports" -l hdmitx_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
	set hdmi_port_node [create_node -n "port" -l encoder_hdmi_port$drv_handle -u 0 -p $ports_node -d $dts_file]
	add_prop "$hdmi_port_node" "reg" 0 int $dts_file 1
	set hdmitx_in_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_IN"]
	if {![llength $hdmitx_in_ip]} {
		dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
	}
	set inip ""
	set axis_sw_nm ""
	foreach inip $hdmitx_in_ip {
		if {[llength $inip]} {
			set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $hdmitx_in_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
			set ip_mem_handles [hsi::get_mem_ranges $inip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
					gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node $dts_file
				}
			} else {
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "system_ila"]} {
					continue
				}
				# Check if slice is connected to axis_switch(NM)
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "axis_register_slice"]} {
					set intf "S_AXIS"
					set streamin_ip [get_connected_stream_ip [hsi::get_cells -hier $inip] $intf]
					if {[llength $streamin_ip]} {
						set ip_mem_handles [hsi::get_mem_ranges $streamin_ip]
					}
					if {![llength $ip_mem_handles] && [string match -nocase [hsi::get_property IP_NAME $streamin_ip] "axis_switch"]} {
						set inip "$streamin_ip"
						set axis_sw_nm "1"
					}
				}
				if {![llength $axis_sw_nm]} {
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {![string_is_empty $inip] && [string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
					gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node $dts_file
				}
			}
		}
	}

	if {[llength $inip]} {
		set hdmitx_in_end ""
		set hdmitx_remo_in_end ""
		global end_mappings
		global remo_mappings
		if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
			set hdmitx_in_end [dict get $end_mappings $inip]
			dtg_verbose "hdmitx_in_end:$hdmitx_in_end"
		}
		if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
			set hdmitx_remo_in_end [dict get $remo_mappings $inip]
			dtg_verbose "hdmitx_remo_in_end:$hdmitx_remo_in_end"
		}
		if {[llength $hdmitx_remo_in_end]} {
			set hdmitx_node [create_node -n "endpoint" -l $hdmitx_remo_in_end -p $hdmi_port_node -d $dts_file]
		}
		if {[llength $hdmitx_in_end]} {
			add_prop "$hdmitx_node" "remote-endpoint" $hdmitx_in_end reference $dts_file 1
		}
		# Add endpoints if IN IP is axis_switch and NM
		if {[llength $axis_sw_nm]} {
			update_axis_switch_endpoints $inip $hdmi_port_node $drv_handle
		}
	}
}

proc gen_frmbuf_rd_node {ip drv_handle hdmi_port_node dts_file} {
	set frmbuf_rd_node [create_node -n "endpoint" -l encoder$drv_handle -p $hdmi_port_node -d $dts_file]
	add_prop "$frmbuf_rd_node" "remote-endpoint" $ip$drv_handle reference $dts_file 1
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
	set pl_display [create_node -n "drm-pl-disp-drv$drv_handle" -l "v_pl_disp$drv_handle" -p $bus_node -d $dts_file]
	add_prop $pl_display "compatible" "xlnx,pl-disp" string $dts_file 1
	add_prop $pl_display "dmas" "$ip 0" reference $dts_file 1
	add_prop $pl_display "dma-names" "dma0" string $dts_file 1
#	add_prop "${pl_display}" "/* Fill the field xlnx,vformat based on user requirement */" "" comment
	add_prop $pl_display "xlnx,vformat" "YUYV" string $dts_file 1
	add_prop $pl_display "#address-cells" 1 int $dts_file 1
        add_prop $pl_display "#size-cells" 0 int $dts_file 1
	set pl_display_port_node [create_node -n "port" -l pl_display_port$drv_handle -u 0 -p $pl_display -d $dts_file]
	add_prop "$pl_display_port_node" "reg" 0 int $dts_file 1
	set pl_disp_crtc_node [create_node -n "endpoint" -l $ip$drv_handle -p $pl_display_port_node -d $dts_file]
	add_prop "$pl_disp_crtc_node" "remote-endpoint" encoder$drv_handle reference $dts_file 1
}
proc hdmitxss_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	#hsi::get_cells -hier -filter {IP_NAME==v_tc}
	#hsi get_property IP_NAME [hsi::get_cells -hier v_hdmi_txss1_hdcp_1_4]
	#

	set ip_subcores [dict create]
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_tx" "hdcp22"
	dict set ip_subcores "v_hdmi_tx" "hdmitx"
	dict set ip_subcores "v_tc" "vtc"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
			update_subcore_absolute_addr $drv_handle $ip_handle $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

	set timers [set_ip_handles_for_ss_subcores axi_timer $drv_handle]
	#zynq_us_ss_0_sys_timer_0 zynq_us_ss_0_sys_timer_1 v_hdmi_rxss1_axi_timer v_hdmi_txss1_axi_timer v_hdmi_rxss1_hdcp22_rx_ss_hdcp22_timer v_hdmi_txss1_hdcp22_tx_ss_hdcp22_timer
	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dts_file
	} else {
		foreach timer $timers {
			if { [regexp -nocase $drv_handle $timer match] } {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
				update_subcore_absolute_addr $drv_handle $timer $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}
}
