#
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

# If there are multiple dp_rx nodes, the bindings to the corresponding
# sub nodes (edid, vidphy, ..) can be specified by putting them
# into the same hierarchical subblock.
# This way their names will have common prefixes.
# 'find_best_match' is used to return the sub node whose name matches
# best the name of the dp_rx node

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

proc common_prefix {a b} {
	set res {}
	foreach i [split $a {}] j [split $b {}] {
		if {$i eq $j} {append res $i} else break
	}
	set res
}

proc find_best_match {dp cells} {
	set idx 0
	set max_len 0
	set nr 0
	foreach cell $cells {
		set sub [common_prefix $cell $dp]
		set len [string length $sub]
		if {$len > $max_len} {
			set max_len $len
			set idx $nr
		}
	        incr nr
	}
	set res [lindex $cells $idx]
}

proc dp_rxss14_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set family [get_hw_family]
	if {$family in {"microblaze" "Zynq"}} {
		set bit_format 32
	} else {
		set bit_format 64
	}
	dp_rx_add_hier_instances $drv_handle

	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,v-dp-rxss-3.1\" "
	pldt append $node compatible "\ \, \"xlnx,v-dp-rxss-3.0\" "

        set dts_file [set_drv_def_dts $drv_handle]
	set audio_enable [hsi get_property CONFIG.AUDIO_ENABLE [hsi::get_cells -hier $drv_handle]]

	if {$audio_enable == 1} {
		add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dts_file
		set audio_channels [hsi get_property CONFIG.AUDIO_CHANNELS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,audio-channels" $audio_channels int $dts_file
	}
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dts_file
        set hdcp22_enable [hsi get_property CONFIG.HDCP22_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bpc" $bits_per_color int $dts_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        set hdcp_enable [hsi get_property CONFIG.HDCP_ENABLE [hsi::get_cells -hier $drv_handle]]
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
                add_prop "${node}" "xlnx,hdcp-authenticate" 0x1 int $dts_file
                add_prop "${node}" "xlnx,hdcp-encrypt" 0x1 int $dts_file
        }
	set versal_gt [hsi get_property CONFIG.C_VERSAL [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $versal_gt "1"]} {
		add_prop "${node}" "xlnx,versal-gt" $versal_gt boolean $dts_file 1

	} else {
		pldt unset $node "xlnx,versal-gt"
	}
	# On Versal 2VE/2VM platforms (e.g. VEK385) the GT Quad needs a
	# small settling delay during DP RX bring-up. The DP RX driver
	# consumes "xlnx,versal-2ve-2vm" together with "xlnx,versal-gt".
	if {[string match -nocase $versal_gt "1"] && [dp_sdt_is_vek385_board [dp_sdt_get_board_dts]]} {
		add_prop "${node}" "xlnx,versal-2ve-2vm" 1 boolean $dts_file 1
	} else {
		pldt unset $node "xlnx,versal-2ve-2vm"
	}
        set include_fec_ports [hsi get_property CONFIG.INCLUDE_FEC_PORTS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dts_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,lane-count" $lane_count int $dts_file
        set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
        set link_rate [expr {${link_rate} * 1000}]
        set link_rate [expr int ($link_rate)]
        add_prop "${node}" "xlnx,linkrate" $link_rate int $dts_file
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
	set connected_phy [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_lnk_rx_lane0"]
	set is_vphy [expr {[llength $connected_phy] && [string match -nocase [hsi::get_property IP_NAME $connected_phy] "vid_phy_controller"]}]
	if {$is_vphy} {
		add_prop "${node}" "xlnx,vidphy" $connected_phy reference $dts_file
	}
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {$is_vphy} {
		add_prop "${node}" "xlnx,dp-retimer" "xfmc$connected_phy" reference $dts_file
	} elseif {[string match -nocase $versal_gt "1"] && [llength $connected_phy]} {
		set gt_quad [get_connected_stream_ip [hsi::get_cells -hier $connected_phy] "GT_RX0"]
		if {[llength $gt_quad]} {
			add_prop "${node}" "xlnx,dp-retimer" "xfmc$gt_quad" reference $dts_file
		} else {
			add_prop "${node}" "xlnx,dp-retimer" "xfmc$drv_handle" reference $dts_file
		}
	} else {
		add_prop "${node}" "xlnx,dp-retimer" "xfmc$drv_handle" reference $dts_file
	}

	set edid_ip [find_best_match $drv_handle [hsi get_cells -hier -filter IP_NAME==vid_edid]]
	if {[llength $edid_ip]} {
		set baseaddr_dp_rx [hsi get_property CONFIG.C_BASEADDR [hsi get_cells -hier $drv_handle]]
		set highaddr_dp_rx [hsi get_property CONFIG.C_HIGHADDR [hsi get_cells -hier $drv_handle]]
		set baseaddr [hsi get_property CONFIG.C_BASEADDR [hsi get_cells -hier $edid_ip]]
		set highaddr [hsi get_property CONFIG.C_HIGHADDR [hsi get_cells -hier $edid_ip]]
		set reg_val_0 [gen_reg_property_format $baseaddr_dp_rx $highaddr_dp_rx $bit_format]
		set updat [lappend updat $reg_val_0]
		set reg_val_1 [gen_reg_property_format $baseaddr $highaddr $bit_format]
		set updat [lappend updat $reg_val_1]
		set reg_val [lindex $updat 0]
		append reg_val ">, <[lindex $updat 1]"
		add_prop $node reg "$reg_val" hexlist $dts_file 1
	}

	lappend reg_names "dp_base" "edid_base"
	add_prop "$node" "reg-names" $reg_names stringlist $dts_file 1
	if {[string match -nocase $versal_gt "1"]} {
		set phy_names "dp-gtquad"
	} else {
		set phy_names "dp-phy0 dp-phy1 dp-phy2 dp-phy3"
	}
	add_prop "${node}" "phy-names" $phy_names stringlist $dts_file 1

	set phy_names ""
	set phys ""
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1
	set links {s_axis_lnk_rx_lane0 s_axis_lnk_rx_lane1 s_axis_lnk_rx_lane2 s_axis_lnk_rx_lane3}
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
						set phys "${link_data_inst}rxphy_lane$index 0 1 1 0"
					} else {
						append phys " <&${link_data_inst}rxphy_lane$index 0 1 1 0"
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
		add_prop "$node" "phy-names" $phy_names stringlist $dts_file 1
	}
	if {![string match -nocase $phys ""]} {
		add_prop "$node" "phys" $phys reference $dts_file 1
	}

	if {[string match -nocase $versal_gt "1"]} {
		set rxpinname "s_axis_lnk_rx_lane0"
		set channelip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $rxpinname]
		puts "$channelip"

		set gtpinname "GT_RX0"
		set gtip [get_connected_stream_ip [hsi::get_cells -hier $channelip] $gtpinname]
		if {[llength $gtip] && [llength [hsi::get_mem_ranges $gtip]]} {
			set phy_s "${gtip}rxphy_lane0 0 1 1 0"
			add_prop "$node" "phys" $phy_s reference $dts_file 1
		}
	}
	set ports_node [create_node -n "ports" -l dprx_ports$drv_handle -p ${node} -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file
	add_prop  "$ports_node" "#size-cells" 0 int $dts_file

	# Decide how many sink-side stream ports to generate.
	# SST (xlnx,mode=0) only ever drives a single video stream, so we keep
	# the legacy single port@0 node. MST (xlnx,mode=1) splits the link into
	# xlnx,num-streams independent video streams, each of which needs its
	# own port@N + remote frmbuf_wr endpoint and a matching dma in the
	# vcap_dprx node. Anything else is conservatively treated as SST.
	if {[string match -nocase $mode "1"]} {
		set total_streams $num_streams
	} else {
		set total_streams 1
	}

	# Aggregate the frmbuf_wr endpoints across streams so that a single
	# vcap_dprx node can be emitted with the full dmas / dma-names list.
	set vcap_frmbuf_list {}

	for {set stream_idx 0} {$stream_idx < $total_streams} {incr stream_idx} {
		set stream_pin "m_axis_video_stream[expr {$stream_idx + 1}]"
		# Preserve the legacy unsuffixed labels for the primary stream so
		# that consumers (driver, kernel video pipeline) keep working in
		# SST and in the first MST stream.
		if {$stream_idx == 0} {
			set port_label "dprx_port$drv_handle"
			set endpoint_label "dprx_out$drv_handle"
		} else {
			set port_label "dprx_port${stream_idx}$drv_handle"
			set endpoint_label "dprx_out${stream_idx}$drv_handle"
		}

		set port_node [create_node -n "port" -u $stream_idx -l $port_label -p $ports_node -d $dts_file]
		add_prop  "$port_node" "reg" $stream_idx int $dts_file
		add_prop "$port_node" "xlnx,video-format" 0 int $dts_file
		add_prop "$port_node" "xlnx,video-width" 8 int $dts_file

		set dprxip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $stream_pin]
		foreach ip $dprxip {
			set intfpins [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi::get_mem_ranges $ip]
			if {[llength $ip_mem_handles]} {
				set dp_rx_node [create_node -n "endpoint" -l $endpoint_label -p $port_node -d $dts_file]
				gen_endpoint $drv_handle $endpoint_label
				if {[string match -nocase [hsi::get_property IP_NAME $ip] "v_frmbuf_wr"]} {
					add_prop  "$dp_rx_node" "remote-endpoint" $ip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle $ip$drv_handle
					lappend vcap_frmbuf_list [list $ip $stream_idx $endpoint_label]
				} else {
					add_prop  "$dp_rx_node" "remote-endpoint" $ip reference $dts_file
					gen_remoteendpoint $drv_handle $ip$drv_handle
				}
			} else {
				set connectip [get_connect_ip $ip $intfpins $dtsi_file]
				if {[llength $connectip]} {
					set sdi_rx_node [create_node -n "endpoint" -l $endpoint_label -p $port_node -d $dts_file]
					gen_endpoint $drv_handle $endpoint_label
					add_prop  "$sdi_rx_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle $connectip$drv_handle
					if {[string match -nocase [hsi::get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
						lappend vcap_frmbuf_list [list $connectip $stream_idx $endpoint_label]
					}
				}
			}
		}
	}

	# Emit a single vcap_dprx node aggregating every collected frmbuf_wr.
	# For SST this collapses to one entry, matching the previous behaviour;
	# for MST it produces port@0..port@N-1 with one dma per stream.
	if {[llength $vcap_frmbuf_list] > 0} {
		gen_vcap_dprx_node $drv_handle $dts_file $vcap_frmbuf_list
	}
}

proc gen_frmbuf_wr_node {outip drv_handle port0_node dtsi_file} {
        # Backwards-compatible single-stream wrapper around
        # gen_vcap_dprx_node. Kept so any out-of-tree caller that still
        # invokes the old proc continues to work.
        set frmbuf_list [list [list $outip 0 dprx_out$drv_handle]]
        gen_vcap_dprx_node $drv_handle $dtsi_file $frmbuf_list
}

# Generate the vcap_dprx node aggregating every frmbuf_wr endpoint feeding
# the DP RX. frmbuf_list is a list of {ip stream_idx endpoint_label}
# triples, one per active stream (1 for SST, num_streams for MST).
proc gen_vcap_dprx_node {drv_handle dtsi_file frmbuf_list} {
        set bus_node [detect_bus_name $drv_handle]
        set vcap [create_node -n "vcap_dprx$drv_handle" -p $bus_node -d $dtsi_file]
        add_prop $vcap "compatible" "xlnx,video" string $dtsi_file

        # Build the dmas reference list and matching dma-names list. The
        # add_prop "reference" type wraps the first entry in <&...>; for
        # subsequent entries we explicitly close the previous angle bracket
        # and open a new one with the &-prefix, mirroring the pattern used
        # by the existing phys-list generation.
        set dma_refs ""
        set dma_names ""
        set first 1
        foreach entry $frmbuf_list {
                set ip [lindex $entry 0]
                set idx [lindex $entry 1]
                if {$first} {
                        set dma_refs "$ip 0"
                        set first 0
                } else {
                        append dma_refs ">, <&$ip 0"
                }
                if {[string length $dma_names]} {
                        append dma_names " "
                }
                append dma_names "port$idx"
        }
        add_prop $vcap "dmas" $dma_refs reference $dtsi_file 1
        add_prop $vcap "dma-names" $dma_names stringlist $dtsi_file 1

        set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dtsi_file]
        add_prop $vcap_ports_node "#address-cells" 1 int $dtsi_file
        add_prop "$vcap_ports_node" "#size-cells" 0 int $dtsi_file

        foreach entry $frmbuf_list {
                set ip [lindex $entry 0]
                set idx [lindex $entry 1]
                set ep_label [lindex $entry 2]
                if {$idx == 0} {
                        set port_label "vcap_port$drv_handle"
                } else {
                        set port_label "vcap_port${idx}$drv_handle"
                }
                set vcap_port_node [create_node -n "port" -l $port_label -u $idx -p $vcap_ports_node -d $dtsi_file]
                add_prop "$vcap_port_node" "reg" $idx int $dtsi_file 1
                add_prop "$vcap_port_node" "direction" input string $dtsi_file 1
                set vcap_in_node [create_node -n "endpoint" -l $ip$drv_handle -p $vcap_port_node -d $dtsi_file]
                add_prop "$vcap_in_node" "remote-endpoint" $ep_label reference $dtsi_file
        }
}

proc dp_rx_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "axi_iic" "iic"
	dict set ip_subcores "displayport" "dp14"
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_rx_dp" "hdcp22"

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

	dict set ip_subcores "clk_wizard" "xlnx,clk-wiz"
	dict set ip_subcores "clkx5_wiz" "xlnx,clk-wiz"

	# The DP Rx driver consumes the new "xlnx,clk-wiz" phandle property
	# (renamed from the legacy camelCase "clkWiz-connected" to match the
	# v-dp-rxss dt-binding). It auto-detects the connected wizard variant
	# (xlnx,clkx5-wiz-1.0 vs xlnx,clk-wizard-1.0) from the referenced
	# node's compatible string.
	#
	# The legacy "clkWiz-connected" / "clkWiz-present" properties are
	# emitted in parallel for downstream tooling and older driver
	# branches that still key on the camelCase names. They will be
	# removed once those consumers are migrated.
	set clk_ip_handle [set_ip_handles_for_ss_subcores clkx5_wiz $drv_handle]
	if {[string_is_empty $clk_ip_handle]} {
		set clk_ip_handle [set_ip_handles_for_ss_subcores clk_wizard $drv_handle]
	}
	if {![string_is_empty $clk_ip_handle]} {
		add_prop "$node" "xlnx,clk-wiz-present" 1 int $dts_file
		add_prop "$node" "xlnx,clk-wiz" $clk_ip_handle reference $dts_file
		add_prop "$node" "clkWiz-present" 1 int $dts_file
		add_prop "$node" "clkWiz-connected" $clk_ip_handle reference $dts_file
	} else {
		add_prop "$node" "xlnx,clk-wiz-present" 0 int $dts_file
		add_prop "$node" "clkWiz-present" 0 int $dts_file
	}

	set timers [set_ip_handles_for_ss_subcores axi_timer $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_timer}
	#processor_hier_0_axi_timer_0 dp_rx_hier_0_v_dp_rxss1_0_timer dp_tx_hier_0_v_dp_txss1_0_timer

	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dts_file
	} else {
		foreach timer $timers {
			set name [hsi get_property NAME [hsi::get_cells -hier $timer]]
			if {[regexp "rx" $name match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}

}
