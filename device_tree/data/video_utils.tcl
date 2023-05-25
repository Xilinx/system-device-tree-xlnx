#
# Copyright (C) 2023 Advanced Micro Devices, Inc.
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

package require Tcl 8.5.14

global set end_mappings [dict create]
global set remo_mappings [dict create]
global set port1_end_mappings [dict create]
global set port2_end_mappings [dict create]
global set port3_end_mappings [dict create]
global set port4_end_mappings [dict create]
global set axis_port1_remo_mappings [dict create]
global set axis_port2_remo_mappings [dict create]
global set axis_port3_remo_mappings [dict create]
global set axis_port4_remo_mappings [dict create]
global set port1_broad_end_mappings [dict create]
global set port2_broad_end_mappings [dict create]
global set port3_broad_end_mappings [dict create]
global set port4_broad_end_mappings [dict create]
global set port5_broad_end_mappings [dict create]
global set port6_broad_end_mappings [dict create]
global set broad_port1_remo_mappings [dict create]
global set broad_port2_remo_mappings [dict create]
global set broad_port3_remo_mappings [dict create]
global set broad_port4_remo_mappings [dict create]
global set broad_port5_remo_mappings [dict create]
global set broad_port6_remo_mappings [dict create]
global set axis_switch_in_end_mappings [dict create]
global set axis_switch_port1_end_mappings [dict create]
global set axis_switch_port2_end_mappings [dict create]
global set axis_switch_port3_end_mappings [dict create]
global set axis_switch_port4_end_mappings [dict create]
global set axis_switch_in_remo_mappings [dict create]
global set axis_switch_port1_remo_mappings [dict create]
global set axis_switch_port2_remo_mappings [dict create]
global set axis_switch_port3_remo_mappings [dict create]
global set axis_switch_port4_remo_mappings [dict create]

proc gen_endpoint {drv_handle value} {
        global end_mappings
        dict append end_mappings $drv_handle $value
        set val [dict get $end_mappings $drv_handle]
}

proc gen_axis_port1_endpoint {drv_handle value} {
       global port1_end_mappings
       dict append port1_end_mappings $drv_handle $value
       set val [dict get $port1_end_mappings $drv_handle]
}

proc gen_axis_port2_endpoint {drv_handle value} {
       global port2_end_mappings
       dict append port2_end_mappings $drv_handle $value
       set val [dict get $port2_end_mappings $drv_handle]
}

proc gen_axis_port3_endpoint {drv_handle value} {
       global port3_end_mappings
       dict append port3_end_mappings $drv_handle $value
       set val [dict get $port3_end_mappings $drv_handle]
}

proc gen_axis_port4_endpoint {drv_handle value} {
       global port4_end_mappings
       dict append port4_end_mappings $drv_handle $value
       set val [dict get $port4_end_mappings $drv_handle]
}

proc gen_axis_switch_in_endpoint {drv_handle value} {
       global axis_switch_in_end_mappings
       dict append axis_switch_in_end_mappings $drv_handle $value
       set val [dict get $axis_switch_in_end_mappings $drv_handle]
}

proc gen_axis_switch_in_remo_endpoint {drv_handle value} {
       global axis_switch_in_remo_mappings
       dict append axis_switch_in_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_in_remo_mappings $drv_handle]
}

proc gen_axis_switch_port1_endpoint {drv_handle value} {
       global axis_switch_port1_end_mappings
       dict append axis_switch_port1_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port1_end_mappings $drv_handle]
}

proc gen_axis_switch_port2_endpoint {drv_handle value} {
       global axis_switch_port2_end_mappings
       dict append axis_switch_port2_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port2_end_mappings $drv_handle]
}

proc gen_axis_switch_port3_endpoint {drv_handle value} {
       global axis_switch_port3_end_mappings
       dict append axis_switch_port3_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port3_end_mappings $drv_handle]
}

proc gen_axis_switch_port4_endpoint {drv_handle value} {
       global axis_switch_port4_end_mappings
       dict append axis_switch_port4_end_mappings $drv_handle $value
       set val [dict get $axis_switch_port4_end_mappings $drv_handle]
}

proc gen_axis_switch_port1_remote_endpoint {drv_handle value} {
       global axis_switch_port1_remo_mappings
       dict append axis_switch_port1_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port1_remo_mappings $drv_handle]
}

proc gen_axis_switch_port2_remote_endpoint {drv_handle value} {
       global axis_switch_port2_remo_mappings
       dict append axis_switch_port2_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port2_remo_mappings $drv_handle]
}

proc gen_axis_switch_port3_remote_endpoint {drv_handle value} {
       global axis_switch_port3_remo_mappings
       dict append axis_switch_port3_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port3_remo_mappings $drv_handle]
}

proc gen_axis_switch_port4_remote_endpoint {drv_handle value} {
       global axis_switch_port4_remo_mappings
       dict append axis_switch_port4_remo_mappings $drv_handle $value
       set val [dict get $axis_switch_port4_remo_mappings $drv_handle]
}

proc gen_broad_endpoint_port1 {drv_handle value} {
        global port1_broad_end_mappings
        dict append port1_broad_end_mappings $drv_handle $value
        set val [dict get $port1_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port2 {drv_handle value} {
        global port2_broad_end_mappings
        dict append port2_broad_end_mappings $drv_handle $value
        set val [dict get $port2_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port3 {drv_handle value} {
        global port3_broad_end_mappings
        dict append port3_broad_end_mappings $drv_handle $value
        set val [dict get $port3_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port4 {drv_handle value} {
        global port4_broad_end_mappings
        dict append port4_broad_end_mappings $drv_handle $value
        set val [dict get $port4_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port5 {drv_handle value} {
        global port5_broad_end_mappings
        dict append port5_broad_end_mappings $drv_handle $value
        set val [dict get $port5_broad_end_mappings $drv_handle]
}

proc gen_broad_endpoint_port6 {drv_handle value} {
        global port6_broad_end_mappings
        dict append port6_broad_end_mappings $drv_handle $value
        set val [dict get $port6_broad_end_mappings $drv_handle]
}

proc get_axis_switch_in_connect_ip {ip intfpins} {
       puts "get_axis_switch_in_connect_ip:$ip $intfpins"
       global connectip ""
       foreach intf $intfpins {
               set connectip [get_connected_stream_ip [hsi get_cells -hier $ip] $intf]
               puts "connectip:$connectip"
               foreach cip $connectip {
			if {[llength $cip]} {
				set ipname [hsi get_property IP_NAME $cip]
				puts "ipname:$ipname"
				set ip_mem_handles [get_ip_mem_ranges $cip]
				if {[llength $ip_mem_handles]} {
					break
				} else {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi get_cells -hier $cip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				get_axis_switch_in_connect_ip $cip $master_intf
				}
                       }
               }
       }
       return $connectip
}

proc gen_remoteendpoint {drv_handle value} {
        global remo_mappings
        dict append remo_mappings $drv_handle $value
        set val [dict get $remo_mappings $drv_handle]
}

proc gen_axis_port1_remoteendpoint {drv_handle value} {
       global axis_port1_remo_mappings
       dict append axis_port1_remo_mappings $drv_handle $value
       set val [dict get $axis_port1_remo_mappings $drv_handle]
}

proc gen_axis_port2_remoteendpoint {drv_handle value} {
       global axis_port2_remo_mappings
       dict append axis_port2_remo_mappings $drv_handle $value
       set val [dict get $axis_port2_remo_mappings $drv_handle]
}

proc gen_axis_port3_remoteendpoint {drv_handle value} {
       global axis_port3_remo_mappings
       dict append axis_port3_remo_mappings $drv_handle $value
       set val [dict get $axis_port3_remo_mappings $drv_handle]
}

proc gen_axis_port4_remoteendpoint {drv_handle value} {
       global axis_port4_remo_mappings
       dict append axis_port4_remo_mappings $drv_handle $value
       set val [dict get $axis_port4_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port1 {drv_handle value} {
        global broad_port1_remo_mappings
        dict append broad_port1_remo_mappings $drv_handle $value
        set val [dict get $broad_port1_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port2 {drv_handle value} {
        global broad_port2_remo_mappings
        dict append broad_port2_remo_mappings $drv_handle $value
        set val [dict get $broad_port2_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port3 {drv_handle value} {
        global broad_port3_remo_mappings
        dict append broad_port3_remo_mappings $drv_handle $value
        set val [dict get $broad_port3_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port4 {drv_handle value} {
        global broad_port4_remo_mappings
        dict append broad_port4_remo_mappings $drv_handle $value
        set val [dict get $broad_port4_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port5 {drv_handle value} {
        global broad_port5_remo_mappings
        dict append broad_port5_remo_mappings $drv_handle $value
        set val [dict get $broad_port5_remo_mappings $drv_handle]
}

proc gen_broad_remoteendpoint_port6 {drv_handle value} {
        global broad_port6_remo_mappings
        dict append broad_port6_remo_mappings $drv_handle $value
        set val [dict get $broad_port6_remo_mappings $drv_handle]
}

proc update_endpoints {drv_handle} {
        global end_mappings
        global remo_mappings
	global set port1_end_mappings
        global set port2_end_mappings
        global set port3_end_mappings
        global set port4_end_mappings
        global set axis_port1_remo_mappings
        global set axis_port2_remo_mappings
        global set axis_port3_remo_mappings
        global set axis_port4_remo_mappings

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
        global set broad_port5_remo_mappings
        global set broad_port6_remo_mappings
        global set axis_switch_in_end_mappings
        global set axis_switch_in_remo_mappings
        global set axis_switch_port1_end_mappings
        global set axis_switch_port2_end_mappings
        global set axis_switch_port3_end_mappings
        global set axis_switch_port4_end_mappings
        global set axis_switch_port1_remo_mappings
        global set axis_switch_port2_remo_mappings
        global set axis_switch_port3_remo_mappings
        global set axis_switch_port4_remo_mappings

		set broad [get_count "broad"]

		set node [get_node $drv_handle]
		set dts_file [set_drv_def_dts $drv_handle]
		set ip [hsi::get_cells -hier $drv_handle]
		if {[string match -nocase [hsi get_property IP_NAME $ip] "v_proc_ss"]} {
			set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
			if {$topology == 0} {
				set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
				add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
				set ports_node [create_node -n "ports" -l scaler_ports$drv_handle -p $node -d $dts_file]
				add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
				add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
				set port_node [create_node -n "port" -l scaler_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
				add_prop "$port_node" "reg" 0 int $dts_file
				add_prop "$port_node" "xlnx,video-format" 3 int $dts_file
				add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
				set scaninip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis"]
				foreach inip $scaninip {
						if {[llength $inip]} {
								set ip_mem_handles [hsi::get_mem_ranges $inip]
								if {![llength $ip_mem_handles]} {
										set broad_ip [get_broad_in_ip $inip]
										if {[llength $broad_ip]} {
												if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
														set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
														set intlen [llength $master_intf]
														set sca_in_end ""
														set sca_remo_in_end ""
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

	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_demosaic"]} {
		set ports_node [create_node -n "ports" -l demosaic_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                set port_node [create_node -n "port" -l demosaic_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$port_node" "reg" 0 int $dts_file
                add_prop "$port_node" "xlnx,cfa-pattern" rggb string $dts_file
		set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
                add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
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
                                               if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
                                                       set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $broad_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
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
               }

	set inip ""
	if {[llength $demo_inip]} {
		if {[string match -nocase [hsi get_property IP_NAME $demo_inip] "axis_switch"]} {
                        set ip_mem_handles [get_ip_mem_ranges $demo_inip]
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
			if {[info exists axis_port2-remo_mappings] && [dict exists $axis_port2_remo_mappings $demo_inip]} {
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
			if {[regexp -nocase $drv_handle "$demo_remo_in_end" match]} {

				if {[llength $demo_remo_in_end]} {
					set demosaic_node [create_node -n "endpoint" -l $demo_remo_in_end -p $port_node -d $dts_file]
					puts "demosaic_node:$demosaic_node"
				}
				if {[llength $demo_in_end]} {
					add_prop "$demosaic_node" "remote-endpoint" $demo_in_end reference $dts_file
				}
				dtg_verbose "****DEMO_END1****"
			}
			if {[info exists demo_remo_in1_end] && [regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
				if {[llength $demo_remo_in1_end]} {
					set demosaic_node1 [create_node -n "endpoint" -l $demo_remo_in1_end -p $port_node -d $dts_file]
					puts "demosaic_node1:$demosaic_node1"
				}
				if {[llength $demo_in1_end]} {
					add_prop "$demosaic_node1" "remote-endpoint" $demo_in1_end reference $dts_file
				}
				dtg_verbose "****DEMO_END2****"
			}
			if {[info exists demo_remo_in2_end] && [regexp -nocase $drv_handle "$demo_remo_in2_end" match]} {
				if {[llength $demo_remo_in2_end]} {
					set demosaic_node2 [create_node -n "endpoint" -l $demo_remo_in2_end -p $port_node -d $dts_file]
					puts "demosaic_node2:$demosaic_node2"
				}
				if {[llength $demo_in2_end]} {
					add_prop "$demosaic_node2" "remote-endpoint" $demo_in2_end reference $dts_file
				}
				dtg_verbose "****DEMO_END3****"
			}
			if {[info exists demo_remo_in3_end] && [regexp -nocase $drv_handle "$demo_remo_in3_end" match]} {
				if {[llength $demo_remo_in3_end]} {
					set demosaic_node3 [create_node -n "endpoint" -l $demo_remo_in3_end -p $port_node -d $dts_file]
					puts "demosaic_node3:$demosaic_node3"
				}
				if {[llength $demo_in3_end]} {
					add_prop "$demosaic_node3" "remote-endpoint" $demo_in3_end reference $dts_file
				}
				dtg_verbose "****DEMO_END3****"
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
                                       dtg_verbose "****DEMO_END1****"
                               }
                               if {[regexp -nocase $drv_handle "$demo_remo_in1_end" match]} {
                                       if {[llength $demo_remo_in1_end]} {
                                               set demosaic_node1 [create_node -n "endpoint" -l $demo_remo_in1_end -p $port_node -d $dts_file]
                                       }
                                       if {[llength $demo_in1_end]} {
                                               add_prop "$demosaic_node1" "remote-endpoint" $demo_in1_end reference $dts_file
                                       }
                                       dtg_verbose "****DEMO_END2****"
                               }
                       }			
			}
		}
                if {[llength $demo_inip]} {
                        foreach inip $demo_inip {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                }
                                if {[llength $inip]} {
                                        set demo_in_end ""
                                        set demo_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                                set demo_in_end [dict get $end_mappings $inip]
						dtg_verbose "demo_in_end:$demo_in_end"
                                        }
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                                set demo_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "demo_remo_in_end:$demo_remo_in_end"
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
		dtg_verbose "***************DEMOEND****************"
	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_gamma_lut"]} {
                set ports_node [create_node -n "ports" -l gamma_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
		add_prop "$ports_node" "#size-cells" 0 int $dts_file 1

                set port_node [create_node -n "port" -l gamma_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$port_node" "reg" 0 int $dts_file
		set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
                add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
		set gamma_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
		set inip ""
                if {[llength $gamma_inip]} {
                        foreach inip $gamma_inip {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                }
                                if {[llength $inip]} {
                                        set gamma_in_end ""
                                        set gamma_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                                set gamma_in_end [dict get $end_mappings $inip]
						dtg_verbose "gamma_in_end:$gamma_in_end"
                                        }
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                                set gamma_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "gamma_remo_in_end:$gamma_remo_in_end"
                                        }
                                        if {[llength $gamma_remo_in_end]} {
                                                set gamma_node [create_node -n "endpoint" -l $gamma_remo_in_end -p $port_node -d $dts_file]
                                        }
                                        if {[llength $gamma_in_end]} {
                                                add_prop "$gamma_node" "remote-endpoint" $gamma_in_end reference $dts_file
                                        }
                                }
                        }
                } else {
                        dtg_warning "$drv_handle pin s_axis_video is not connected..check your design"
                }

	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_hdmi_tx_ss"]} {
                set ports_node [create_node -n "ports" -l hdmitx_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                set hdmi_port_node [create_node -n "port" -l encoder_hdmi_port$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$hdmi_port_node" "reg" 0 int $dts_file
                set hdmitx_in_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_IN"]
                if {![llength $hdmitx_in_ip]} {
                        dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
                }
                set inip ""
                foreach inip $hdmitx_in_ip {
                        if {[llength $inip]} {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $hdmitx_in_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node $dts_file
                                        }
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $hdmi_port_node $dts_file
                                        }
                                }
                        }
                }
		 if {[llength $inip]} {
                        set hdmitx_in_end ""
                        set hdmitx_remo_in_end ""
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
                                add_prop "$hdmitx_node" "remote-endpoint" $hdmitx_in_end reference $dts_file
                        }
                }
        }

	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_tpg"]} {
		set family [get_hw_family]
               if {[string match -nocase $family "zynq"]} {
                       #TBF
                       return
               }
		set ports_node [create_node -n "ports" -l tpg_ports$drv_handle -p $node -d $dts_file]
		set port0_node [create_node -n "port" -l tpg_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$port0_node" "reg" 0 int $dts_file 1
                add_prop "$port0_node" "xlnx,video-format" 2 int $dts_file 1
		 set tpg_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
               if {![llength $tpg_inip]} {
                       dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected..check your design"
               }
                 set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $tpg_inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                set inip [get_in_connect_ip $tpg_inip $master_intf]
                if {[llength $inip]} {
                        set tpg_in_end ""
                        set tpg_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set tpg_in_end [dict get $end_mappings $inip]
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set tpg_remo_in_end [dict get $remo_mappings $inip]
                        }
                        if {[llength $tpg_remo_in_end]} {
                                set tpg_node [create_node -n "endpoint" -l $tpg_remo_in_end -p $port0_node -d $dts_file]
                        }
                        if {[llength $tpg_in_end]} {
                                add_prop "$tpg_node" "remote-endpoint" $tpg_in_end reference $dts_file
                        }
                }
	}

	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_smpte_uhdsdi_tx_ss"]} {
                set ports_node [create_node -n "ports" -l sditx_ports$drv_handle -p $node -d $dts_file]
                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                set sdi_port_node [create_node -n "port" -l encoder_sdi_port$drv_handle -u 0 -p $ports_node -d $dts_file]
                add_prop "$sdi_port_node" "reg" 0 int $dts_file
                set sditx_in_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_IN"]
                if {![llength $sditx_in_ip]} {
                        dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
                }
                set inip ""
                foreach inip $sditx_in_ip {
                        if {[llength $inip]} {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set ip_mem_handles [hsi::get_mem_ranges $inip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node $dts_file
                                        }
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
                                                continue
                                        }
                                        set inip [get_in_connect_ip $inip $master_intf]
                                        if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
                                                gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node $dts_file
                                        }
                                }
                        }
                }
		if {[llength $inip]} {
                        set sditx_in_end ""
                        set sditx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set sditx_in_end [dict get $end_mappings $inip]
				dtg_verbose "sditx_in_end:$sditx_in_end"
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set sditx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "sditx_remo_in_end:$sditx_remo_in_end"
                        }
                        if {[llength $sditx_remo_in_end]} {
                                set sditx_node [create_node -n "endpoint" -l $sditx_remo_in_end -p $sdi_port_node -d $dts_file]
                        }
                        if {[llength $sditx_in_end]} {
                                add_prop "$sditx_node" "remote-endpoint" $sditx_in_end reference $dts_file
                        }
                }
	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "mipi_dsi_tx_subsystem"]} {
		set dsitx_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS"]
		if {![llength $dsitx_inip]} {
			dtg_warning "$drv_handle pin S_AXIS is not connected ..check your design"
		}
		set port_node [create_node -n "port" -l encoder_dsi_port$drv_handle -u 0 -p $node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		set inip ""
		foreach inip $dsitx_inip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
					if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
					}
				} else {
					if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
					if {[string match -nocase [hsi get_property IP_NAME $inip] "v_frmbuf_rd"]} {
						gen_frmbuf_rd_node $inip $drv_handle $port_node $dts_file
					}
				}
			}
		}
		if {[llength $inip]} {
                        set dsitx_in_end ""
                        set dsitx_remo_in_end ""
			if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                set dsitx_in_end [dict get $end_mappings $inip]
				dtg_verbose "dsitx_in_end:$dsitx_in_end"
                        }
			if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                set dsitx_remo_in_end [dict get $remo_mappings $inip]
				dtg_verbose "dsitx_remo_in_end:$dsitx_remo_in_end"
                        }
                        if {[llength $dsitx_remo_in_end]} {
                                set dsitx_node [create_node -n "endpoint" -l $dsitx_remo_in_end -p $port_node -d $dts_file]
                        }
                        if {[llength $dsitx_in_end]} {
				add_prop "$dsitx_node" "remote-endpoint" $dsitx_in_end reference $dts_file
                        }
                }
	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "v_scenechange"]} {
		set memory_scd [hsi get_property CONFIG.MEMORY_BASED [hsi::get_cells -hier $drv_handle]]
		if {$memory_scd == 1} {
			#memory scd
			return
		}
		set scd_ports_node [create_node -n "scd" -l scd_ports$drv_handle -p $node -d $dts_file]
		add_prop "$scd_ports_node" "#address-cells" 1 int $dts_file 1
		add_prop "$scd_ports_node" "#size-cells" 0 int $dts_file 1
		set port_node [create_node -n "port" -l scd_port0$drv_handle -u 0 -p $scd_ports_node -d $dts_file]
		add_prop "$port_node" "reg" 0 int $dts_file
		set scd_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
		if {![llength $scd_inip]} {
			dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected...check your design"
		}
		set broad_ip [get_broad_in_ip $scd_inip]
               if {[llength $broad_ip]} {
               if {[string match -nocase [hsi get_property IP_NAME $broad_ip] "axis_broadcaster"]} {
                       set scd_in_end ""
                       set scd_remo_in_end ""
			if {[info exists port1_broad_end_mappings] && [dict exists $port1_broad_end_mappings $broad_ip]} {
                               set scd_in_end [dict get $port1_broad_end_mappings $broad_ip]
                       }
			if {[info exists broad_port1_remo_mappings] && [dict exists $broad_port1_remo_mappings $broad_ip]} {
                               set scd_remo_in_end [dict get $broad_port1_remo_mappings $broad_ip]
                       }
			if {[info exists port2_broad_end_mappings] && [dict exists $port2_broad_end_mappings $broad_ip]} {
                               set scd_in1_end [dict get $port2_broad_end_mappings $broad_ip]
                       }
			if {[info exists broad_port2_remo_mappings] && [dict exists $broad_port2_remo_mappings $broad_ip]} {
                               set scd_remo_in1_end [dict get $broad_port2_remo_mappings $broad_ip]
                       }
			if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
                               set scd_in2_end [dict get $port3_broad_end_mappings $broad_ip]
                       }
			if {[info exists port3_broad_end_mappings] && [dict exists $port3_broad_end_mappings $broad_ip]} {
                               set scd_remo_in2_end [dict get $broad_port3_remo_mappings $broad_ip]
                       }
			if {[info exists broad_port3_remo_mappings] && [dict exists $broad_port3_remo_mappings $broad_ip]} {
                               set scd_in3_end [dict get $port4_broad_end_mappings $broad_ip]
                       }
			if {[info exists port4_broad_end_mappings] && [dict exists $port4_broad_end_mappings $broad_ip]} {
                               set scd_remo_in3_end [dict get $broad_port4_remo_mappings $broad_ip]
                       }
			if {[info exists scd_remo_in_end] && [regexp -nocase $drv_handle "$scd_remo_in_end" match]} {
                               if {[llength $scd_remo_in_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in_end reference $dts_file
                               }
                       }
			if {[info exists scd_remo_in1_end] && [regexp -nocase $drv_handle "$scd_remo_in1_end" match]} {
                               if {[llength $scd_remo_in1_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in1_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in1_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in1_end reference $dts_file
                               }
                       }
			if {[info exists scd_remo_in2_end] && [regexp -nocase $drv_handle "$scd_remo_in2_end" match]} {
                               if {[llength $scd_remo_in2_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in2_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in2_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in2_end reference $dts_file
                               }
                       }
			if {[info exists scd_remo_in3_end] && [regexp -nocase $drv_handle "$scd_remo_in3_end" match]} {
                               if {[llength $scd_remo_in3_end]} {
                                       set scd_node [create_node -n "endpoint" -l $scd_remo_in3_end -p $port_node -d $dts_file]
                               }
                               if {[llength $scd_in3_end]} {
                                       add_prop "$scd_node" "remote-endpoint" $scd_in3_end reference $dts_file
                               }
                       }
                       return
               }
               }
		foreach inip $scd_inip {
			if {[llength $inip]} {
				set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
				set ip_mem_handles [hsi::get_mem_ranges $inip]
				if {[llength $ip_mem_handles]} {
					set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
				} else {
					if {[string match -nocase [hsi get_property IP_NAME $inip] "system_ila"]} {
						continue
					}
					set inip [get_in_connect_ip $inip $master_intf]
				}
				if {[llength $inip]} {
					set scd_in_end ""
					set scd_remo_in_end ""
					if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
						set scd_in_end [dict get $end_mappings $inip]
					}
					if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
						set scd_remo_in_end [dict get $remo_mappings $inip]
					}
					if {[llength $scd_remo_in_end]} {
						set scd_node [create_node -n "endpoint" -l $scd_remo_in_end -p $port_node -d $dts_file]
					}
					if {[llength $scd_in_end]} {
						add_prop "$scd_node" "remote-endpoint" $scd_in_end reference $dts_file
					}
				}
			}
		}


	}
	if {[string match -nocase [hsi get_property IP_NAME $ip] "axis_broadcaster"]} {
			set axis_broad_ip [hsi get_property IP_NAME $ip]
			set unit_addr [get_baseaddr ${ip} no_prefix]
			if { ![string equal $unit_addr ""] } {
				#break
				return
			}
			set label $ip
			set ip_type [hsi get_property IP_TYPE $ip]
                        if {[string match -nocase $ip_type "BUS"]} {
                               #break
								return
                        }

			set bus_node [detect_bus_name $ip]
			set dts_file [set_drv_def_dts $ip]
			 set rt_node [create_node -n "axis_broadcaster$ip" -l ${label} -u 0 -d ${dts_file} -p $bus_node]
                        if {[llength $axis_broad_ip]} {
                                set intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                set inip [get_in_connect_ip $ip $intf]
                                if {[llength $inip]} {
                                        set inipname [hsi get_property IP_NAME $inip]
set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_l
ut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_sc
enechange"
                                if {[lsearch  -nocase $valid_mmip_list $inipname] >= 0} {
                                set ports_node [create_node -n "ports" -l axis_broadcaster_ports$ip -p $rt_node -d $dts_file]
                                add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
                                add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
                                set port_node [create_node -n "port" -l axis_broad_port0$ip -u 0 -p $ports_node -d $dts_file]
                                add_prop "$port_node" "reg" 0 int $dts_file
				if {[llength $inip]} {
                                        set axis_broad_in_end ""
                                        set axis_broad_remo_in_end ""
                                        if {[dict exists $end_mappings $inip]} {
                                                set axis_broad_in_end [dict get $end_mappings $inip]
						dtg_verbose "drv:$ip inend:$axis_broad_in_end"
                                        }
                                        if {[dict exists $remo_mappings $inip]} {
                                                set axis_broad_remo_in_end [dict get $remo_mappings $inip]
						dtg_verbose "drv:$ip inremoend:$axis_broad_remo_in_end"
                                        }
                                        if {[llength $axis_broad_remo_in_end]} {
                                                set axisinnode [create_node -n "endpoint" -l $axis_broad_remo_in_end -p $port_node -d $dts_file]
                                        }
                                        if {[llength $axis_broad_in_end]} {
                                                add_prop "$axisinnode" "remote-endpoint" $axis_broad_in_end reference $dts_file 1
                                        }
                                        }
                                }
                                }
                        }
	}

	 if {[string match -nocase [hsi get_property IP_NAME $ip] "axis_switch"]} {
		set axis_ip [hsi get_property IP_NAME $ip]
		set dts_file [set_drv_def_dts $ip]
		set unit_addr [get_baseaddr ${ip} no_prefix]
		if { ![string equal $unit_addr ""] } {
			return
		}
		set label $ip
		set bus_node [detect_bus_name $ip]
		set dev_type [hsi get_property IP_NAME [hsi::get_cells -hier [hsi::get_cells -hier $ip]]]
		#set intf "S00_AXIS"
		#set inips [get_axis_switch_in_connect_ip $ip $intf]
		if {[llength $axis_ip]} {
			set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
			set inip [get_in_connect_ip $ip $intf]
			if {[llength $inip]} {
				set inipname [hsi get_property IP_NAME $inip]
					set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
					if {[lsearch -nocase $valid_mmip_list $inipname] >= 0} {
						set ports_node [create_node -n "ports" -l axis_switch_ports$drv_handle -p $node -d $dts_file]
						add_prop "$ports_node" "#address-cells" 1 int $dts_file
						add_prop "$ports_node" "#size-cells" 0 int $dts_file
						set port_node [create_node -n "port" -l axis_switch_port0$ip -u 0 -p $ports_node -d $dts_file]
						add_prop "$port_node" "reg" 0 int $dts_file
						if {[llength $inip]} {
							set axis_switch_in_end ""
							set axis_switch_remo_in_end ""
							if {[info exists axis_switch_in_end_mappings] && [dict exists $axis_switch_in_end_mappings $inip]} {
								set axis_switch_in_end [dict get $axis_switch_in_end_mappings $inip]
								dtg_verbose "drv:$ip inend:$axis_switch_in_end"
							}
							if {[info exists axis_switch_in_remo_mappings] && [dict exists $axis_switch_in_remo_mappings $inip]} {
								set axis_switch_remo_in_end [dict get $axis_switch_in_remo_mappings $inip]
								dtg_verbose "drv:$ip inremoend:$axis_switch_remo_in_end"
							}
							if {[llength $axis_switch_remo_in_end]} {
								set axisinnode [create_node -n "endpoint" -l $axis_switch_remo_in_end -p $port_node -d $dts_file]
							}
							if {[llength $axis_switch_in_end]} {
								add_prop "$axisinnode" "remote-endpoint" $axis_switch_in_end reference $dts_file
							}

				}
			}
		}
	}
	}
}

proc gen_broadcaster {ip dts_file} {
	dtg_verbose "+++++++++gen_broadcaster:$ip"
	set count 0
	set inputip ""
	set outip ""
	set connectip ""
        set compatible [get_comp_str $ip]
        set intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
        set inip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
        set inip [get_in_connect_ip $ip $intf]
	set bus_node [detect_bus_name $ip]
        set broad_node [create_node -n "axis_broadcaster$ip" -l $ip -u 0 -p $bus_node -d $dts_file]
        set ports_node [create_node -n "ports" -l axis_broadcaster_ports$ip -p $broad_node -d $dts_file]
        add_prop "$ports_node" "#address-cells" 1 int $dts_file
        add_prop "$ports_node" "#size-cells" 0 int $dts_file
        add_prop "$broad_node" "compatible" "$compatible" string $dts_file
        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
        set broad 10
	foreach intf $master_intf {
		set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
		if {[llength $connectip]} {
			set ip_mem_handles [hsi::get_mem_ranges $connectip]
				if {![llength $ip_mem_handles]} {
					set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
					set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master_intf]
					if {[llength $connectip]} {
						set ip_mem_handles [hsi::get_mem_ranges $connectip]
						if {![llength $ip_mem_handles]} {
							set master2_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master2_intf]
						}
						if {[llength $connectip]} {
							set ip_mem_handles [hsi::get_mem_ranges $connectip]
							if {![llength $ip_mem_handles]} {
							set master3_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
							set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master3_intf]
						}
					}
				}
			}
			incr count
			set port_node [add_or_get_dt_node -n "port" -l axis_broad_port$count$ip -u $count -p $ports_node]
			add_prop "$port_node" "reg" $count int $dts_file
			set axis_node [add_or_get_dt_node -n "endpoint" -l axis_broad_out$count$ip -p $port_node]
			if {$count <= $count-1} {
				gen_broad_endpoint_port$count $ip "axis_broad_out$count$ip"
                        }
                        add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts_file
			if {$count <= $count-1} {
				gen_broad_remoteendpoint_port$count $ip $connectip$ip
			}
			append inputip " " $connectip
			append outip " " $connectip$ip
                }
        }
        if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
		gen_broad_frmbuf_wr_node $inputip $outip $ip $count $dts_file
	}
}

proc gen_broad_frmbuf_wr_node {inputip outip drv_handle ip count dts_file} {
	set bus_node [detect_bus_name $ip]
	set vcap [add_or_get_dt_node -n "vcapaxis_broad_out1$drv_handle" -p $bus_node -d $dts_file]
	add_prop $vcap "compatible" "xlnx,video" string $dts_file
	set inputip [split $inputip " "]
	set j 0
	foreach ip $inputip {
		if {[llength $ip]} {
			if {$j < $count} {
				append dmasip "<&$ip 0>," " "
			}
		}
		incr j
	}
	append dmasip "<&$ip 0>"
	add_prop $vcap "dmas" "$dmasip" string $dts_file
	set prt ""
	for {set i 0} {$i < $count} {incr i} {
		append prt " " "port$i"
	}
	add_prop $vcap "dma-names" $prt stringlist $dts_file
	set vcap_ports_node [add_or_get_dt_node -n "ports" -l "vcap_portsaxis_broad_out1$drv_handle" -p $vcap -d $dts_file]
	add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
	add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
	set outip [split $outip " "]
	set b 0
	for {set a 1} {$a <= $count} {incr a} {
		set vcap_port_node [add_or_get_dt_node -n "port" -l "vcap_portaxis_broad_out$a$drv_handle" -u "$b" -p "$vcap_ports_node" -d $dts_file]
		add_prop "$vcap_port_node" "reg" $b int $dts_file
		add_prop "$vcap_port_node" "direction" input string $dts_file
		set vcap_in_node [add_or_get_dt_node -n "endpoint" -l [lindex $outip $a] -p "$vcap_port_node" -d $dts_file]
		add_prop "$vcap_in_node" "remote-endpoint" axis_broad_out$a$drv_handle reference $dts_file
		incr b
	}
}

proc get_connect_ip {ip intfpins dts_file} {
	dtg_verbose "get_con_ip:$ip pins:$intfpins"
        if {[llength $intfpins]== 0} {
                return
        }
        if {[llength $ip]== 0} {
                return
        }
        if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $ip]] "axis_broadcaster"]} {
                gen_broadcaster $ip $dts_file
                return
        }
        global connectip ""
        foreach intf $intfpins {
                set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
				if {[llength $connectip]} {
                       if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $connectip]] "axis_switch"]} {
                               gen_axis_switch $connectip
                               break
                       }
                }
                if {[llength $connectip]} {
                        if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $connectip]] "axis_broadcaster"]} {
                                gen_broadcaster $connectip
                                break
                        }
                        if {[string match -nocase [hsi get_property IP_NAME [hsi::get_cells -hier $connectip]] "axis_switch"]} {
                                gen_axis_switch $connectip
                                break
                        }
                }
               set len [llength $connectip]
               if {$len > 1} {
                       for {set i 0 } {$i < $len} {incr i} {
                               set ip [lindex $connectip $i]
                               if {[regexp -nocase "ila" $ip match]} {
                                       continue
                               }
                               set connectip "$ip"
                       }
               }
                if {[llength $connectip]} {
                        set ip_mem_handles [hsi::get_mem_ranges $connectip]
                        if {[llength $ip_mem_handles]} {
                                break
                        } else {
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                                get_connect_ip $connectip $master_intf $dts_file
                        }
                }
        }
        return $connectip
}

proc get_in_connect_ip {ip intfpins} {
	dtg_verbose "get_in_con_ip:$ip pins:$intfpins"
        if {[llength $intfpins]== 0} {
                return
        }
        if {[llength $ip]== 0} {
                return
        }
        global connectip ""
        foreach intf $intfpins {
                        set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
                        if {[llength $connectip]} {
                        set extip [hsi get_property IP_NAME $connectip]
                        if {[string match -nocase $extip "dfe_glitch_protect"] || [string match -nocase $extip "axi_interconnect"] || [string match -nocase $extip "axi_crossbar"]} {
                                return
                        }
                        }
                        set len [llength $connectip]
                        if {$len > 1} {
                                for {set i 0 } {$i < $len} {incr i} {
                                        set ip [lindex $connectip $i]
                                        if {[regexp -nocase "ila" $ip match]} {
                                                continue
                                        }
                                        set connectip "$ip"
                                }
                        }
                        if {[llength $connectip]} {
                                set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                if {[llength $ip_mem_handles]} {
                                                break
                                } else {
                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "system_ila"]} {
                                                        continue
                                        }
                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                        get_in_connect_ip $connectip $master_intf
                                }
                        }
        }
        return $connectip
}

proc gen_frmbuf_rd_node {ip drv_handle sdi_port_node dts_file} {
        set frmbuf_rd_node [create_node -n "endpoint" -l encoder$drv_handle -p $sdi_port_node -d $dts_file]
        add_prop "$frmbuf_rd_node" "remote-endpoint" $ip$drv_handle reference $dts_file
	set bus_node [detect_bus_name $drv_handle]
        set pl_display [create_node -n "drm-pl-disp-drv$drv_handle" -l "v_pl_disp$drv_handle" -p $bus_node -d $dts_file]
        add_prop $pl_display "compatible" "xlnx,pl-disp" string $dts_file
        add_prop $pl_display "dmas" "$ip 0" reference $dts_file
        add_prop $pl_display "dma-names" "dma0" string $dts_file
        add_prop $pl_display "xlnx,vformat" "YUYV" string $dts_file
        set pl_display_port_node [create_node -n "port" -l pl_display_port$drv_handle -u 0 -p $pl_display -d $dts_file]
        add_prop "$pl_display_port_node" "reg" 0 int $dts_file
        set pl_disp_crtc_node [create_node -n "endpoint" -l $ip$drv_handle -p $pl_display_port_node -d $dts_file]
        add_prop "$pl_disp_crtc_node" "remote-endpoint" encoder$drv_handle reference $dts_file
}

proc gen_axis_switch {ip} {
	set compatible [get_comp_str $ip]
	dtg_verbose "+++++++++gen_axis_switch:$ip"
	set routing_mode [hsi get_property CONFIG.ROUTING_MODE [hsi get_cells -hier $ip]]
        if {$routing_mode == 1} {
                # Routing_mode is 1 means it is a memory mapped
                return
        }
	set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set inip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
	puts "connectinip:$inip"
	set intf1 [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
	set iip [get_connected_stream_ip [hsi::get_cells -hier $inip] $intf1]
	puts "iip:$iip"
	set inip [get_in_connect_ip $ip $intf]
	puts "inip:$inip"
	set bus_node [detect_bus_name $ip]
	set dts [set_drv_def_dts $ip]
	set switch_node [create_node -n "axis_switch_$ip" -l $ip -u 0 -p $bus_node -d $dts]
	set ports_node [create_node -n "ports" -l axis_switch_ports$ip -p $switch_node -d $dts]
	add_prop "$ports_node" "#address-cells" 1 int $dts
	add_prop "$ports_node" "#size-cells" 0 int $dts
	set master_intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	puts "intf:$master_intf"
	add_prop "$switch_node" "xlnx,routing-mode" $routing_mode int $dts
	set num_si [hsi get_property CONFIG.NUM_SI [hsi::get_cells -hier $ip]]

	add_prop "$switch_node" "xlnx,num-si-slots" $num_si int $dts
	set num_mi [hsi get_property CONFIG.NUM_MI [hsi::get_cells -hier $ip]]
	add_prop "$switch_node" "xlnx,num-mi-slots" $num_mi int $dts
	add_prop "$switch_node" "compatible" "$compatible" string $dts
	set count 0
	foreach intf $master_intf {
	       set connectip [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
	       set len [llength $connectip]
               if {$len > 1} {
                       for {set i 0 } {$i < $len} {incr i} {
                              set temp_ip [lindex $connectip $i]
                              if {[regexp -nocase "ila" $temp_ip match]} {
                                      continue
                              }
                              set connectip "$temp_ip"
                      }
               }
	       puts "connectip:$connectip intf:$intf"
	       if {[llength $connectip]} {
		       incr count
	       }
	       if {$count == 1} {
		       set port_node [create_node -n "port" -l axis_switch_port1$ip -u 1 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 1 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out1$ip -p $port_node -d $dts]
		       gen_axis_port1_endpoint $ip "axis_switch_out1$ip"
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port1_remoteendpoint $ip $connectip$ip
	       }
	       if {$count == 2} {
		       set port_node [create_node -n "port" -l axis_switch_port2$ip -u 2 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 2 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out2$ip -p $port_node -d $dts]
		       gen_axis_port2_endpoint $ip "axis_switch_out2$ip"
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port2_remoteendpoint $ip $connectip$ip
	       }
	       if {$count == 3} {
		       set port_node [create_node -n "port" -l axis_switch_port3$ip -u 3 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 3 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out3$ip -p $port_node -d $dts]
		       gen_axis_port3_endpoint $ip "axis_switch_out3$ip" 
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port3_remoteendpoint $ip $connectip$ip
	       }
	       if {$count == 4} {
		       set port_node [create_node -n "port" -l axis_switch_port4$ip -u 4 -p $ports_node -d $dts]
		       add_prop "$port_node" "reg" 4 int $dts
		       set axis_node [create_node -n "endpoint" -l axis_switch_out4$ip -p $port_node -d $dts]
		       gen_axis_port4_endpoint $ip "axis_switch_out4$ip"
		       add_prop "$axis_node" "remote-endpoint" $connectip$ip reference $dts
		       gen_axis_port4_remoteendpoint $ip $connectip$ip
	       }
	}
}

proc get_broad_in_ip {ip} {
	dtg_verbose "get_broad_in_ip:$ip"
        if {[llength $ip]== 0} {
                return
        }
        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
        set connectip ""
        foreach intf $master_intf {
                set connect [get_connected_stream_ip [hsi::get_cells -hier $ip] $intf]
                set len [llength $connectip]
                if {$len > 1} {
                    for {set i 0 } {$i < $len} {incr i} {
                        set ip [lindex $connectip $i]
                        if {[regexp -nocase "ila" $ip match]} {
                            continue
                        }
                        set connectip "$ip"
                    }
                }
                foreach connectip $connect {
                        if {[llength $connectip]} {
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_broadcaster"]} {
                                        return $connectip
                                }
                                set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                if {![llength $ip_mem_handles]} {
                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                        foreach intf $master_intf {
                                                set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $intf]
                                                foreach connect $connectip {
                                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_broadcaster"]} {
                                                                return $connectip
                                                        }
                                                }
                                        }
                                        if {[llength $connectip]} {
                                                set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                                if {![llength $ip_mem_handles]} {
                                                        set master2_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                        foreach intf $master2_intf {
                                                                set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $intf]
                                                                if {[llength $connectip]} {
                                                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_broadcaster"]} {
                                                                                return $connectip
                                                                        }
                                                                }
                                                        }
                                                }
						if {[llength $connectip]} {
                                                        set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                                        if {![llength $ip_mem_handles]} {
                                                                set master3_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connectip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                                set connectip [get_connected_stream_ip [hsi::get_cells -hier $connectip] $master3_intf]
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
        return $connectip
}