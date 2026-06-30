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

    proc gamma_lut_generate {drv_handle} {
	global end_mappings
	global remo_mappings
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,v-gamma-lut\""
        set gamma_ip [hsi::get_cells -hier $drv_handle]
        set s_axi_ctrl_addr_width [hsi get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int $dts_file
        set s_axi_ctrl_data_width [hsi get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int $dts_file
        set max_rows [hsi get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
        set max_cols [hsi get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,max-width" $max_cols int $dts_file
        set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        set ports_node [create_node -n "ports" -l gamma_ports$drv_handle -p $node -d $dts_file]
        add_prop "$ports_node" "#address-cells" 1 int $dts_file
        add_prop "$ports_node" "#size-cells" 0 int $dts_file
        set port1_node [create_node -n "port" -l gamma_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
        add_prop "$port1_node" "reg" 1 int $dts_file
        add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file

        set gammaoutip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_video"]
        foreach outip $gammaoutip {
            if {[llength $outip]} {
                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $outip] -filter { TYPE==MASTER || TYPE == INITIATOR}]
                set ip_mem_handles [hsi::get_mem_ranges $outip]
                if {[llength $ip_mem_handles]} {
                    set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                    set gammanode [create_node -n "endpoint" -l gamma_out$drv_handle -p $port1_node -d $dts_file]
                    add_prop "$gammanode" "remote-endpoint" $outip$drv_handle reference $dts_file
                    gen_endpoint $drv_handle "gamma_out$drv_handle"
                    gen_remoteendpoint $drv_handle "$outip$drv_handle"
                    if {[string match -nocase [hsi get_property IP_NAME $outip] "v_frmbuf_wr"]} {
                        gamma_lut_gen_frmbuf_wr_node $outip $drv_handle $dts_file
                    }
                } else {
                    if {[string match -nocase [hsi get_property IP_NAME $outip] "system_ila"]} {
                        continue
                    }
                    set connectip [get_connect_ip $outip $master_intf $dts_file]
                    if {[llength $connectip]} {
                        set gammanode [create_node -n "endpoint" -l gamma_out$drv_handle -p $port1_node -d $dts_file]
                        gen_endpoint $drv_handle "gamma_out$drv_handle"
                        add_prop "$gammanode" "remote-endpoint" $connectip$drv_handle reference $dts_file
                        gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                            gamma_lut_gen_frmbuf_wr_node $connectip $drv_handle $dts_file
                        }
                    }
                }
            } else {
                dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
            }
        }

    gen_video_reset_gpio $drv_handle $node $dts_file
    }

    proc gamma_lut_update_endpoints {drv_handle} {
	global end_mappings
	global remo_mappings
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        set ports_node [create_node -n "ports" -l gamma_ports$drv_handle -p $node -d $dts_file]
        set port_node [create_node -n "port" -l gamma_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
        add_prop "$port_node" "reg" 0 int $dts_file
        set max_data_width [hsi::get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "$port_node" "xlnx,video-width" $max_data_width int $dts_file
        set gamma_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
        set inip ""
        if {[llength $gamma_inip]} {
            foreach inip $gamma_inip {
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

    proc gamma_lut_gen_frmbuf_wr_node {outip drv_handle dts_file} {
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
        add_prop "$vcap_in_node" "remote-endpoint" gamma_out$drv_handle reference $dts_file
    }

