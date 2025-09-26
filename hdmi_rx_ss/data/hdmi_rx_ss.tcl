#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc hdmi_rx_ss_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	hdmirxss_add_hier_instances $drv_handle
	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,v-hdmi-rx-ss-3.1\""

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
	set audio_out_connect_ip [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "AUDIO_OUT"]
	if {[llength $audio_out_connect_ip] != 0} {
		set audio_out_connect_ip_type [hsi get_property IP_NAME $audio_out_connect_ip]
		if {[string match -nocase $audio_out_connect_ip_type "axis_switch"]} {
			 set connected_ip [get_connected_stream_ip $audio_out_connect_ip "M00_AXIS"]
                        if {[llength $connected_ip] != 0} {
                                add_prop "$node" "xlnx,snd-pcm" $connected_ip reference $dts_file 1
				add_prop "${node}" "xlnx,audio-enabled" "" boolean $dts_file 1
                        }
		} elseif {[string match -nocase $audio_out_connect_ip_type "audio_formatter"]} {
			add_prop "$node" "xlnx,snd-pcm" $audio_out_connect_ip reference $dts_file 1
			add_prop "${node}" "xlnx,audio-enabled" "" boolean $dts_file 1 $dts_file 1
		}
	} else {
		dtg_warning "$drv_handle pin AUDIO_OUT is not connected... check your design"
	}
        set ports_node [create_node -n "ports" -l hdmirx_ports$drv_handle -p $node -d $dts_file]
        add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
        add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
        set port_node [create_node -n "port" -l hdmirx_port$drv_handle -u 0 -p $ports_node -d $dts_file]
#        add_prop "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment
        add_prop "$port_node" "xlnx,video-format" 0 int $dts_file 1
        add_prop "$port_node" "xlnx,video-width" 10 int $dts_file 1
        add_prop "$port_node" "reg" 0 int $dts_file 1
        set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_OUT"]
        foreach ip $outip {
                if {[llength $ip]} {
                        set master_intf [hsi get_intf_pins -of_objects [hsi get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                        set ip_mem_handles [hsi get_mem_ranges $ip]
                        if {[llength $ip_mem_handles]} {
                                set hdmi_rx_node [create_node -n "endpoint" -l hdmirx_out$drv_handle -p $port_node -d $dts_file]
                                gen_endpoint $drv_handle "hdmirx_out$drv_handle"
                                add_prop "$hdmi_rx_node" "remote-endpoint" $ip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle $ip$drv_handle
                                if {[string match -nocase [hsi::get_property IP_NAME $ip] "v_frmbuf_wr"]} {
                                        gen_frmbuf_node $ip $drv_handle $dts_file
                                }
                        } else {
                                if {[string match -nocase [hsi::get_property IP_NAME $ip] "system_ila"]} {
                                        continue
                                }
                                set connectip [get_connect_ip $ip $master_intf $dts_file]
                                if {[llength $connectip]} {
                                        set hdmi_rx_node [create_node -n "endpoint" -l hdmirx_out$drv_handle -p $port_node -d $dts_file]
                                        gen_endpoint $drv_handle "hdmirx_out$drv_handle"
                                        add_prop "$hdmi_rx_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                        gen_remoteendpoint $drv_handle $connectip$drv_handle
                                        if {[string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                                gen_frmbuf_node $connectip $drv_handle $dts_file
                                        }
                                }
                        }
                }
        }


	set phy_names ""
	set phys ""
	set link_data0 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA0_IN"]
	set link_data1 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA1_IN"]
	set link_data2 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA2_IN"]
	set link_data3 [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "LINK_DATA3_IN"]

	if {[llength $link_data0]} {
		set ip_mem_handles [hsi::get_mem_ranges $link_data0]
		if {[llength $ip_mem_handles]} {
			set link_data0_inst $link_data0
			set link_data0 [hsi::get_property IP_NAME $link_data0]
			if {[string match -nocase $link_data0 "vid_phy_controller"] || [string match -nocase $link_data0 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy0"
				if {[llength $link_data1]} {
					append phys  "${link_data0_inst}rxphy_lane0 0 1 1 0>,"
				} else {
					append phys  "${link_data0_inst}rxphy_lane0 0 1 1 0"
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
			set link_data1 [hsi::get_property IP_NAME $link_data1]
			if {[string match -nocase $link_data1 "vid_phy_controller"] || [string match -nocase $link_data1 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy1"
				if {[llength $link_data2]} {
					append phys  " <&${link_data1_inst}rxphy_lane1 0 1 1 0>,"
				} else {
					append phys  " <&${link_data1_inst}rxphy_lane1 0 1 1 0"
				}
			}
		} else {
			dtg_warning "Connected stream of LINK_DATA1_IN is NULL...check the design"
		}
	}

	if {[llength $link_data2]} {
		set ip_mem_handles [hsi::get_mem_ranges $link_data2]
		if {[llength $ip_mem_handles]} {
			set link_data2_inst $link_data2
			set link_data2 [hsi::get_property IP_NAME $link_data2]
			if {[string match -nocase $link_data2 "vid_phy_controller"] || [string match -nocase $link_data2 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy2"
				if {[llength $link_data3]} {
					append phys " <&${link_data2_inst}rxphy_lane2 0 1 1 0>,"
				} else {
					append phys " <&${link_data2_inst}rxphy_lane2 0 1 1 0"
				}
			}
		} else {
			dtg_warning "Connected stream of LINK_DATA2_IN is NULL...check the design"
		}
	}

	if {[llength $link_data3]} {
		set ip_mem_handles [hsi::get_mem_ranges $link_data3]
		if {[llength $ip_mem_handles]} {
			set link_data3_inst $link_data3
			set link_data3 [hsi get_property IP_NAME $link_data3]
			if {[string match -nocase $link_data3 "vid_phy_controller"] || [string match -nocase $link_data3 "hdmi_gt_controller"]} {
				append phy_names " " "hdmi-phy3"
				append phys " <&${link_data3_inst}rxphy_lane3 0 1 1 0"
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
}

proc gen_frmbuf_node {ip drv_handle dts_file} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
        set vcap [create_node -n "vcap_$drv_handle" -p $bus_node -d $dts_file]
        add_prop $vcap "compatible" "xlnx,video" string $dts_file
        add_prop $vcap "dmas" "$ip 0" reference $dts_file
        add_prop $vcap "dma-names" "port0" string $dts_file
        set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dts_file]
        add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
        add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
        set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
        add_prop "$vcap_port_node" "reg" 0 int $dts_file
        add_prop "$vcap_port_node" "direction" input string $dts_file
        set vcap_in_node [create_node -n "endpoint" -l $ip$drv_handle -p $vcap_port_node -d $dts_file]
        add_prop "$vcap_in_node" "remote-endpoint" hdmirx_out$drv_handle reference $dts_file
}



proc hdmirxss_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set subsystem_base_addr [get_baseaddr $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	#hsi::get_cells -hier -filter {IP_NAME==v_tc}
	#
	#dict set ip_subcores "v_tc" "vtc"

	set ip_subcores [dict create]
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_rx" "hdcp22"
	dict set ip_subcores "v_hdmi_rx" "hdmirx"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
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
			if {[regexp -nocase $drv_handle $timer match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}
}
