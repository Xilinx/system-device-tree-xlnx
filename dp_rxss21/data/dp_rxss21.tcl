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
proc dp_rxss21_generate {drv_handle} {
	set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
	dp_rx_21_add_hier_instances $drv_handle

	set dts_file [set_drv_def_dts $drv_handle]
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1

	dp_rx_21_add_link_props $drv_handle
	dp_rx_21_add_video_ports $drv_handle
}

# Return the vid_edid instance that belongs to this receiver.
#
# A design can hold more than one DP receiver, each with its own EDID block.
# The subsystem and its EDID sit in the same hierarchical block, so their
# instance names share a prefix and the longest match wins.
proc dp_rxss21_find_edid_ip {drv_handle} {
	set best ""
	set best_len -1

	foreach cell [hsi get_cells -hier -filter IP_NAME==vid_edid] {
		set len 0
		foreach a [split $cell {}] b [split $drv_handle {}] {
			if {$a ne $b} {
				break
			}
			incr len
		}
		if {$len > $best_len} {
			set best_len $len
			set best $cell
		}
	}

	return $best
}

# Fill in the properties the driver needs on top of the ones the generic
# parameter export already covers: the bits per component under the name the
# driver reads, the EDID register range and the video PHY wiring.
proc dp_rx_21_add_link_props {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set ip [hsi::get_cells -hier $drv_handle]

	if {[get_hw_family] in {"microblaze" "Zynq"}} {
		set bit_format 32
	} else {
		set bit_format 64
	}

	# The driver reads xlnx,bpc, while the generic export only publishes
	# the value as xlnx,bits-per-color.
	set bpc ""
	foreach param {BITS_PER_COLOR Max_Bits_Per_Color C_MAX_BITS_PER_COLOR} {
		set bpc [hsi get_property CONFIG.$param $ip]
		if {[llength $bpc]} {
			break
		}
	}
	if {[string is integer -strict $bpc]} {
		add_prop "${node}" "xlnx,bpc" $bpc int $dts_file 1
	} else {
		dtg_warning "$drv_handle: bits per component is not available in the design...check the design"
	}

	# The EDID block sits outside the subsystem, so the driver maps it as a
	# second register range named edid_base.
	set reg_names "dp_base"
	set edid_ip [dp_rxss21_find_edid_ip $drv_handle]
	if {[llength $edid_ip]} {
		set edid [hsi get_cells -hier $edid_ip]
		set reg_val [gen_reg_property_format \
			[hsi get_property CONFIG.C_BASEADDR $ip] \
			[hsi get_property CONFIG.C_HIGHADDR $ip] $bit_format]
		append reg_val ">, <[gen_reg_property_format \
			[hsi get_property CONFIG.C_BASEADDR $edid] \
			[hsi get_property CONFIG.C_HIGHADDR $edid] $bit_format]"
		add_prop "$node" "reg" "$reg_val" hexlist $dts_file 1
		lappend reg_names "edid_base"
	} else {
		dtg_warning "$drv_handle: no vid_edid instance found...the driver needs an edid_base range"
	}
	add_prop "$node" "reg-names" $reg_names stringlist $dts_file 1

	# Every link lane is driven by a video PHY channel. The PHY driver
	# labels its per-lane nodes <instance>rxphy_lane<N>, so only emit an
	# entry for the lanes the design actually wired up.
	set phys ""
	set phy_names {}
	set vidphy ""
	for {set lane 0} {$lane < 4} {incr lane} {
		set connected [get_connected_stream_ip $ip "s_axis_lnk_rx_lane$lane"]
		if {![llength $connected]} {
			continue
		}
		if {![string match -nocase [hsi::get_property IP_NAME $connected] "vid_phy_controller"]} {
			continue
		}
		set vidphy $connected
		if {![llength $phy_names]} {
			set phys "${connected}rxphy_lane$lane 0 1 1 0"
		} else {
			append phys ">, <&${connected}rxphy_lane$lane 0 1 1 0"
		}
		lappend phy_names "dp-phy$lane"
	}
	if {[llength $phy_names]} {
		add_prop "$node" "phys" $phys reference $dts_file 1
		add_prop "$node" "phy-names" $phy_names stringlist $dts_file 1
		add_prop "$node" "xlnx,vidphy" $vidphy reference $dts_file 1
	} else {
		dtg_warning "$drv_handle: no video PHY is wired to the link lanes...check the design"
	}
}

# Resolve how many video stream ports the design exposes.
#
# The subsystem drives one m_axis_video_streamN master per MST stream. An
# SST design (xlnx,mode=0) only ever carries a single stream no matter how
# many the IP was built for, so it gets a single port. This mirrors the way
# the driver derives num_mst_streams from xlnx,mode and xlnx,num-streams.
proc dp_rxss21_get_stream_count {drv_handle} {
	set ip [hsi::get_cells -hier $drv_handle]

	set mode [hsi get_property CONFIG.MODE $ip]
	if {![llength $mode]} {
		set mode 0
	}

	# CONFIG.NUM_STREAMS is the canonical name; the older subsystem
	# releases only expose the MST stream count under its IP-GUI name.
	set num_streams ""
	foreach param {NUM_STREAMS Number_of_MST_Streams C_NUMBER_OF_MST_STREAMS} {
		set num_streams [hsi get_property CONFIG.$param $ip]
		if {[llength $num_streams]} {
			break
		}
	}
	if {![string is integer -strict $num_streams] || $num_streams < 1} {
		set num_streams 1
	}

	if {![string match -nocase $mode "1"]} {
		return 1
	}
	if {$num_streams > 4} {
		dtg_warning "$drv_handle: xlnx,num-streams=$num_streams exceeds the four streams the DP Rx driver supports...check the design"
	}
	return $num_streams
}

# Generate the media graph for the DP 2.1 Rx video outputs.
#
# One port@N holding a single endpoint is emitted per active video stream,
# wired to whatever that stream's m_axis_video_streamN master drives. Every
# stream that lands in a frame buffer writer is collected as well, so that a
# single vcap node can expose one DMA per stream.
proc dp_rx_21_add_video_ports {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set total_streams [dp_rxss21_get_stream_count $drv_handle]

	set ports_node [create_node -n "ports" -l dp21rx_ports$drv_handle -p ${node} -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file
	add_prop "$ports_node" "#size-cells" 0 int $dts_file

	set vcap_frmbuf_list {}

	for {set stream_idx 0} {$stream_idx < $total_streams} {incr stream_idx} {
		set stream_pin "m_axis_video_stream[expr {$stream_idx + 1}]"
		# Keep the first stream on unsuffixed labels so that SST designs
		# and the primary MST stream carry the same names.
		if {$stream_idx == 0} {
			set port_label "dp21rx_port$drv_handle"
			set endpoint_label "dp21rx_out$drv_handle"
		} else {
			set port_label "dp21rx_port${stream_idx}$drv_handle"
			set endpoint_label "dp21rx_out${stream_idx}$drv_handle"
		}

		set port_node [create_node -n "port" -u $stream_idx -l $port_label -p $ports_node -d $dts_file]
		add_prop "$port_node" "reg" $stream_idx int $dts_file

		set dprxip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $stream_pin]
		if {![llength $dprxip]} {
			dtg_warning "$drv_handle: connected stream of $stream_pin is NULL...check the design"
			continue
		}

		foreach ip $dprxip {
			set intfpins [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			if {[llength [hsi::get_mem_ranges $ip]]} {
				set ep_node [create_node -n "endpoint" -l $endpoint_label -p $port_node -d $dts_file]
				gen_endpoint $drv_handle $endpoint_label
				if {[string match -nocase [hsi::get_property IP_NAME $ip] "v_frmbuf_wr"]} {
					add_prop "$ep_node" "remote-endpoint" $ip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle $ip$drv_handle
					lappend vcap_frmbuf_list [list $ip $stream_idx $endpoint_label]
				} else {
					add_prop "$ep_node" "remote-endpoint" $ip reference $dts_file
					gen_remoteendpoint $drv_handle $ip$drv_handle
				}
			} else {
				set connectip [get_connect_ip $ip $intfpins $dts_file]
				if {[llength $connectip]} {
					set ep_node [create_node -n "endpoint" -l $endpoint_label -p $port_node -d $dts_file]
					gen_endpoint $drv_handle $endpoint_label
					add_prop "$ep_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle $connectip$drv_handle
					set connect_name [hsi::get_property IP_NAME $connectip]
					if {[string match -nocase $connect_name "v_frmbuf_wr"] ||
					    [string match -nocase $connect_name "axi_vdma"]} {
						lappend vcap_frmbuf_list [list $connectip $stream_idx $endpoint_label]
					}
				}
			}
		}
	}

	if {[llength $vcap_frmbuf_list]} {
		gen_vcap_dp21rx_node $drv_handle $dts_file $vcap_frmbuf_list
	}
}

# Emit the vcap node aggregating every frame buffer writer that captures a
# DP 2.1 Rx stream. frmbuf_list holds {ip stream_idx endpoint_label} triples,
# one per active stream, so an SST design collapses to a single DMA while MST
# produces port@0..port@N-1 with one DMA each.
proc gen_vcap_dp21rx_node {drv_handle dts_file frmbuf_list} {
	set bus_node [detect_bus_name $drv_handle]
	set vcap [create_node -n "vcap_dp21rx$drv_handle" -p $bus_node -d $dts_file]
	add_prop $vcap "compatible" "xlnx,video" string $dts_file

	# add_prop's "reference" type only wraps the first entry in <&...>, so
	# close and reopen the angle brackets by hand for the remaining ones,
	# the same way the phys list is built elsewhere.
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
	add_prop $vcap "dmas" $dma_refs reference $dts_file 1
	add_prop $vcap "dma-names" $dma_names stringlist $dts_file 1

	set vcap_ports_node [create_node -n "ports" -l vcap_dp21rx_ports$drv_handle -p $vcap -d $dts_file]
	add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
	add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file

	foreach entry $frmbuf_list {
		set ip [lindex $entry 0]
		set idx [lindex $entry 1]
		set ep_label [lindex $entry 2]
		if {$idx == 0} {
			set port_label "vcap_dp21rx_port$drv_handle"
		} else {
			set port_label "vcap_dp21rx_port${idx}$drv_handle"
		}
		set vcap_port_node [create_node -n "port" -l $port_label -u $idx -p $vcap_ports_node -d $dts_file]
		add_prop "$vcap_port_node" "reg" $idx int $dts_file 1
		add_prop "$vcap_port_node" "direction" input string $dts_file 1
		set vcap_in_node [create_node -n "endpoint" -l $ip$drv_handle -p $vcap_port_node -d $dts_file]
		add_prop "$vcap_in_node" "remote-endpoint" $ep_label reference $dts_file
	}
}


proc dp_rx_21_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "axi_iic" "iic"
	dict set ip_subcores "clk_wiz" "clkWiz"
	dict set ip_subcores "dprx" "dp21"
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
