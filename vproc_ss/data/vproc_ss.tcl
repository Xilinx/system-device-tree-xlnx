#
# (C) Copyright 2018-2022 Xilinx, Inc.
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

proc vproc_ss_generate {drv_handle} {
	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	global end_mappings
	global remo_mappings
	set dts_file [set_drv_def_dts $drv_handle]
	set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
	vproc_ss_add_hier_instances $drv_handle

	set p_highaddress [hsi get_property CONFIG.C_HIGHADDR [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" [format %08x $p_highaddress] hexint $dts_file

	if {$topology == 0} {
		#scaler
		set name [hsi get_property NAME [hsi::get_cells -hier $drv_handle]]
		pldt append $node compatible "\ \, \"xlnx,v-vpss-scaler-2.2\""
		set ip [hsi::get_cells -hier $drv_handle]
		set csc_enable_window [hsi get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
		set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set v_scaler_phases [hsi get_property CONFIG.C_V_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int $dts_file
		set interlace [hsi get_property CONFIG.C_ENABLE_INTERLACED [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,enable-interlaced" $interlace boolean $dts_file
		set v_scaler_taps [hsi get_property CONFIG.C_V_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int $dts_file
		add_prop "${node}" "xlnx,num-vert-taps" $v_scaler_taps int $dts_file
		set madi [hsi get_property CONFIG.C_DEINT_MOTION_ADAPTIVE [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,deint-motion-adaptive" $madi boolean $dts_file
		set csc_enable_422 [hsi get_property CONFIG.C_CSC_ENABLE_422 [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-422" $csc_enable_422 string $dts_file
		set h_scaler_phases [hsi get_property CONFIG.C_H_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,h-scaler-phases" $h_scaler_phases int $dts_file
		add_prop "${node}" "xlnx,max-num-phases" $h_scaler_phases int $dts_file
		set h_scaler_taps [hsi get_property CONFIG.C_H_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,h-scaler-taps" $h_scaler_taps int $dts_file
		add_prop "${node}" "xlnx,num-hori-taps" $h_scaler_taps int $dts_file
		set max_cols [hsi get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
		set max_rows [hsi get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
		set max_cols [hsi get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-cols" $max_cols int $dts_file
		set max_rows [hsi get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-rows" $max_rows int $dts_file
		set samples_per_clk [hsi get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
		add_prop "${node}" "xlnx,pix-per-clk" $samples_per_clk int $dts_file
		set scaler_algo [hsi get_property CONFIG.C_SCALER_ALGORITHM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,scaler-algorithm" $scaler_algo int $dts_file
		set enable_csc [hsi get_property CONFIG.C_ENABLE_CSC [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,enable-csc" $enable_csc string $dts_file
		set color_support [hsi get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
		set use_uram [hsi get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
		set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file

		set ports_node [create_node -n "ports" -l scaler_ports$drv_handle -p $node -d $dts_file]
		add_prop "$ports_node" "#address-cells" 1 int $dts_file
		add_prop "$ports_node" "#size-cells" 0 int $dts_file
		set port1_node [create_node -n "port" -l scaler_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
		# add_prop "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
		add_prop "$port1_node" "reg" 1 int $dts_file
		add_prop "$port1_node" "xlnx,video-format" 3 int $dts_file
		add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file
		set scaoutip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis"]
		if {[llength $scaoutip]} {
			if {[string match -nocase [hsi::get_property IP_NAME $scaoutip] "axis_broadcaster"]} {
				set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
				gen_endpoint $drv_handle "sca_out$drv_handle"
				add_prop "$sca_node" "remote-endpoint" $scaoutip$drv_handle reference $dts_file
				gen_remoteendpoint $drv_handle "$scaoutip$drv_handle"
			}
		}

		foreach outip $scaoutip {
			if {[llength $outip]} {
					if {[string match -nocase [hsi::get_property IP_NAME $outip] "system_ila"]} {
						continue
					}
				set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set ip_mem_handles [hsi::get_mem_ranges $outip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
					set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
					gen_endpoint $drv_handle "sca_out$drv_handle"
					if {[string match -nocase [hsi::get_property IP_NAME $outip] "v_mix"]} {
						add_prop "$sca_node" "remote-endpoint" "mixer_crtc$outip" reference $dts_file
					} else {
						add_prop "$sca_node" "remote-endpoint" $outip$drv_handle reference $dts_file
					}
					gen_remoteendpoint $drv_handle "$outip$drv_handle"
					if {[string match -nocase [hsi::get_property IP_NAME $outip] "v_frmbuf_wr"] \
					    || [string match -nocase [hsi::get_property IP_NAME $outip] "axi_vdma"]} {
						vpss_gen_sca_frm_buf_node $outip $drv_handle $dts_file
					}
				} else {
					set connectip [get_connect_ip $outip $master_intf $dts_file]
					if {[llength $connectip]} {
						set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
						gen_endpoint $drv_handle "sca_out$drv_handle"
						add_prop "$sca_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
						gen_remoteendpoint $drv_handle "$connectip$drv_handle"
						if {[string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_wr"] \
						    || [string match -nocase [hsi::get_property IP_NAME $connectip] "axi_vdma"]} {
							vpss_gen_sca_frm_buf_node $connectip $drv_handle $dts_file
						}
					}
				}
			} else {
				dtg_warning "$drv_handle pin m_axis is not connected..check your design"
			}
		}
		vproc_ss_gen_gpio_reset $drv_handle $node $topology $dts_file
	}

	if {$topology == 3} {
		#CSC
		set name [hsi::get_property NAME [hsi::get_cells -hier $drv_handle]]
		set compatible [get_comp_str $drv_handle]
		pldt append $node compatible "\ \, \"xlnx,v-vpss-csc\""
		#set compatible [append compatible " " "xlnx,vpss-csc xlnx,v-vpss-csc"]
		set ip [hsi::get_cells -hier $drv_handle]
		set topology [hsi::get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set color_support [hsi::get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
		set csc_enable_window [hsi::get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
		set max_cols [hsi::get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
		set max_data_width [hsi::get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
		set max_rows [hsi::get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
		set num_video_comp [hsi::get_property CONFIG.C_NUM_VIDEO_COMPONENTS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,num-video-components" $num_video_comp int $dts_file
		set samples_per_clk [hsi::get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
		set topology [hsi::get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set use_uram [hsi::get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file

		set ports_node [create_node -n "ports" -l csc_ports$drv_handle -p $node -d $dts_file]
		add_prop "$ports_node" "#address-cells" 1 int $dts_file
		add_prop "$ports_node" "#size-cells" 0 int $dts_file
		set port1_node [create_node -n "port" -l csc_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
		# add_prop "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
		add_prop "$port1_node" "reg" 1 int $dts_file
		add_prop "$port1_node" "xlnx,video-format" 3 int $dts_file
		add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file
		set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis"]
		if {[llength $outip]} {
			if {[string match -nocase [hsi::get_property IP_NAME $outip] "axis_broadcaster"]} {
				set csc_node [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
				gen_endpoint $drv_handle "csc_out$drv_handle"
				add_prop "$csc_node" "remote-endpoint" $outip$drv_handle reference $dts_file
				gen_remoteendpoint $drv_handle "$outip$drv_handle"
			}
		}

		foreach ip $outip {
			if {[llength $ip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
				set ip_mem_handles [hsi::get_mem_ranges $ip]
				if {[llength $ip_mem_handles]} {
				set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
				set cscoutnode [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
				gen_endpoint $drv_handle "csc_out$drv_handle"
				add_prop "$cscoutnode" "remote-endpoint" $ip$drv_handle reference $dts_file
				gen_remoteendpoint $drv_handle "$ip$drv_handle"
				if {[string match -nocase [hsi::get_property IP_NAME $ip] "v_frmbuf_wr"] \
				|| [string match -nocase [hsi::get_property IP_NAME $ip] "axi_vdma"]} {
				vpss_gen_csc_frm_buf_node $ip $drv_handle $dts_file
				}
				} else {
				if {[string match -nocase [hsi::get_property IP_NAME $ip] "system_ila"]} {
				continue
				}
				set connectip [get_connect_ip $ip $master_intf $dts_file]
				if {[llength $connectip]} {
				set cscoutnode [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
				gen_endpoint $drv_handle "csc_out$drv_handle"
				add_prop "$cscoutnode" "remote-endpoint" $connectip$drv_handle reference $dts_file
				gen_remoteendpoint $drv_handle "$connectip$drv_handle"
				if {[string match -nocase [hsi::get_property IP_NAME $connectip] "v_frmbuf_wr"] \
				   || [string match -nocase [hsi::get_property IP_NAME $ip] "axi_vdma"]} {
				   vpss_gen_csc_frm_buf_node $connectip $drv_handle $dts_file
				}
				}
				}
				} else {
			dtg_warning "$drv_handle pin m_axis is not connected..check your design"
			}
		}

		vproc_ss_gen_gpio_reset $drv_handle $node $topology $dts_file
		}
}

proc vproc_ss_update_endpoints {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {[string_is_empty $node]} {
		return
	}

	global end_mappings
	global remo_mappings
	global set port1_broad_end_mappings
	global set port2_broad_end_mappings
	global set port3_broad_end_mappings
	global set port4_broad_end_mappings
	global set port5_broad_end_mappings
	global set port6_broad_end_mappings
	global set broad_port1_remo_mappings
	global set broad_port2_remo_mappings
	global set broad_port3_remo_mappings
	global set broad_port4_remo_mappings


	set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]

	if {$topology == 0} {
		set ports_node [create_node -n "ports" -l scaler_ports$drv_handle -p $node -d $dts_file]
		set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		set port_node [create_node -n "port" -l scaler_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		add_prop "$port_node" "xlnx,video-format" 3 int $dts_file
		add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
		set scaninip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis"]
		if {[llength $scaninip] && \
		    [string match -nocase [hsi::get_property IP_NAME $scaninip] "axis_switch"]} {
			set axis_node [create_node -n "endpoint" -l $drv_handle$scaninip -p $port_node -d $dts_file]
			add_prop "$axis_node" "remote-endpoint" axis_switch_out1$scaninip reference $dts_file
		}
		# Get next IN IP if axis_slice connected
		if {[llength "$scaninip"] && \
		    [string match -nocase [hsi::get_property IP_NAME $scaninip] "axis_register_slice"]} {
			set intf "S_AXIS"
			set scaninip [get_connected_stream_ip [hsi::get_cells -hier $scaninip] "$intf"]
		}
		foreach inip $scaninip {
			if {[llength $inip]} {
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "ISPPipeline_accel"]} {
					set port0_node [create_node -n "endpoint" -l v_proc_ss$inip -p $port_node -d $dts_file]
					add_prop "$port0_node" "remote-endpoint" $inip$drv_handle reference $dts_file
				}
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {![llength $ip_mem_handles]} {
					# Add endpoints if IN IP is axis_switch and non memory mapped
					if {[string match -nocase [hsi get_property IP_NAME $inip] "axis_switch"]} {
						update_axis_switch_endpoints $inip $port_node $drv_handle
					}
					set broad_ip [get_broad_in_ip $inip]
					if {[llength $broad_ip]} {
						if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
							set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set intlen [llength $master_intf]
							set sca_in_end ""
							set sca_remo_in_end ""
							set sca_remo_in1_end ""
							set sca_remo_in2_end ""
							set sca_remo_in3_end ""
							switch $intlen {
								"1" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
										dtg_verbose "sca_in_end:$sca_in_end"
									}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
										dtg_verbose "drv:$drv_handle inremoend:$sca_remo_in_end"
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
										if {[llength $sca_remo_in_end]} {
											set sca_node [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
										}
										if {[llength $sca_in_end]} {
											add_prop "$sca_node" "remote-endpoint" $sca_in_end reference $dts_file
										}
									}
								}
								"2" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
									}
									if {[info exists port1_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
										set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
										set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
										if {[llength $sca_remo_in_end]} {
											set sca_node [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
										}
										if {[llength $sca_in_end]} {
											add_prop "$sca_node" "remote-endpoint" $sca_in_end reference $dts_file
										}
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in1_end" match]} {
										if {[llength $sca_remo_in1_end]} {
											set sca_node [create_node -n "endpoint" -l $sca_remo_in1_end -p $port_node -d $dts_file]
										}
										if {[llength $sca_in1_end]} {
											add_prop "$sca_node" "remote-endpoint" $sca_in1_end reference $dts_file
										}
									}
								}
								"3" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
									}
									if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
										set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
										set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
									}
									if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
										set sca_in2_end [dict get $port3_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
										set sca_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
										if {[llength $sca_remo_in_end]} {
											set sca_node [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
										}
										if {[llength $sca_in_end]} {
											add_prop "$sca_node" "remote-endpoint" $sca_in_end reference $dts_file
										}
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in1_end" match]} {
										if {[llength $sca_remo_in1_end]} {
											set sca_node [create_node -n "endpoint" -l $sca_remo_in1_end -p $port_node -d $dts_file]
										}
										if {[llength $sca_in1_end]} {
											add_prop "$sca_node" "remote-endpoint" $sca_in1_end reference $dts_file
										}
									}
									if {[regexp -nocase $drv_handle "$sca_remo_in2_end" match]} {
										if {[llength $sca_remo_in2_end]} {
											set sca_node [create_node -n "endpoint" -l $sca_remo_in2_end -p $port_node -d $dts_file]
										}
										if {[llength $sca_in2_end]} {
											add_prop "$sca_node" "remote-endpoint" $sca_in2_end reference $dts_file
										}
									}
								}
								"4" {
									if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
										set sca_in_end [dict get $port1_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
										set sca_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
									}
									if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
										set sca_in1_end [dict get $port2_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
										set sca_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
									}
									if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
										set sca_in2_end [dict get $port3_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
										set sca_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
									}
									if {[info exists port4_broad_end_mappings] && [dict exists $port4_broad_end_mappings $broad_ip]} {
										set sca_in3_end [dict get $port4_broad_end_mappings $broad_ip]
									}
									if {[info exists broad_port4_remo_mappings] && [dict exists $broad_port4_remo_mappings $broad_ip]} {
										set sca_remo_in3_end [dict get $broad_port4_remo_mappings $broad_ip]
									}
								}
							}
							return
						}
					}
				}
			}
		}

		foreach inip $scaninip {
			if {[llength $inip]} {
				if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
					continue
				}
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
				} else {
					set inip [get_in_connect_ip $inip $master_intf]
					if {[llength $inip]} {
						if {[string match -nocase [hsi get_property IP_NAME $inip] "axi_vdma"]} {
							gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
						}
					}
				}
				if {[llength $inip]} {
					set sca_in_end ""
					set sca_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set sca_in_end [dict get $end_mappings $inip]
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set sca_remo_in_end [dict get $remo_mappings $inip]
					}
					if {[llength $sca_remo_in_end]} {
						set scainnode [create_node -n "endpoint" -l $sca_remo_in_end -p $port_node -d $dts_file]
					}
					if {[llength $sca_in_end]} {
					add_prop "$scainnode" "remote-endpoint" $sca_in_end reference $dts_file
					}
				}
			} else {
				dtg_warning "$drv_handle pin s_axis is not connected..check your design"
			}
		}
	}

	if {$topology == 3} {
		set ports_node [create_node -n "ports" -l csc_ports$drv_handle -p $node -d $dts_file]
		add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
		add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
		set port_node [create_node -n "port" -l csc_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		add_prop "$port_node" "xlnx,video-format" 3 int $dts_file
		set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
		set cscinip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis"]
		if {[llength $cscinip]} {
			foreach inip $cscinip {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
					}
				} else {
					set inip [get_in_connect_ip $inip $master_intf]
					if {[llength $inip]} {
						if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
							continue
						}
						if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
							gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
						}
					}
				}
				if {[llength $inip]} {
					set csc_in_end ""
					set csc_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set csc_in_end [dict get $end_mappings $inip]
						dtg_verbose "drv:$drv_handle inend:$csc_in_end"
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set csc_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "drv:$drv_handle inremoend:$csc_remo_in_end"
					}
					if {[llength $csc_remo_in_end]} {
						set cscinnode [create_node -n "endpoint" -l $csc_remo_in_end -p $port_node -d $dts_file]
					}
					if {[llength $csc_in_end]} {
						add_prop "$cscinnode" "remote-endpoint" $csc_in_end reference $dts_file
					}
				}
			}
		} else {
			dtg_warning "$drv_handle pin s_axis is not connected..check your design"
		}
	}
	if {($topology == 1) || ($topology ==2) || ($topology == 4) || ($topology ==5) || ($topology ==6)} {
		puts "$drv_handle Printing remote endpoint in case of VPSS in FF only to validate Baremetal cases"
		set ports_node [create_node -n "ports" -l vpss_ports$drv_handle -p $node -d $dts_file]
		set port_node [create_node -n "port" -l vpss_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		set vpssinip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis"]
		if {[llength $vpssinip]} {
			foreach inip $vpssinip {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						#not useful in baremetal case
					#	gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
					}
				} else {
					set inip [get_in_connect_ip $inip $master_intf]
					if {[llength $inip]} {
						if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
							continue
						}
						if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						#not useful in baremetal case
						#	gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
						}
					}
				}
			}
		}
		if {[llength $inip]} {
			set vpss_in_end ""
			set vpss_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
				set vpss_in_end [dict get $end_mappings $inip]
				dtg_verbose "drv:$drv_handle inend:$vpss_in_end"
			}
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
				set vpss_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "drv:$drv_handle inremoend:$vpss_remo_in_end"
			}
			if {[llength $vpss_remo_in_end]} {
				set vpssinnode [create_node -n "endpoint" -l $vpss_remo_in_end -p $port_node -d $dts_file]
			}
			if {[llength $vpss_in_end]} {
				add_prop "$vpssinnode" "remote-endpoint" $vpss_in_end reference $dts_file
			}
		}
	}  else {
		dtg_warning "$drv_handle unsupportedd topology for linux driver"
	}
}

proc vproc_ss_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set family [get_hw_family]
	if {$family in {"microblaze" "Zynq"}} {
		set bit_format 32
	} else {
		set bit_format 64
	}

	set ip_subcores [dict create]
	dict set ip_subcores "axi_vdma" "vdma"
	dict set ip_subcores "axis_switch" "router"
	dict set ip_subcores "v_csc" "csc"
	dict set ip_subcores "v_deinterlacer" "deint"
	dict set ip_subcores "v_hcresampler" "hcrsmplr"
	dict set ip_subcores "v_hscaler" "hscale"
	dict set ip_subcores "v_letterbox" "lbox"
	dict set ip_subcores "v_vscaler" "vscale"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
			set connected_node [get_node $ip_handle]
			set subsys_base [get_baseaddr $drv_handle]
			set subcore_base [get_baseaddr $ip_handle]
			set subcore_abs_base [format 0x%lx [expr $subsys_base+$subcore_base]]
			set subcore_base_high [get_highaddr $ip_handle]
			set subcore_abs_high [format 0x%lx [expr $subsys_base+$subcore_base_high]]
			set subcore_reg_val [gen_reg_property_format $subcore_abs_base $subcore_abs_high $bit_format]
			add_prop $connected_node reg "$subcore_reg_val" hexlist $dts_file 1
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

	set gpios [set_ip_handles_for_ss_subcores axi_gpio $drv_handle]
	if {[string_is_empty $gpios]} {
		add_prop "$node" "rstaxis-present" 0 int $dts_file
		add_prop "$node" "rstaximm-present" 0 int $dts_file
	} else {
		foreach gpio $gpios {
			set name [hsi get_property NAME [hsi::get_cells -hier $gpio]]
			if {[regexp ".axis" $name match]} {
				add_prop "$node" "rstaxis-present" 1 int $dts_file 1
				add_prop "$node" "rstaxis-connected" $gpio reference $dts_file 1
			}

			if {[regexp ".axi_mm" $name match]} {
				add_prop "$node" "rstaximm-present" 1 int $dts_file 1
				add_prop "$node" "rstaximm-connected" $gpio reference $dts_file 1
			}
			set connected_node [get_node $gpio]
			set subsys_base [get_baseaddr $drv_handle]
			set subcore_base [get_baseaddr $gpio]
			set subcore_abs_base [format 0x%lx [expr $subsys_base+$subcore_base]]
			set subcore_base_high [get_highaddr $gpio]
			set subcore_abs_high [format 0x%lx [expr $subsys_base+$subcore_base_high]]
			set subcore_reg_val [gen_reg_property_format $subcore_abs_base $subcore_abs_high $bit_format]
			add_prop $connected_node reg "$subcore_reg_val" hexlist $dts_file 1
		}
	}

	set vcrs [set_ip_handles_for_ss_subcores v_vcresampler $drv_handle]
	foreach vcr $vcrs {
		set name [hsi get_property NAME [hsi::get_cells -hier $vcr]]
		if {[regexp "._o" $name match]} {
			add_prop "$node" "vcrsmplrout-present" 1 int $dts_file
			add_prop "$node" "vcrsmplrout-present" 1 int $dts_file
			add_prop "$node" "vcrsmplrout-connected" $vcr reference $dts_file
		}

		if {[regexp "._i" $name match]} {
			add_prop "$node" "vcrsmplrin-present" 1 int $dts_file
			add_prop "$node" "vcrsmplrin-connected" $vcr reference $dts_file
		}
		set connected_node [get_node $vcr]
		set subsys_base [get_baseaddr $drv_handle]
		set subcore_base [get_baseaddr $vcr]
		set subcore_abs_base [format 0x%lx [expr $subsys_base+$subcore_base]]
		set subcore_base_high [get_highaddr $vcr]
		set subcore_abs_high [format 0x%lx [expr $subsys_base+$subcore_base_high]]
		set subcore_reg_val [gen_reg_property_format $subcore_abs_base $subcore_abs_high $bit_format]
		add_prop $connected_node reg "$subcore_reg_val" hexlist $dts_file 1
	}
}

proc vproc_ss_gen_gpio_reset {drv_handle node topology dts_file} {
	if {$topology == 3} {
		set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "aresetn"]]
	}
	if {$topology == 0} {
		set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "aresetn_ctrl"]]
	}
	foreach pin $pins {
		set sink_periph [hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [hsi::get_property IP_NAME $sink_periph]
			if {[string match -nocase $sink_ip "axi_gpio"]} {
				add_prop "$node" "reset-gpios" "$sink_periph 0 1" reference $dts_file
			}
			if {$sink_ip in {"xlslice" "ilslice"}} {
				set gpio [hsi::get_property CONFIG.DIN_FROM $sink_periph]
				set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [hsi::get_cells -of_objects $pin]
					if {[llength $periph]} {
						set ip [hsi::get_property IP_NAME $periph]
						if { $ip in { "versal_cips" "ps_wizard" }} {
							# As versal has only bank0 for MIOs
							set gpio [expr $gpio + 26]
							add_prop "$node" "reset-gpios" "gpio0 $gpio 1" reference $dts_file
							break
						}
						if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
							set gpio [expr $gpio + 78]
							add_prop "$node" "reset-gpios" "gpio $gpio 1" reference $dts_file
							break
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							add_prop "$node" "reset-gpios" "$periph $gpio 1" reference $dts_file
						}
					} else {
					    dtg_warning "peripheral is NULL for the $pin $periph"
					}
				}
			}
		} else {
			dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
		}
	}
}

proc vpss_gen_sca_frm_buf_node {outip drv_handle dts_file} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
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
	set vcap_in_node [create_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node -d $dts_file]
	gen_endpoint $drv_handle "sca_out$drv_handle"
	add_prop "$vcap_in_node" "remote-endpoint" sca_out$drv_handle reference $dts_file
	gen_remoteendpoint $drv_handle "$outip$drv_handle"
}

proc vpss_gen_csc_frm_buf_node {outip drv_handle dts_file} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
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
	set vcap_in_node [create_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node -d $dts_file]
	gen_endpoint $drv_handle "csc_out$drv_handle"
	add_prop "$vcap_in_node" "remote-endpoint" csc_out$drv_handle reference $dts_file
	gen_remoteendpoint $drv_handle "$outip$drv_handle"
}
