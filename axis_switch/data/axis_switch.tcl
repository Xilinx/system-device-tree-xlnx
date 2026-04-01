#
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
#
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

proc sdt_debug {msg} {
        return
}
proc axis_switch_generate {drv_handle} {
}


proc axis_switch_update_endpoints {drv_handle} {
        global end_mappings
        global remo_mappings
        global axis_switch_in_end_mappings
        global axis_switch_in_remo_mappings

        set ip $drv_handle
        set ip_name [hsi get_property IP_NAME [hsi get_cells -hier $drv_handle]]
        sdt_debug "axis_switch: update start ip=$drv_handle ip_name=$ip_name"
        set bus_node [detect_bus_name $ip]
        set dts [set_drv_def_dts $ip]
        set switch_node [get_node $drv_handle]
        if {[string_is_empty $switch_node]} {
                set switch_node [create_node -n "axis_switch_$ip" -l $ip -u 0 -p $bus_node -d $dts]
        }
                if {![string match -nocase $ip_name "axis_switch"] && [llength $ip]} {
                        set ip_mem_handles [hsi get_mem_ranges $ip]
                        if {![llength $ip_mem_handles]} {
                                set axis_ip [hsi get_property IP_NAME $ip]
                                set unit_addr [get_baseaddr ${ip} no_prefix]
                                if { [string equal $unit_addr ""] } {
                                if {[llength $axis_ip]} {
                                        set intf [hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                        set inip [get_in_connect_ip $ip $intf]
                                        set node [get_node $ip]
                                        if {[llength $inip]} {
                                                set inipname [hsi get_property IP_NAME $inip]
                                                set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
                                                if {[lsearch -nocase $valid_mmip_list $inipname] >= 0} {
                                                        set ports_node [create_node -n "ports" -l axis_switch_ports$ip -p $switch_node -d $dts]
                                                        add_prop "$ports_node" "#address-cells" 1 int $dts
                                                        add_prop "$ports_node" "#size-cells" 0 int $dts
                                                        set port_node [create_node -n "port" -l axis_switch_port0$ip -u 0 -p $ports_node -d $dts]
                                                        add_prop "$port_node" "reg" 0 int $dts
                                                        if {[llength $inip]} {
                                                                set axis_switch_in_end ""
                                                                set axis_switch_remo_in_end ""
                                                                if {[info exists end_mappings] && [dict exists $end_mappings $inip]} {
                                                                        set axis_switch_in_end [dict get $end_mappings $inip]
                                                                        dtg_verbose "drv:$ip inend:$axis_switch_in_end"
                                                                }
                                                                if {[info exists remo_mappings] && [dict exists $remo_mappings $inip]} {
                                                                        set axis_switch_remo_in_end [dict get $remo_mappings $inip]
                                                                        dtg_verbose "drv:$ip inremoend:$axis_switch_remo_in_end"
                                                                }
                                                                if {[llength $axis_switch_remo_in_end]} {
                                                                        set axisinnode [create_node -n "endpoint" -l $axis_switch_remo_in_end -p $port_node -d $dts]
                                                                }
                                                                if {[llength $axis_switch_in_end]} {
                                                                        add_prop "$axisinnode" "remote-endpoint" $axis_switch_in_end reference $dts
                                                                }
                                                        }
                                                }
                                        }
                                }
                                }
                        }
                }

        set ip [hsi get_cells -hier $drv_handle]
        if {[string match -nocase [hsi get_property IP_NAME $ip] "axis_switch"]} {
        set intf "S00_AXIS"
        set inips [get_axis_switch_in_connect_ip $ip $intf]
        foreach inip $inips {
                if {[llength $inip]} {
                        set inipname [hsi get_property IP_NAME $inip]
                        set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_hdmi_txss1 v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
                                if {[lsearch -nocase $valid_mmip_list $inipname] >= 0} {
                                        set ports_node [create_node -n "ports" -l axis_switch_ports$ip -p $switch_node -d $dts]
                                        add_prop "$ports_node" "#address-cells" 1 int $dts
                                        add_prop "$ports_node" "#size-cells" 0 int $dts
                                        set port_node [create_node -n "port" -l axis_switch_port0$ip -u 0 -p $ports_node -d $dts]
                                        add_prop "$port_node" "reg" 0 int $dts
                                        if {[llength $inip]} {
                                                set axis_switch_in_end ""
                                                set axis_switch_remo_in_end ""
                                                        set axis_switch_used_fallback 0
                                                if {[info exists axis_switch_in_end_mappings] && [dict exists $axis_switch_in_end_mappings $inip]} {
                                                        set axis_switch_in_end [dict get $axis_switch_in_end_mappings $inip]
                                                        dtg_verbose "drv:$ip inend:$axis_switch_in_end"
                                                }
                                                if {[info exists axis_switch_in_remo_mappings] && [dict exists $axis_switch_in_remo_mappings $inip]} {
                                                        set axis_switch_remo_in_end [dict get $axis_switch_in_remo_mappings $inip]
                                                        dtg_verbose "drv:$ip inremoend:$axis_switch_remo_in_end"
                                                }
						if {[string match -nocase $inipname "mipi_csi2_rx_subsystem"]} {
							if {![llength $axis_switch_in_end]} {
                                                                if {[string match -nocase "hier_*" $inip]} {
                                                                        set axis_switch_in_end "$inip$ip"
                                                                } else {
                                                                        set axis_switch_in_end "mipi_csirx_out$inip"
                                                                }
                                                                        set axis_switch_used_fallback 1
							}
							if {![llength $axis_switch_remo_in_end]} {
								set axis_switch_remo_in_end "$ip$inip"
                                                                        set axis_switch_used_fallback 1
							}
						}
                                                sdt_debug "axis_switch: map in_end=$axis_switch_in_end remo_in_end=$axis_switch_remo_in_end"
                                                if {[llength $axis_switch_remo_in_end]} {
                                                        set axisinnode [create_node -n "endpoint" -l $axis_switch_remo_in_end -p $port_node -d $dts]
                                                }
                                                        if {[llength $axis_switch_in_end] && !$axis_switch_used_fallback} {
                                                        add_prop "$axisinnode" "remote-endpoint" $axis_switch_in_end reference $dts
                                                }
                                        }
                                }
                }
        }
        }
}
