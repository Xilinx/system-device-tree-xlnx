#
# (C) Copyright 2020-2022 Xilinx, Inc.
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

proc dp_txss21_generate {drv_handle} {
	set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

	dp_tx_21_add_hier_instances $drv_handle

        set dts_file [set_drv_def_dts $drv_handle]
        set num_audio_channels [hsi get_property CONFIG.Number_of_Audio_Channels [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-audio-channels" $num_audio_channels int $dts_file
        set audio_enable [hsi get_property CONFIG.AUDIO_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dts_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dts_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bpc" $bits_per_color int $dts_file
        set hdcp_enable [hsi get_property CONFIG.HDCP_ENABLE [hsi::get_cells -hier $drv_handle]]
	# HDCP enables are read via of_property_read_bool (presence, not value),
	# so the property MUST be absent when disabled - unset it instead of
	# emitting <0>, which the driver would misread as enabled.
	if {[string match -nocase $hdcp_enable "1"]} {
		add_prop "${node}" "xlnx,hdcp-enable" $hdcp_enable boolean $dts_file 1
		set hdcp_keymngmt [hsi get_cells -hier -filter {IP_NAME == "hdcp_keymngmt_blk"}]
		if {[llength $hdcp_keymngmt]} {
			set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $drv_handle] hdcp_key]
			set target_intf [hsi::get_intf_nets -of_objects $intf]
			add_prop "${node}" "xlnx,hdcp1x-keymgmt"  [hsi::get_cells -of_objects $target_intf -filter IP_NAME==hdcp_keymngmt_blk] reference $dts_file
		}
	} else {
		pldt unset $node "xlnx,hdcp-enable"
	}
        set hdcp22_enable [hsi get_property CONFIG.HDCP22_ENABLE [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $hdcp22_enable "1"]} {
		add_prop "${node}" "xlnx,hdcp22-enable" $hdcp22_enable boolean $dts_file 1
	} else {
		pldt unset $node "xlnx,hdcp22-enable"
	}
        if {[string match -nocase $hdcp_enable "1"] || [string match -nocase $hdcp22_enable "1"]} {
                add_prop "${node}" "xlnx,hdcp-authenticate" 0x1 int $dts_file 1
                add_prop "${node}" "xlnx,hdcp-encrypt" 0x1 int $dts_file 1
        }
        set include_fec_ports [hsi get_property CONFIG.INCLUDE_FEC_PORTS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dts_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,lane-count" $lane_count int $dts_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,max-lanes" $lane_count int $dts_file
        set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
        set link_rate [expr {${link_rate} * 1000}]
        set link_rate [expr int ($link_rate)]
        add_prop "${node}" "xlnx,linkrate" $link_rate int $dts_file
        set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
        set link_rate [expr {${link_rate} * 100000}]
        set link_rate [expr int ($link_rate)]
        add_prop "${node}" "xlnx,max-link-rate" $link_rate int $dts_file
        set mode [hsi get_property CONFIG.MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mode" $mode int $dts_file
        set num_streams [hsi get_property CONFIG.NUM_STREAMS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-streams" $num_streams int $dts_file
        set phy_data_width [hsi get_property CONFIG.PHY_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,phy-data-width" $phy_data_width int $dts_file
        set pixel_mode [hsi get_property CONFIG.PIXEL_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,pixel-mode" $pixel_mode int $dts_file
        set sim_mode [hsi get_property CONFIG.SIM_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,sim-mode" $sim_mode string $dts_file
        set video_interface [hsi get_property CONFIG.VIDEO_INTERFACE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,video-interface" $video_interface int $dts_file
	# reg-names is required: the driver maps its register block by name
	# (platform_get_resource_byname(.., "dp_base")).
	set reg_names "dp_base"
	add_prop "$node" "reg-names" $reg_names stringlist $dts_file 1
	# Map each DP TX link lane to its Video PHY (vid_phy_controller) TX lane
	# so the xlnx-dp-tx driver can devm_phy_get("dp-phy0".."dp-phy3"). Without
	# phys/phy-names the driver fails probe with -ENODEV on dp-phy0 (external
	# vphy / non-versal-gt datapath).
	set phy_names ""
	set phys ""
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
	if {![string match -nocase $phys ""]} {
		add_prop "$node" "phys" $phys reference $dts_file 1
	}
	set phy_names "dp-phy0 dp-phy1 dp-phy2 dp-phy3"
	add_prop "$node" "phy-names" $phy_names stringlist $dts_file 1
        # Scope VTC lookup to this TXSS hierarchy and emit one offset per VTC
        # sub-core, so MST designs get an xlnx,vtc-offset entry for every stream's
        # VTC (e.g. <0x8000 0x9000 0xA000 0xB000>) instead of only the first.
        set vtcip [set_ip_handles_for_ss_subcores v_tc $drv_handle]
        if {[llength $vtcip]} {
                set vtc_offsets ""
                foreach vtc_inst $vtcip {
                        set baseaddr [hsi get_property CONFIG.C_BASEADDR [hsi::get_cells -hier $vtc_inst]]
                        if {[llength $baseaddr]} {
                                lappend vtc_offsets $baseaddr
                        }
                }
                if {[llength $vtc_offsets]} {
                        # Sort ascending so offsets line up with VTC/stream index order
                        set vtc_offsets [lsort -integer $vtc_offsets]
                        set vtc_offset_list ""
                        foreach off $vtc_offsets {
                                append vtc_offset_list [format "0x%08X" $off] " "
                        }
                        set vtc_offset_list [string trimright $vtc_offset_list " "]
                        add_prop "${node}" "xlnx,vtc-offset" $vtc_offset_list hexlist $dts_file
                }
        }
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1

	set ports_node [create_node -n "ports" -l dptx_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
	# Generate one graph port and one drm-pl-disp-drv CRTC per DP TX video
	# stream. MST designs expose NUM_STREAMS s_axis_video_streamN pins, each
	# driven by its own v_frmbuf_rd, so every stream gets an independent
	# display pipeline. SST designs have a single stream (index 0).
	if {![string is integer -strict $num_streams] || $num_streams < 1} {
		set num_streams 1
	}
	# Count DP TX subsystem instances in this design. For a single-instance
	# design the pl-disp graph labels are emitted in the exact reference form
	# (stream-indexed, no drv_handle suffix). When more than one DP TX instance
	# is present, gen_frmbuf_rd_node_21 qualifies those labels with drv_handle so
	# they stay globally unique across instances.
	set num_tx 1
	if {![catch {set txss_ipname [hsi::get_property IP_NAME [hsi::get_cells -hier $drv_handle]]}]} {
		set txss_cells [hsi::get_cells -hier -filter "IP_NAME==$txss_ipname"]
		if {[llength $txss_cells]} {
			set num_tx [llength $txss_cells]
		}
	}
	for {set stream 1} {$stream <= $num_streams} {incr stream} {
		set port_index [expr {$stream - 1}]
		set dptxip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video_stream$stream"]
		if {![llength $dptxip]} {
			dtg_warning "$drv_handle pin s_axis_video_stream$stream is not connected...check your design"
			continue
		}
		set port0_node [create_node -n "port" -l dptx_port$port_index$drv_handle -u $port_index -p $ports_node -d $dts_file]
		add_prop "$port0_node" "reg" $port_index int $dts_file 1
		set inip ""
		foreach inip $dptxip {
			set intfpins [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			if {[llength $inip]} {
				set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $dptxip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node_21 $inip $drv_handle $port0_node $port_index $num_tx $dts_file
					} else {
						set dp_tx_node [create_node -n "endpoint" -l dptx_out$port_index$drv_handle -p $port0_node -d $dts_file]
						gen_endpoint $drv_handle "dptx_out$port_index$drv_handle"
						add_prop "$dp_tx_node" "remote-endpoint" $inip reference $dts_file
						gen_remoteendpoint $drv_handle $inip$drv_handle
					}
				} else {
					set connectip [get_connect_ip $inip $intfpins $dts_file]
					if {[llength $connectip]} {
						set dp_tx_node [create_node -n "endpoint" -l dptx_out$port_index$drv_handle -p $port0_node -d $dts_file]
						gen_endpoint $drv_handle "dptx_out$port_index$drv_handle"
						if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_mix"]} {
							add_prop "$dp_tx_node" "remote-endpoint" "mixer_crtc$connectip" reference $dts_file
							gen_remoteendpoint $drv_handle "mixer_crtc$connectip"
						} else {
							add_prop "$dp_tx_node" "remote-endpoint" $connectip reference $dts_file
							gen_remoteendpoint $drv_handle $connectip$drv_handle
						}
						if {[string match -nocase [hsi::get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_rd"]} {
							gen_frmbuf_rd_node_21 $inip $drv_handle $port0_node $port_index $num_tx $dts_file
						}
					}
				}
			}
		}
	}
}

proc gen_frmbuf_rd_node_21 {ip drv_handle port0_node port_index num_tx dtsi_file} {
	# Design-global running index for the drm-pl-disp-drv node name, so every
	# CRTC node is unique across all streams AND all DP TX instances. Shared with
	# the dp14 generator (same global) so mixed dp14/dp21 designs stay unique.
	# It is intentionally NOT reset per instance.
	global dptx_pldisp_index
	if {![info exists dptx_pldisp_index]} {
		set dptx_pldisp_index 0
	}
	set disp_index $dptx_pldisp_index
	# Keep single-instance output identical to the reference (stream-indexed,
	# no drv_handle suffix). For multi-instance designs qualify the pl-disp
	# graph labels with drv_handle to keep them globally unique.
	if {$num_tx > 1} {
		set pl_disp_out_label "pl_disp_out$port_index$drv_handle"
		set pl_disp_port_label "pl_disp_port$port_index$drv_handle"
	} else {
		set pl_disp_out_label "pl_disp_out$port_index"
		set pl_disp_port_label "pl_disp_port$port_index"
	}
	# DP TX graph endpoint for this stream: link the port to its pl-disp CRTC.
	set frmbuf_rd_node [create_node -n "endpoint" -l dptx_out$port_index$drv_handle -p $port0_node -d $dtsi_file]
	add_prop "$frmbuf_rd_node" "remote-endpoint" $pl_disp_out_label reference $dtsi_file 1
	set bus_node "amba_pl: amba_pl"
	# One drm-pl-disp-drv CRTC per DP TX video stream. In MST each stream has
	# its own v_frmbuf_rd and its own display pipeline; SST has a single
	# stream (index 0).
	set pl_disp [create_node -n "drm-pl-disp-drv-$disp_index" -l "v_pl_disp$port_index$drv_handle" -p $bus_node -d $dtsi_file]
	add_prop $pl_disp "compatible" "xlnx,pl-disp" string $dtsi_file 1
	add_prop $pl_disp "#address-cells" 1 int $dtsi_file 1
	add_prop $pl_disp "xlnx,vformat" "YUYV" string $dtsi_file 1
	add_prop $pl_disp "dmas" "$ip 0" reference $dtsi_file 1
	add_prop $pl_disp "#size-cells" 0 int $dtsi_file 1
	add_prop $pl_disp "dma-names" "dma0" string $dtsi_file 1
	set pl_port_node [create_node -n "port" -l "$pl_disp_port_label" -u 0 -p $pl_disp -d $dtsi_file]
	add_prop "$pl_port_node" "reg" 0 int $dtsi_file 1
	set pl_disp_crtc_node [create_node -n "endpoint" -l $pl_disp_out_label -p $pl_port_node -d $dtsi_file]
	add_prop "$pl_disp_crtc_node" "remote-endpoint" dptx_out$port_index$drv_handle reference $dtsi_file 1
	incr dptx_pldisp_index
}

proc dp_tx_21_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "v_dual_splitter" "dual-splitter"
	dict set ip_subcores "dptx" "dp21"
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_tx_dp" "hdcp22"

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
	#hsi::get_cells -hier -filter {IP_NAME==axi_timer}
	#processor_hier_0_axi_timer_0 dp_rx_hier_0_v_dp_rxss1_0_timer dp_tx_hier_0_v_dp_txss1_0_timer

	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dts_file
	} else {
		foreach timer $timers {
			set name [hsi get_property NAME [hsi::get_cells -hier $timer]]
			if {[regexp "tx" $name match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}
	set vtcs [set_ip_handles_for_ss_subcores v_tc $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_time_tcr}
	#dp_tx_hier_0_v_dp_txss1_0_vtc1 dp_tx_hier_0_v_dp_txss1_0_vtc2 dp_tx_hier_0_v_dp_txss1_0_vtc3 dp_tx_hier_0_v_dp_txss1_0_vtc4

	if {[string_is_empty $vtcs]} {
		add_prop "$node" "vtc1-present" 0 int $dts_file
		add_prop "$node" "vtc2-present" 0 int $dts_file
		add_prop "$node" "vtc3-present" 0 int $dts_file
		add_prop "$node" "vtc4-present" 0 int $dts_file
	} else {
		foreach vtc $vtcs {
			if {[regexp "_vtc1" $vtc match]} {
				add_prop "$node" "vtc1-present" 1 int $dts_file
				add_prop "$node" "vtc1-connected" $vtc reference $dts_file
			}
			if {[regexp "_vtc2" $vtc match]} {
				add_prop "$node" "vtc2-present" 1 int $dts_file
				add_prop "$node" "vtc2-connected" $vtc reference $dts_file
			}
			if {[regexp "_vtc3" $vtc match]} {
				add_prop "$node" "vtc3-present" 1 int $dts_file
				add_prop "$node" "vtc3-connected" $vtc reference $dts_file
			}
			if {[regexp "_vtc4" $vtc match]} {
				add_prop "$node" "vtc4-present" 1 int $dts_file
				add_prop "$node" "vtc4-connected" $vtc reference $dts_file
			}
		}
	}

}
