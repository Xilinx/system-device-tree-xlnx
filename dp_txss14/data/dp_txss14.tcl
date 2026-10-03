
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

# Resolve the board short name. Prefers $::env(sdt_board_dts) when the
# user passed -board_dts on the command line; otherwise derives it from
# the HSI BOARD property, dropping the vendor prefix (e.g. the BOARD
# property "xilinx.com:vek385:part0:1.0" becomes "vek385").
proc dp_sdt_get_board_dts {} {
	set board_dts ""
	set board_hsi ""
	if {[info exists ::env(sdt_board_dts)]} {
		set board_dts $::env(sdt_board_dts)
	}
	set hw_design [hsi::current_hw_design]
	if {[llength $hw_design]} {
		set board_hsi [hsi get_property BOARD $hw_design]
	}
	if {![llength $board_dts] && [llength $board_hsi]} {
		set board_parts [split $board_hsi ":"]
		if {[llength $board_parts] > 1} {
			set board_dts [lindex $board_parts 1]
		} else {
			set board_dts $board_hsi
		}
	}
	return [string tolower $board_dts]
}

# Resolve the device PART string from the active hardware design.
proc dp_sdt_get_hw_part {} {
	set hw_part ""
	set hw_design [hsi::current_hw_design]
	if {[llength $hw_design]} {
		set hw_part [hsi get_property PART $hw_design]
	}
	return [string tolower $hw_part]
}

# Return 1 when the active design targets a VEK385 (Versal 2VE/2VM)
# board, either by BOARD property or by silicon part match.
proc dp_sdt_is_vek385_board {board_dts} {
	if {[string match "*vek385*" $board_dts]} {
		return 1
	}
	set hw_part [dp_sdt_get_hw_part]
	if {[string match "*ve385*" $hw_part]} {
		return 1
	}
	return 0
}

# Locate the v_frmbuf_rd that feeds a native-video DP TX display pipeline.
# Native DP TX designs have no s_axis_video_streamN AXI-Stream pins, so the
# normal graph walk in dp_txss14_generate finds nothing. Enumerate v_frmbuf_rd
# cells and, when more than one exists, follow each one's master AXI-Stream
# forward (through v_tc / converters, up to a bounded hop count) to pick the
# pipeline that reaches this DP TX instance. Returns the cell name, or "".
proc dp_tx_find_native_frmbuf {drv_handle} {
	set frmbuf_cells [hsi::get_cells -hier -filter "IP_NAME==v_frmbuf_rd"]
	if {![llength $frmbuf_cells]} {
		return ""
	}
	if {[llength $frmbuf_cells] == 1} {
		return [lindex $frmbuf_cells 0]
	}
	foreach fb $frmbuf_cells {
		set cur $fb
		for {set hop 0} {$hop < 20} {incr hop} {
			set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $cur] -filter {TYPE==MASTER || TYPE==INITIATOR}]
			if {![llength $master_intf]} {
				break
			}
			set nextip ""
			foreach mi $master_intf {
				set nextip [get_connected_stream_ip [hsi::get_cells -hier $cur] $mi]
				if {[llength $nextip]} {
					break
				}
			}
			if {![llength $nextip]} {
				break
			}
			if {[string match -nocase $nextip $drv_handle]} {
				return $fb
			}
			set cur $nextip
		}
	}
	return [lindex $frmbuf_cells 0]
}

# Locate the standalone v_tc (Video Timing Controller) that drives a native-
# video DP TX pipeline. In an AXI4-Stream design the VTC is internal to the DP
# TX subsystem (vtcN-present) and the DP driver programs it; in a native design
# the VTC is an external IP that the xlnx_pl_disp CRTC must drive via an
# "xlnx,bridge" phandle. Returns the v_tc cell name, or "" when none/unclear.
proc dp_tx_find_native_vtc {drv_handle} {
	set vtc_cells [hsi::get_cells -hier -filter "IP_NAME==v_tc"]
	if {![llength $vtc_cells]} {
		return ""
	}
	if {[llength $vtc_cells] == 1} {
		return [lindex $vtc_cells 0]
	}
	# Multiple VTCs (e.g. multi-instance designs): pick the one whose master
	# AXI-Stream path reaches this DP TX instance; fall back to the first.
	foreach vtc $vtc_cells {
		set cur $vtc
		for {set hop 0} {$hop < 20} {incr hop} {
			set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $cur] -filter {TYPE==MASTER || TYPE==INITIATOR}]
			if {![llength $master_intf]} {
				break
			}
			set nextip ""
			foreach mi $master_intf {
				set nextip [get_connected_stream_ip [hsi::get_cells -hier $cur] $mi]
				if {[llength $nextip]} {
					break
				}
			}
			if {![llength $nextip]} {
				break
			}
			if {[string match -nocase $nextip $drv_handle]} {
				return $vtc
			}
			set cur $nextip
		}
	}
	return [lindex $vtc_cells 0]
}

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
	set versal_gt [hsi get_property CONFIG.C_VERSAL [hsi::get_cells -hier $drv_handle]]
	set tx_phy_retimer [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_lnk_tx_lane0"]
	if {[llength $tx_phy_retimer] && [string match -nocase [hsi::get_property IP_NAME $tx_phy_retimer] "vid_phy_controller"]} {
		add_prop "${node}" "xlnx,dp-retimer" "xfmc$tx_phy_retimer" reference $dtsi_file
	} elseif {[string match -nocase $versal_gt "1"] && [llength $tx_phy_retimer]} {
		set gt_quad [get_connected_stream_ip [hsi::get_cells -hier $tx_phy_retimer] "GT_TX0"]
		if {[llength $gt_quad]} {
			add_prop "${node}" "xlnx,dp-retimer" "xfmc$gt_quad" reference $dtsi_file
		} else {
			add_prop "${node}" "xlnx,dp-retimer" "xfmc$drv_handle" reference $dtsi_file
		}
	} else {
		add_prop "${node}" "xlnx,dp-retimer" "xfmc$drv_handle" reference $dtsi_file
	}
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
	if {[string match -nocase $versal_gt "1"]} {
		add_prop "${node}" "xlnx,versal-gt" $versal_gt boolean $dtsi_file 1

	} else {
		pldt unset $node "xlnx,versal-gt"
	}
	# On Versal 2VE/2VM platforms (e.g. VEK385) the GT Quad needs a
	# small settling delay during DP TX bring-up. The DP TX driver
	# consumes "xlnx,versal-2ve-2vm" together with "xlnx,versal-gt".
	if {[string match -nocase $versal_gt "1"] && [dp_sdt_is_vek385_board [dp_sdt_get_board_dts]]} {
		add_prop "${node}" "xlnx,versal-2ve-2vm" 1 boolean $dtsi_file 1
	} else {
		pldt unset $node "xlnx,versal-2ve-2vm"
	}

	append reg-names "$reg_names"
	add_prop "$node" "reg-names" $reg_names stringlist $dtsi_file 1
	overwrite_clknames $clknames $drv_handle
	set phy_names ""
	set phys ""
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
                        add_prop "${node}" "xlnx,vtc-offset" $vtc_offset_list hexlist $dtsi_file
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
	# is present, gen_frmbuf_rd_node qualifies those labels with drv_handle so
	# they stay globally unique across instances.
	set num_tx 1
	if {![catch {set txss_ipname [hsi::get_property IP_NAME [hsi::get_cells -hier $drv_handle]]}]} {
		set txss_cells [hsi::get_cells -hier -filter "IP_NAME==$txss_ipname"]
		if {[llength $txss_cells]} {
			set num_tx [llength $txss_cells]
		}
	}
	# Track whether the AXI4-Stream walk below actually produced any graph
	# port. Native-video DP TX designs (VIDEO_INTERFACE=Native) have no
	# s_axis_video_streamN AXI-Stream pins, so this stays 0 and triggers the
	# native-video fallback after the loop.
	set graph_generated 0
	for {set stream 1} {$stream <= $num_streams} {incr stream} {
		set port_index [expr {$stream - 1}]
		set dptxip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video_stream$stream"]
		if {![llength $dptxip]} {
			dtg_warning "$drv_handle pin s_axis_video_stream$stream is not connected...check your design"
			continue
		}
		set port0_node [create_node -n "port" -l dptx_port$port_index$drv_handle -u $port_index -p $ports_node -d $dtsi_file]
		add_prop "$port0_node" "reg" $port_index int $dtsi_file 1
		set graph_generated 1
		set inip ""
		foreach inip $dptxip {
			set intfpins [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			if {[llength $inip]} {
				set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $dptxip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port0_node $port_index $num_tx $dtsi_file
					} else {
						set dp_tx_node [create_node -n "endpoint" -l dptx_out$port_index$drv_handle -p $port0_node -d $dtsi_file]
						gen_endpoint $drv_handle "dptx_out$port_index$drv_handle"
						add_prop "$dp_tx_node" "remote-endpoint" $inip reference $dtsi_file
						gen_remoteendpoint $drv_handle $inip$drv_handle
					}
				} else {
					set connectip [get_connect_ip $inip $intfpins $dtsi_file]
					if {[llength $connectip]} {
						set dp_tx_node [create_node -n "endpoint" -l dptx_out$port_index$drv_handle -p $port0_node -d $dtsi_file]
						gen_endpoint $drv_handle "dptx_out$port_index$drv_handle"
						if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_mix"]} {
							add_prop "$dp_tx_node" "remote-endpoint" "mixer_crtc$connectip" reference $dtsi_file
							gen_remoteendpoint $drv_handle "mixer_crtc$connectip"
						} else {
							add_prop "$dp_tx_node" "remote-endpoint" $connectip reference $dtsi_file
							gen_remoteendpoint $drv_handle $connectip$drv_handle
						}
						if {[string match -nocase [hsi::get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_rd"]} {
							gen_frmbuf_rd_node $inip $drv_handle $port0_node $port_index $num_tx $dtsi_file
						}
					}
				}
			}
		}
	}
	# Native-video fallback: when the AXI4-Stream graph walk above produced no
	# port/endpoint (e.g. a VIDEO_INTERFACE=Native DP TX design that has no
	# s_axis_video_streamN pins), the display source is a v_frmbuf_rd wired
	# through the native video path (frmbuf_rd -> v_tc -> native vid_in). Emit
	# the pl-disp CRTC for that frame buffer so DRM still gets a display
	# pipeline. AXI4-Stream designs are unaffected because graph_generated is 1.
	if {!$graph_generated} {
		set native_frmbuf [dp_tx_find_native_frmbuf $drv_handle]
		if {[llength $native_frmbuf]} {
			set port_index 0
			set port0_node [create_node -n "port" -l dptx_port$port_index$drv_handle -u $port_index -p $ports_node -d $dtsi_file]
			add_prop "$port0_node" "reg" $port_index int $dtsi_file 1
			# Native pipelines have an EXTERNAL VTC that the pl-disp CRTC must
			# drive; pass it so gen_frmbuf_rd_node emits the xlnx,bridge phandle.
			set native_vtc [dp_tx_find_native_vtc $drv_handle]
			if {![llength $native_vtc]} {
				dtg_warning "$drv_handle native-video design has no external v_tc; drm-pl-disp-drv will lack xlnx,bridge (no timing generator)"
			}
			gen_frmbuf_rd_node $native_frmbuf $drv_handle $port0_node $port_index $num_tx $dtsi_file $native_vtc
		} else {
			dtg_warning "$drv_handle no v_frmbuf_rd found for native-video display pipeline; drm-pl-disp-drv not generated"
		}
	}
}

proc gen_frmbuf_rd_node {ip drv_handle port0_node port_index num_tx dtsi_file {vtc_bridge ""}} {
	# Design-global running index for the drm-pl-disp-drv node name, so every
	# CRTC node is unique across all streams AND all DP TX instances
	# (reproduces drm-pl-disp-drv-0..N in both the single-instance MST and the
	# multi-instance references). It is intentionally NOT reset per instance.
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
	# Native-video pipelines: reference the external VTC so xlnx_pl_disp drives
	# the timing generator (of_parse_phandle(node,"xlnx,bridge")). Omitted for
	# AXI4-Stream designs where the VTC is internal to the DP TX subsystem.
	if {[llength $vtc_bridge]} {
		add_prop $pl_disp "xlnx,bridge" "$vtc_bridge" reference $dtsi_file 1
	}
	set pl_port_node [create_node -n "port" -l "$pl_disp_port_label" -u 0 -p $pl_disp -d $dtsi_file]
	add_prop "$pl_port_node" "reg" 0 int $dtsi_file 1
	set pl_disp_crtc_node [create_node -n "endpoint" -l $pl_disp_out_label -p $pl_port_node -d $dtsi_file]
	add_prop "$pl_disp_crtc_node" "remote-endpoint" dptx_out$port_index$drv_handle reference $dtsi_file 1
	incr dptx_pldisp_index
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
