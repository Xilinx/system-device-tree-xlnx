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

proc demosaic_generate {drv_handle} {
	global end_mappings
	global remo_mappings
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	set keyval [pldt append $node compatible "\ \, \"xlnx,v-demosaic\""]
	set s_axi_ctrl_addr_width [hsi get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int $dts_file
	set s_axi_ctrl_data_width [hsi get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int $dts_file
	set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	set max_rows [hsi get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
	set max_rows [hsi get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-width" $max_rows int $dts_file

	set ports_node [create_node -n "ports" -l demosaic_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
	set port1_node [create_node -n "port" -l demosaic_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
	add_prop "$port1_node" "reg" 1 int $dts_file 1

	set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_video"]
	if {[llength $outip]} {
		set outipname [hsi get_property IP_NAME $outip]
		set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_hdmi_txss1 v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
		if {[lsearch  -nocase $valid_mmip_list $outipname] >= 0} {
			foreach ip $outip {
				if {[llength $ip]} {
					set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
					set ip_mem_handles [hsi::get_mem_ranges $ip]
					if {[llength $ip_mem_handles]} {
						set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
						set demonode [create_node -n "endpoint" -l demo_out$drv_handle -p $port1_node -d $dts_file]
						gen_endpoint $drv_handle "demo_out$drv_handle"
						add_prop "$demonode" "remote-endpoint" $ip$drv_handle reference $dts_file
						gen_remoteendpoint $drv_handle "$ip$drv_handle"
						if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"]} {
							demosaic_gen_frmbuf_wr_node $ip $drv_handle $dts_file
						}
					} else {
						if {[string match -nocase [hsi get_property IP_NAME $ip] "system_ila"]} {
							continue
						}
						set connectip [get_connect_ip $ip $master_intf $dts_file]
						if {[llength $connectip]} {
							set demonode [create_node -n "endpoint" -l demo_out$drv_handle -p $port1_node -d $dts_file]
							gen_endpoint $drv_handle "demo_out$drv_handle"
							add_prop "$demonode" "remote-endpoint" $connectip$drv_handle reference $dts_file
							gen_remoteendpoint $drv_handle "$connectip$drv_handle"
							if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
								demosaic_gen_frmbuf_wr_node $connectip $drv_handle $dts_file
							}
						}
					}
				} else {
					dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
				}
			}
		}
		demosaic_gen_gpio_reset $drv_handle $node $dts_file
	}

}

proc demosaic_update_endpoints {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {[string_is_empty $node]} {
			return
	}

	global end_mappings
	global remo_mappings
	global port1_end_mappings
	global port2_end_mappings
	global port3_end_mappings
	global port4_end_mappings
	global axis_port1_remo_mappings
	global axis_port2_remo_mappings
	global axis_port3_remo_mappings
	global axis_port4_remo_mappings

	global port1_broad_end_mappings
	global broad_port1_remo_mappings
	global port2_broad_end_mappings
	global broad_port2_remo_mappings


	set ports_node [create_node -n "ports" -l demosaic_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1

	set port_node [create_node -n "port" -l demosaic_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
	add_prop "$port_node" "reg" 0 int $dts_file 1

	set demo_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
	set len [llength $demo_inip]
	if {$len > 1} {
		for {set i 0 } {$i < $len} {incr i} {
			set temp_ip [lindex $demo_inip $i]
			if {[regexp -nocase "ila" $temp_ip match]} {
				continue
			}
			set demo_inip "$temp_ip"
		}
	}

	foreach inip $demo_inip {
		if {[llength $inip]} {
			set ip_mem_handles [hsi::get_mem_ranges $inip]
			if {![llength $ip_mem_handles]} {
				set broad_ip [get_broad_in_ip $inip]
				if {[llength $broad_ip]} {
					if {[string match -nocase [hsi::get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
						set master_intf [hsi::get_intf_pins -of_objects [hsi get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
						set intlen [llength $master_intf]
						set mipi_in_end ""
						set mipi_remo_in_end ""
						switch $intlen {
							"1" {
								if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
									set mipi_in_end [dict get $port1_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
									set mipi_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
								}
								if {[info exists sca_remo_in_end] && [regexp -nocase $drv_handle "$sca_remo_in_end" match]} {
									if {[llength $mipi_remo_in_end]} {
										set mipi_node [create_node -n "endpoint" -l $mipi_remo_in_end -p $port_node -d $dts_file]
									}
									if {[llength $mipi_in_end]} {
										add_prop "$mipi_node" "remote-endpoint" $mipi_in_end reference $dts_file
						}
								}
							}
							"2" {
								if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
									set mipi_in_end [dict get $port1_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
									set mipi_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
								}
								if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
									set mipi_in1_end [dict get $port2_broad_end_mappings $broad_ip]
								}
								if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
									set mipi_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
								}
								if {[info exists mipi_remo_in_end] && [regexp -nocase $drv_handle "$mipi_remo_in_end" match]} {
									if {[llength $mipi_remo_in_end]} {
										set mipi_node [create_node -n "endpoint" -l $mipi_remo_in_end -p $port_node -d $dts_file]
									}
									if {[llength $mipi_in_end]} {
										add_prop "$mipi_node" "remote-endpoint" $mipi_in_end reference $dts_file
									}
								}
								if {[info exists mipi_remo_in1_end] && [regexp -nocase $drv_handle "$mipi_remo_in1_end" match]} {
									if {[llength $mipi_remo_in1_end]} {
										set mipi_node [create_node -n "endpoint" -l $mipi_remo_in1_end -p $port_node -d $dts_file]
									}
									if {[llength $mipi_in1_end]} {
										add_prop "$mipi_node" "remote-endpoint" $mipi_in1_end reference $dts_file
									}
								}
							}
						}
							return
					}
				}
			}
		}

		if {[llength $demo_inip]} {
			if {[string match -nocase [hsi::get_property IP_NAME $demo_inip] "axis_switch"]} {
				set ip_mem_handles [hsi::get_mem_ranges $demo_inip]
					if {![llength $ip_mem_handles]} {
						set demo_in_end ""
						set demo_remo_in_end ""
						if {[info exists port1_end_mappings] && [dict exists $port1_end_mappings $demo_inip]} {
						   set demo_in_end [dict get $port1_end_mappings $demo_inip]
						   dtg_verbose "demo_in_end:$demo_in_end"
						}
						if {[info exists axis_port1_remo_mappings] && [dict exists $axis_port1_remo_mappings $demo_inip]} {
						   set demo_remo_in_end [dict get $axis_port1_remo_mappings $demo_inip]
						   dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
						}
						if {[info exists port2_end_mappings] && [dict exists $port2_end_mappings $demo_inip]} {
						   set demo_in1_end [dict get $port2_end_mappings $demo_inip]
						   dtg_verbose "demo_in1_end:$demo_in1_end"
						}
						if {[info exists axis_port2_remo_mappings] && [dict exists $axis_port2_remo_mappings $demo_inip]} {
						   set demo_remo_in1_end [dict get $axis_port2_remo_mappings $demo_inip]
						   dtg_verbose "demo_remo_in1_end:$demo_remo_in1_end"
						}
						if {[info exists port3_end_mappings] && [dict exists $port3_end_mappings $demo_inip]} {
						   set demo_in2_end [dict get $port3_end_mappings $demo_inip]
						   dtg_verbose "demo_in2_end:$demo_in2_end"
						}
				if {[info exists axis_port3_remo_mappings] && [dict exists $axis_port3_remo_mappings $demo_inip]} {
						   set demo_remo_in2_end [dict get $axis_port3_remo_mappings $demo_inip]
						   dtg_verbose "demo_remo_in2_end:$demo_remo_in2_end"
						}
						if {[info exists port4_end_mappings] && [dict exists $port4_end_mappings $demo_inip]} {
						   set demo_in3_end [dict get $port4_end_mappings $demo_inip]
						   dtg_verbose "demo_in3_end:$demo_in3_end"
						}
						if {[info exists axis_port4_remo_mappings] && [dict exists $axis_port4_remo_mappings $demo_inip]} {
						   set demo_remo_in3_end [dict get $axis_port4_remo_mappings $demo_inip]
						   dtg_verbose "demo_remo_in3_end:$demo_remo_in3_end"
						}
						set drv [split $demo_remo_in_end "-"]
						set handle [lindex $drv 0]
						if {[info exists demo_remo_in_end] && [regexp -nocase $drv_handle "$demo_remo_in_end" match]} {
						   if {[llength $demo_remo_in_end]} {
							  set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
						   }
						   if {[llength $demo_in_end]} {
							  add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
						   }
						}

			if {[info exists demo_remo_in1_end] && [regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
				if {[llength $demo_remo_in1_end]} {
					set demosaic_node1 [create_node -n "endpoint" -l $demo_remo_in1_end -p $port_node -d $dts_file]
				}
				if {[llength $demo_in1_end]} {
					add_prop "$demosaic_node1" "remote-endpoint" $demo_in1_end reference $dts_file
				}
			}

			if {[info exists demo_remo_in2_end] && [regexp -nocase $drv_handle "$demo_remo_in2_end" match]} {
				if {[llength $demo_remo_in2_end]} {
					set demosaic_node2 [create_node -n "endpoint" -l $demo_remo_in2_end -p $port_node -d $dts_file]
				}
				if {[llength $demo_in2_end]} {
					add_prop "$demosaic_node2" "remote-endpoint" $demo_in2_end reference $dts_file
				}
			}

			if {[info exists demo_remo_in3_end] && [regexp -nocase $drv_handle "$demo_remo_in3_end" match]} {
				if {[llength $demo_remo_in3_end]} {
					set demosaic_node3 [create_node -n "endpoint" -l $demo_remo_in3_end -p $port_node -d $dts_file]
				}
				if {[llength $demo_in3_end]} {
					add_prop "$demosaic_node3" "remote-endpoint" $demo_in3_end reference $dts_file
				}
			}
			return
			} else {
				set demo_in_end ""
				set demo_remo_in_end ""
				if {[info exists axis_switch_port1_end_mappings] && [dict exists $axis_switch_port1_end_mappings $demo_inip]} {
					set demo_in_end [dict get $axis_switch_port1_end_mappings $demo_inip]
					dtg_verbose "demo_in_end:$demo_in_end"
				}
				if {[info exists axis_switch_port1_remo_mappings] && [dict exists $axis_switch_port1_remo_mappings $demo_inip]} {
					set demo_remo_in_end [dict get $axis_switch_port1_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
				}
				if {[info exists axis_switch_port2_end_mappings] && [dict exists $axis_switch_port2_end_mappings $demo_inip]} {
					set demo_in1_end [dict get $axis_switch_port2_end_mappings $demo_inip]
					dtg_verbose "demo_in1_end:$demo_in1_end"
				}
				if {[info exists axis_switch_port2_remo_mappings] && [dict exists $axis_switch_port2_remo_mappings $demo_inip]} {
					set demo_remo_in1_end [dict get $axis_switch_port2_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in1_end:$demo_remo_in1_end"
				}
				if {[info exists axis_switch_port3_end_mappings] && [dict exists $axis_switch_port3_end_mappings $demo_inip]} {
					set demo_in2_end [dict get $axis_switch_port3_end_mappings $demo_inip]
					dtg_verbose "demo_in2_end:$demo_in2_end"
				}
				if {[info exists axis_switch_port3_remo_mappings] && [dict exists $axis_switch_port3_remo_mappings $demo_inip]} {
					set demo_remo_in2_end [dict get $axis_switch_port3_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in2_end:$demo_remo_in2_end"
				}
				if {[info exists axis_switch_port4_end_mappings] && [dict exists $axis_switch_port4_end_mappings $demo_inip]} {
					set demo_in3_end [dict get $axis_switch_port4_end_mappings $demo_inip]
					dtg_verbose "demo_in3_end:$demo_in3_end"
				}
				if {[info exists axis_switch_port4_remo_mappings] && [dict exists $axis_switch_port4_remo_mappings $demo_inip]} {
					set demo_remo_in3_end [dict get $axis_switch_port4_remo_mappings $demo_inip]
					dtg_verbose "demo_remo_in3_end:$demo_remo_in3_end"
				}
				set drv [split $demo_remo_in_end "-"]
				set handle [lindex $drv 0]
				if {[regexp -nocase $drv_handle "$demo_remo_in_end" match]} {
					if {[llength $demo_remo_in_end]} {
						set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
					}
					if {[llength $demo_in_end]} {
						add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
					}
				}

				if {[regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
					if {[llength $demo_remo_in1_end]} {
						set demosaic_node1 [create_node -n "endpoint" -l $demo_remo_in1_end -p $port_node -d $dts_file]
					}
					if {[llength $demo_in1_end]} {
						add_prop "$demosaic_node1" "remote-endpoint" $demo_in1_end reference $dts_file
					}
				}
			}
		}
	}

		set inip ""
		if {[llength $demo_inip]} {
			foreach inip $demo_inip {
				set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
					if {[llength $ip_mem_handles]} {
						   set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
					} else {
							if {[string match -nocase [hsi::get_property IP_NAME $inip] "system_ila"]} {
								continue
							}
							set inip [get_in_connect_ip $inip $master_intf]
					}
					if {[llength $inip]} {
						set demo_in_end ""
						set demo_remo_in_end ""
						if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
							set demo_in_end [dict get $end_mappings $inip]
							}
						if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
							set demo_remo_in_end [dict get $remo_mappings $inip]
							}
						if {[llength $demo_remo_in_end]} {
							set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
							}
						if {[llength $demo_in_end]} {
							add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
							}
						}
					 }
		} else {
				dtg_warning "$drv_handle pin s_axis is not connected..check your design"
			   }
		}
	}

	proc demosaic_gen_frmbuf_wr_node {outip drv_handle dts_file} {
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
		set vcap_in_node [create_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node -d $dts_file]
		gen_endpoint $drv_handle "demo_out$drv_handle"
		add_prop "$vcap_in_node" "remote-endpoint" demo_out$drv_handle reference $dts_file
		gen_remoteendpoint $drv_handle "$outip$drv_handle"
	}

	proc demosaic_gen_gpio_reset {drv_handle node dts_file} {
		set dts_file [set_drv_def_dts $drv_handle]
		set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "ap_rst_n"]]
		foreach pin $pins {
			set sink_periph [hsi::get_cells -of_objects $pin]
			if {[llength $sink_periph]} {
				set sink_ip [hsi get_property IP_NAME $sink_periph]
				if {$sink_ip in {"xlslice" "ilslice"}} {
					set gpio [hsi get_property CONFIG.DIN_FROM $sink_periph]
					set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
					foreach pin $pins {
						set periph [hsi::get_cells -of_objects $pin]
						if {[llength $periph]} {
							set ip [hsi get_property IP_NAME $periph]
							if {[string match -nocase $ip "versal_cips"]} {
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
								dtg_warning "$drv_handle: peripheral is NULL for the $pin $periph"
						}
					}
				}
			# add reset-gpio pin when no slice is connected between v_tpg ip and axi_gpio ip
			set ip_name [hsi::get_property IP_NAME $sink_periph]
			if {[string match -nocase $ip_name "axi_gpio"]} {
				set gpio_number [hsi::get_property LEFT [hsi::get_pins -of_objects [hsi::get_cells -hier "$sink_periph"] "gpio_io_o" ]]
				add_prop "$node" "reset-gpios" "$sink_periph $gpio_number 1" reference $dts_file
			}
			} else {
				dtg_warning "$drv_handle: peripheral is NULL for the $pin $sink_periph"
			}
		}
	}
