
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc dp_txss14_generate {drv_handle} {
	set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
	dp_tx_add_hier_instances $drv_handle

        set dtsi_file [set_drv_def_dts $drv_handle]
	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,v-dp-txss-3.1\""
	pldt append $node compatible "\ \, \"xlnx,v-dp-txss-3.0\""

        set num_audio_channels [hsi get_property CONFIG.Number_of_Audio_gt_quad_gtwiz_versal_0rxphy_lane0Channels [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-audio-channels" $num_audio_channels int $dtsi_file
        set audio_enable [hsi get_property CONFIG.AUDIO_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dtsi_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bpc" $bits_per_color int $dtsi_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dtsi_file
        set include_fec_ports [hsi get_property CONFIG.INCLUDE_FEC_PORTS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dtsi_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,lane-count" $lane_count int $dtsi_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,max-lanes" $lane_count int $dtsi_file
	set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
        set link_rate [expr {${link_rate} * 1000}]
        set link_rate [expr int ($link_rate)]
        add_prop "${node}" "xlnx,linkrate" $link_rate int $dtsi_file
	set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
	set link_rate [expr {${link_rate} * 100000}]
	set link_rate [expr int ($link_rate)]
	add_prop "${node}" "xlnx,max-link-rate" $link_rate int $dtsi_file
	set mode [hsi get_property CONFIG.MODE [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,mode" $mode int $dtsi_file
        set mode [hsi get_property CONFIG.MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mode" $mode int $dtsi_file
        set num_streams [hsi get_property CONFIG.NUM_STREAMS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-streams" $num_streams int $dtsi_file
        set phy_data_width [hsi get_property CONFIG.PHY_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,phy-data-width" $phy_data_width int $dtsi_file
        set pixel_mode [hsi get_property CONFIG.PIXEL_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,pixel-mode" $pixel_mode int $dtsi_file
        set sim_mode [hsi get_property CONFIG.SIM_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,sim-mode" $sim_mode string $dtsi_file
        set video_interface [hsi get_property CONFIG.VIDEO_INTERFACE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,video-interface" $video_interface int $dtsi_file
	add_prop "${node}" "xlnx,dp-retimer" "xfmc$drv_handle" reference $dtsi_file
	set clknames "s_axi_aclk tx_vid_clk"
	set reg_names "dp_base"
        set hdcp_enable [hsi get_property CONFIG.HDCP_ENABLE [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $hdcp_enable "1"]} {
               add_prop "${node}" "xlnx,hdcp-enable" $hdcp_enable boolean $dtsi_file 1
		set hdcp_keymngmt [hsi get_cells -hier -filter {IP_NAME == "hdcp_keymngmt_blk"}]
		if {[llength $hdcp_keymngmt]} {
			set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $drv_handle] hdcp_key]
			set target_intf [hsi::get_intf_nets -of_objects $intf]
			add_prop "${node}" "xlnx,hdcp1x-keymgmt"  [hsi::get_cells -of_objects $target_intf -filter IP_NAME==hdcp_keymngmt_blk] reference $dtsi_file
		}
	} else {
		pldt unset $node "xlnx,hdcp-enable"
	}
        set hdcp22_enable [hsi get_property CONFIG.HDCP22_ENABLE [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $hdcp22_enable "1"]} {
               add_prop "${node}" "xlnx,hdcp22-enable" $hdcp22_enable boolean $dtsi_file 1
        } else {
		pldt unset $node "xlnx,hdcp22-enable"
	}
        if {[string match -nocase $hdcp_enable "1"] || [string match -nocase $hdcp22_enable "1"]} {
                add_prop "${node}" "xlnx,hdcp-authenticate" 0x1 int $dtsi_file 1
                add_prop "${node}" "xlnx,hdcp-encrypt" 0x1 int $dtsi_file 1
        }
	set versal_gt [hsi get_property CONFIG.C_VERSAL [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $versal_gt "1"]} {
		add_prop "${node}" "xlnx,versal-gt" $versal_gt boolean $dtsi_file 1

	} else {
		pldt unset $node "xlnx,versal-gt"
	}

	append reg-names "$reg_names"
	add_prop "$node" "reg-names" $reg_names stringlist $dtsi_file 1
	overwrite_clknames $clknames $drv_handle
	set phy_names ""
	set phys ""
	set vtcip [hsi get_cells -hier -filter {IP_NAME == "v_tc"}]
        if {[llength $vtcip]} {
                set baseaddr [hsi get_property CONFIG.C_BASEADDR [hsi get_cells -hier $vtcip]]
                if {[llength $baseaddr]} {
                        add_prop "${node}" "xlnx,vtc-offset" "$baseaddr" int $dtsi_file
                }
        }
	set links {m_axis_lnk_tx_lane0 m_axis_lnk_tx_lane1 m_axis_lnk_tx_lane2 m_axis_lnk_tx_lane3}
	foreach stream_name $links {
		set connected_stream [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $stream_name]
		if {[llength $connected_stream]} {
			set ip_mem_handles [hsi::get_mem_ranges $connected_stream]
			if {[llength $ip_mem_handles]} {
				set link_data_inst $connected_stream
				set link_data [hsi::get_property IP_NAME $connected_stream]
				if {[string match -nocase $link_data "vid_phy_controller"]} {
					set index [lsearch $links $stream_name]
					append phy_names " dp-phy$index"
					if {$index == 0} {
						set phys "${link_data_inst}txphy_lane$index 0 1 1 1"
					} else {
						append phys " <&${link_data_inst}txphy_lane$index 0 1 1 1"
					}
					if {$index != [expr {[llength $links] - 1}]} {
						append phys ">,"
					}
				}
			}
		} else {
		    dtg_warning "Connected stream of $stream_name is NULL...check the design"
		}
	}
	if {![string match -nocase $phy_names ""]} {
		add_prop "$node" "phy-names" $phy_names stringlist $dtsi_file 1
	}
	if {![string match -nocase $phys ""]} {
		add_prop "$node" "phys" $phys reference $dtsi_file 1
	}
	if {[string match -nocase $versal_gt "1"]} {
		set phy_names "dp-gtquad"
		add_prop "$node" "phy-names" $phy_names stringlist $dtsi_file 1

	} else {
		set phy_names "dp-phy0 dp-phy1 dp-phy2 dp-phy3"
		add_prop "$node" "phy-names" $phy_names stringlist $dtsi_file 1

	}
	if {[string match -nocase $versal_gt "1"]} {
		set txpinname "m_axis_lnk_tx_lane0"
		set channelip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $txpinname]
		set gtpinname "GT_TX0"
		set gtip [get_connected_stream_ip [hsi::get_cells -hier $channelip] $gtpinname]
		if {[llength $gtip] && [llength [hsi::get_mem_ranges $gtip]]} {
			set phy_s "${gtip}txphy_lane0 0 1 1 1"
			add_prop "$node" "phys" $phy_s reference $dtsi_file 1
		}
	}
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dtsi_file 1

	set ports_node [create_node -n "ports" -l dptx_ports$drv_handle -p $node -d $dtsi_file]
	add_prop "$ports_node" "#address-cells" 1 int $dtsi_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dtsi_file 1
	set port0_node [create_node -n "port" -l dptx_port$drv_handle -u 0 -p $ports_node -d $dtsi_file]
	add_prop "$port0_node" "reg" 0 int $dtsi_file 1
	set dptxip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video_stream1"]
	if {![llength $dptxip]} {
		dtg_warning "$drv_handle pin s_axis_video_stream1 is not connected...check your design"
	}
	set inip ""
#	set axis_sw_nm ""
	foreach inip $dptxip {
		set intfpins [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
		if {[llength $inip]} {
			set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $dptxip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
			set ip_mem_handles [hsi::get_mem_ranges $inip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
					gen_frmbuf_rd_node $inip $drv_handle $port0_node $dtsi_file
				} else {
					set dp_tx_node [create_node -n "endpoint" -l dptx_out$drv_handle -p $port0_node -d $dtsi_file]
					gen_endpoint $drv_handle "dptx_out$drv_handle"
					if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port0_node $dtsi_file
					} else {
						add_prop "$dp_tx_node" "remote-endpoint" $inip reference $dtsi_file
						gen_remoteendpoint $drv_handle $inip$drv_handle
					}
				}
			} else {
				set connectip [get_connect_ip $inip $intfpins $dtsi_file]
				if {[llength $connectip]} {
					set dp_tx_node [create_node -n "endpoint" -l dptx_out$drv_handle -p $port0_node -d $dtsi_file]
					gen_endpoint $drv_handle "dptx_out$drv_handle"
					if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_mix"]} {
						add_prop "$dp_tx_node" "remote-endpoint" "mixer_crtc$connectip" reference $dtsi_file
						gen_remoteendpoint $drv_handle "mixer_crtc$connectip"
					} else {
						add_prop "$dp_tx_node" "remote-endpoint" $connectip reference $dtsi_file
						gen_remoteendpoint $drv_handle $connectip$drv_handle
					}
					if {[string match -nocase [hsi::get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port0_node $dtsi_file					}
				}
			}
		}
		gen_xfmc_node $drv_handle $dtsi_file
	}
}

proc gen_frmbuf_rd_node {ip drv_handle port0_node dtsi_file} {
	set frmbuf_rd_node [create_node -n "endpoint" -l dptx_out$drv_handle -p $port0_node -d $dtsi_file]
	add_prop "$frmbuf_rd_node" "remote-endpoint" $ip$drv_handle reference $dtsi_file 1
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
        set pl_disp [create_node -n "drm-pl-disp-drv" -l "v_pl_disp$drv_handle" -p $bus_node -d $dtsi_file]
        add_prop $pl_disp "compatible" "xlnx,pl-disp" string $dtsi_file 1
	add_prop $pl_disp "dmas" "$ip 0" reference $dtsi_file 1
        add_prop $pl_disp "dma-names" "dma0" string $dtsi_file 1
        add_prop $pl_disp "xlnx,vformat" "YUYV" string $dtsi_file 1
        add_prop $pl_disp "#address-cells" 1 int $dtsi_file 1
        add_prop $pl_disp "#size-cells" 0 int $dtsi_file 1
	set pl_port_node [create_node -n "port" -l pl_disp_port -u 0 -p $pl_disp -d $dtsi_file]
	add_prop "$pl_port_node" "reg" 0 int $dtsi_file 1
        set pl_disp_crtc_node [create_node -n "endpoint" -l $ip$drv_handle -p $pl_port_node -d $dtsi_file]
        add_prop "$pl_disp_crtc_node" "remote-endpoint" dptx_out$drv_handle reference $dtsi_file 1
}

proc dp_tx_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dtsi_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "v_dual_splitter" "dual-splitter"
	dict set ip_subcores "displayport" "dp14"
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_tx_dp" "hdcp22"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dtsi_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dtsi_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dtsi_file
		}
	}

	set timers [set_ip_handles_for_ss_subcores axi_timer $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_timer}
	#processor_hier_0_axi_timer_0 dp_rx_hier_0_v_dp_rxss1_0_timer dp_tx_hier_0_v_dp_txss1_0_timer

	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dtsi_file
	} else {
		foreach timer $timers {
			set name [hsi get_property NAME [hsi::get_cells -hier $timer]]
			if {[regexp "tx" $name match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dtsi_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dtsi_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dtsi_file
			}
		}
	}
	set vtcs [set_ip_handles_for_ss_subcores v_tc $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_time_tcr}
	#dp_tx_hier_0_v_dp_txss1_0_vtc1 dp_tx_hier_0_v_dp_txss1_0_vtc2 dp_tx_hier_0_v_dp_txss1_0_vtc3 dp_tx_hier_0_v_dp_txss1_0_vtc4

	if {[string_is_empty $vtcs]} {
		add_prop "$node" "vtc1-present" 0 int $dtsi_file
		add_prop "$node" "vtc2-present" 0 int $dtsi_file
		add_prop "$node" "vtc3-present" 0 int $dtsi_file
		add_prop "$node" "vtc4-present" 0 int $dtsi_file
	} else {
		foreach vtc $vtcs {
			if {[regexp "_vtc1" $vtc match]} {
				add_prop "$node" "vtc1-present" 1 int $dtsi_file
				add_prop "$node" "vtc1-connected" $vtc reference $dtsi_file
			}
			if {[regexp "_vtc2" $vtc match]} {
				add_prop "$node" "vtc2-present" 1 int $dtsi_file
				add_prop "$node" "vtc2-connected" $vtc reference $dtsi_file
			}
			if {[regexp "_vtc3" $vtc match]} {
				add_prop "$node" "vtc3-present" 1 int $dtsi_file
				add_prop "$node" "vtc3-connected" $vtc reference $dtsi_file
			}
			if {[regexp "_vtc4" $vtc match]} {
				add_prop "$node" "vtc4-present" 1 int $dtsi_file
				add_prop "$node" "vtc4-connected" $vtc reference $dtsi_file
			}
		}
	}


}

#generate fmc card node as this is required when display port exits
proc gen_xfmc_node {drv_handle dts_file} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
        set pl_disp [create_node -n "xv_fmc$drv_handle" -l "xfmc$drv_handle" -p $bus_node -d $dts_file]
        add_prop $pl_disp "compatible" "xilinx-vfmc" string $dts_file 1
}
