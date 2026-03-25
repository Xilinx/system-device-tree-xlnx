#
# (C) Copyright 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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
#
# Endpoint rules for axis_subset_converter:
# - Do not force output remote-endpoint when downstream mappings are missing.
# - Avoid adding output remote-endpoint for v_frmbuf_wr and v_proc_ss; those IPs own their endpoints.
# - For input port@0, only add a fallback endpoint label (no remote-endpoint) when mappings are missing.
# - MIPI input creates its endpoint on the MIPI side; subset port@0 may remain without remote-endpoint.

proc axis_subset_converter_generate {drv_handle} {
        set ip $drv_handle
	set ip_name [hsi get_property IP_NAME [hsi get_cells -hier $drv_handle]]

	# Check HIER_NAME property before creating the node
	if {[catch {set hier_name [hsi get_property HIER_NAME [hsi::get_cells -hier $drv_handle]]} error_msg]} {
		set hier_name ""
	}

	# Skip node creation if HIER_NAME contains "/"
	if {[string match "*/*" $hier_name]} {
		return
	}

	set bus_node [detect_bus_name $ip]
        set dts_file [set_drv_def_dts $drv_handle]
        set subset_node [create_node -n "axis_subset$ip" -l $ip -u 0 -p $bus_node -d $dts_file]
	set ip_name [hsi get_property IP_NAME [hsi get_cells -hier $drv_handle]]
	set ips [hsi get_cells -hier -filter {IP_NAME == "axis_subset_converter"}]
	pldt append $subset_node compatible "\"xlnx,axis-subsetconv-1.1\""
        set ports_node [create_node -n "ports" -l axis_subset_ports$ip -p $subset_node -d $dts_file]
        add_prop "$ports_node" "#address-cells" 1 int $dts_file
        add_prop "$ports_node" "#size-cells" 0 int $dts_file

	# Create port0 (input) early if connected to MIPI (which has no memory map)
	set axis_subset_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
	if {[llength $axis_subset_inip]} {
		set axis_subset_inip_name [hsi get_property IP_NAME $axis_subset_inip]
	} else {
	}
	if {[llength $axis_subset_inip]} {
	}

	# Skip over transparent IPs like axis_data_fifo to find the real source
	while {[llength $axis_subset_inip] && [string match -nocase [hsi get_property IP_NAME $axis_subset_inip] "axis_data_fifo"]} {
		set axis_subset_inip [get_connected_stream_ip [hsi::get_cells -hier $axis_subset_inip] "S_AXIS"]
		if {[llength $axis_subset_inip]} {
			set axis_subset_inip_name [hsi get_property IP_NAME $axis_subset_inip]
		}
		if {[llength $axis_subset_inip]} {
		}
	}

	if {[llength $axis_subset_inip] && [string match -nocase [hsi get_property IP_NAME $axis_subset_inip] "mipi_csi2_rx_subsystem"]} {
		set port0_node [create_node -n "port" -l axis_subset_port0$axis_subset_inip -u 0 -p $ports_node -d $dts_file]
		add_prop "$port0_node" "reg" 0 int $dts_file
		add_prop "$port0_node" "xlnx,video-format" 12 int $dts_file
		set subset_sink_node [create_node -n "endpoint" -l $drv_handle$axis_subset_inip -p $port0_node -d $dts_file]
		add_prop "$subset_sink_node" "remote-endpoint" $axis_subset_inip$drv_handle reference $dts_file
	}

        set port_node [create_node -n "port" -l axis_subset_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
        add_prop "$port_node" "reg" 1 int $dts_file
        add_prop "$port_node" "xlnx,video-format" 12 int $dts_file
	set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_video"]
	if {[llength $outip]} {
		set outip_name [hsi get_property IP_NAME $outip]
	} else {
	}
	set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set inip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
	if {[llength $inip]} {
		set inip_name [hsi get_property IP_NAME $inip]
	} else {
	}
		if {[llength $ip]} {
			set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi::get_mem_ranges $ip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
				set subset_node [create_node -n "endpoint" -l subset_out$drv_handle -p $port_node -d $dts_file]
				gen_endpoint $drv_handle "subset_out$drv_handle"
				add_prop "$subset_node" "remote-endpoint" $drv_handle reference $dts_file
				gen_remoteendpoint $drv_handle "$ip$drv_handle"
				if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"]} {
					# Skip vcap node creation - let v_frmbuf_wr handle it
					# axis_subset_gen_frmbuf_wr_node $ip $drv_handle $dts_file
				}
			} else {
				if {[string match -nocase [hsi get_property IP_NAME $ip] "system_ila"]} {
					continue
				}
			}
			set connectip [get_connect_ip $ip $master_intf $dts_file]
			if {[llength $connectip]} {
				set connectip_name [hsi get_property IP_NAME $connectip]
			} else {
			}
			if {[llength $connectip]} {
				#to handle scaler subsystem IP
				set sub_set_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
				set subset_node [create_node -n "endpoint" -l $drv_handle$connectip -p $port_node -d $dts_file]
				gen_endpoint $drv_handle "subset_out$drv_handle"
				if {[string match -nocase [hsi get_property IP_NAME $sub_set_inip] "v_proc_ss"]} {
					dtg_warning "$drv_handle scaler sub-core use case skipped.!"
				#	add_prop "$subset_node" "remote-endpoint" "" reference $dts_file
					return
				}
			if {[string match -nocase [hsi get_property IP_NAME $connectip] "ISPPipeline_accel"]} {
				add_prop "$subset_node" "remote-endpoint" isppipeline_in$connectip reference $dts_file
				gen_remoteendpoint $drv_handle "isppipeline_in$connectip"
			} elseif {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_switch"]} {
				set axis_switch_inips [get_axis_switch_in_connect_ip $connectip "S00_AXIS"]
				if {[llength $axis_switch_inips]} {
					add_prop "$subset_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
					gen_axis_switch_in_endpoint $drv_handle "$drv_handle$connectip"
					gen_axis_switch_in_remo_endpoint $drv_handle "$connectip$drv_handle"
					gen_remoteendpoint $drv_handle "$connectip$drv_handle"
				} else {
				}
			} elseif {[string match -nocase [hsi get_property IP_NAME $connectip] "v_proc_ss"]} {
				# v_proc_ss should handle its own endpoint creation, just register in mappings
				gen_remoteendpoint $drv_handle "v_proc_ss$drv_handle"
			} elseif {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
				# v_frmbuf_wr is DMA endpoint, skip remote-endpoint
				gen_remoteendpoint $drv_handle "$connectip$drv_handle"
			} else {
				global end_mappings
				set has_remote 0
				if {[info exists end_mappings] && [dict exists $end_mappings $connectip]} {
					set remote_end [dict get $end_mappings $connectip]
					add_prop "$subset_node" "remote-endpoint" $remote_end reference $dts_file
					set has_remote 1
				}
				if {!$has_remote} {
				}
				gen_remoteendpoint $drv_handle "$connectip$drv_handle"
			}
				if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
					# Skip vcap node creation - let v_frmbuf_wr handle it
					# axis_subset_gen_frmbuf_wr_node $connectip $drv_handle $dts_file
				}
			}
		} else {
			dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
	}
}

proc axis_subset_converter_update_endpoints {drv_handle} {
        set ip $drv_handle
	set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        set axis_subset_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
        set subset_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
	if {[llength $axis_subset_inip]} {
		set axis_subset_inip_name [hsi get_property IP_NAME $axis_subset_inip]
	} else {
	}
	if {[llength $subset_inip]} {
		set subset_inip_name [hsi get_property IP_NAME $subset_inip]
	} else {
	}

        if {[string_is_empty $node]} {
                return
        }

	# Check if port0 was already created in generate phase (for MIPI case)
	set axis_subset_inip_check [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]

	# Skip over axis_data_fifo to find real source
	while {[llength $axis_subset_inip_check] && [string match -nocase [hsi get_property IP_NAME $axis_subset_inip_check] "axis_data_fifo"]} {
		set axis_subset_inip_check [get_connected_stream_ip [hsi::get_cells -hier $axis_subset_inip_check] "S_AXIS"]
		if {[llength $axis_subset_inip_check]} {
			set axis_subset_inip_check_name [hsi get_property IP_NAME $axis_subset_inip_check]
		}
	}

	if {[llength $axis_subset_inip_check]} {
	}
	if {[llength $axis_subset_inip_check] && [string match -nocase [hsi get_property IP_NAME $axis_subset_inip_check] "mipi_csi2_rx_subsystem"]} {
		# Check if MIPI created its ports node - if not, create it now
		set mipi_node [get_node $axis_subset_inip_check]
		if {$mipi_node != 0} {
			set mipi_children [pldt children $mipi_node]
			set mipi_has_ports 0
			foreach child $mipi_children {
				if {[string match "*ports*" $child]} {
					set mipi_has_ports 1
					break
				}
			}
			if {!$mipi_has_ports} {
				set mipi_ports [create_node -n "ports" -l csirx_ports$axis_subset_inip_check -p $mipi_node -d $dts_file]
				add_prop "$mipi_ports" "#address-cells" 1 int $dts_file
				add_prop "$mipi_ports" "#size-cells" 0 int $dts_file
				set mipi_port [create_node -n "port" -l csirx_out_port$axis_subset_inip_check -u 1 -p $mipi_ports -d $dts_file]
				add_prop "$mipi_port" "reg" 1 int $dts_file
				set mipi_endpoint [create_node -n "endpoint" -l $axis_subset_inip_check$drv_handle -p $mipi_port -d $dts_file]
				add_prop "$mipi_endpoint" "remote-endpoint" $drv_handle$axis_subset_inip_check reference $dts_file
			}
		}
		# port0 already created in generate phase, skip rest of update_endpoints
		return
	}

	global end_mappings
	global remo_mappings

	set ports_node [create_node -n "ports" -l axis_subset_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
        set len [llength $axis_subset_inip]
	global port1_broad_end_mappings
	if {$len > 1} {
		for {set i 0 } {$i < $len} {incr i} {
			set temp_ip [lindex $axis_subset_inip $i]
			if {[regexp -nocase "ila" $temp_ip match]} {
				continue
			}
			set axis_subset_inip "$temp_ip"
		}
	}

	if {[string_is_empty $axis_subset_inip]} {
		return
	}
	set port0_node [create_node -n "port" -l axis_subset_port0$axis_subset_inip -u 0 -p $ports_node -d $dts_file]
	add_prop "$port0_node" "reg" 0 int $dts_file
	add_prop "$port0_node" "xlnx,video-format" 12 int $dts_file
	if {[string match -nocase [hsi get_property IP_NAME $axis_subset_inip] "mipi_csi2_rx_subsystem"]} {
		# MIPI endpoint already created in generate phase, skip the generic endpoint creation below
		return
	}
		set effective_inip $subset_inip
		if {![llength $effective_inip]} {
			set effective_inip $axis_subset_inip
		}
		if {![llength $effective_inip]} {
			dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected..check your design"
		} else {
			set master_intf [hsi::get_intf_pins -of_objects [hsi get_cells -hier $effective_inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
			set inip [get_in_connect_ip $effective_inip $master_intf]
			if {![llength $inip]} {
				set inip $effective_inip
			}
			if {[llength $inip]} {
				set has_map 0
				if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
					set has_map 1
				}
				if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
					set has_map 1
				}
				if {!$has_map && [llength $effective_inip]} {
					if {[info exists end_mappings] && [dict exists $end_mappings $effective_inip]} {
						set inip $effective_inip
						set has_map 1
					}
					if {!$has_map && [info exists remo_mappings] && [dict exists $remo_mappings $effective_inip]} {
						set inip $effective_inip
					}
				}
			}
		if {[llength $inip]} {
			set inip_name [hsi get_property IP_NAME $inip]
			set subset_in_end ""
			set subset_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				set subset_in_end [dict get $end_mappings $inip]
			}
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				set subset_remo_in_end [dict get $remo_mappings $inip]
			}
			if {[llength $subset_remo_in_end]} {
				set subset_node [create_node -n "endpoint" -l $subset_remo_in_end -p $port0_node -d $dts_file]
			}
			if {[llength $subset_in_end]} {
				add_prop "$subset_node" "remote-endpoint" $subset_in_end reference $dts_file
			} elseif {![llength $subset_remo_in_end]} {
				set fallback_label "$inip$drv_handle"
				set has_endpoint 0
				foreach child [pldt children $port0_node] {
					if {[string match "*endpoint*" $child]} {
						set has_endpoint 1
						break
					}
				}
				if {!$has_endpoint} {
					set subset_node [create_node -n "endpoint" -l $fallback_label -p $port0_node -d $dts_file]
				}
			}
		}
	}
}

proc axis_subset_gen_frmbuf_wr_node {outip drv_handle dts_file} {
	set bus_node [detect_bus_name $drv_handle]
	set vcap [create_node -n "vcap_$drv_handle" -p $bus_node -d $dts_file]
	add_prop $vcap "compatible" "xlnx,video" string $dts_file
	add_prop $vcap "dmas" "$outip 0" reference $dts_file
	add_prop $vcap "dma-names" "port0" string $dts_file
	set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dts_file]
	add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
	add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
	set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
	add_prop "$vcap_port_node" "reg" 0 int $dts_file
	add_prop "$vcap_port_node" "direction" input string $dts_file

	# Get the input IP to axis_subset_converter
	set inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
	if {[llength $inip] == 0} {
		set inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
	}

	set vcap_in_node [create_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node -d $dts_file]

	# Try to get the endpoint from the input IP
	global end_mappings
	if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
		set remote_end [dict get $end_mappings $inip]
		add_prop "$vcap_in_node" "remote-endpoint" $remote_end reference $dts_file
	} else {
		# Fallback to direct connection pattern
		add_prop "$vcap_in_node" "remote-endpoint" $inip$drv_handle reference $dts_file
	}
	gen_remoteendpoint $drv_handle "$outip$drv_handle"
}
