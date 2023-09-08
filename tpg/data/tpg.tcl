#
# (C) Copyright 2018-2022 Xilinx, Inc.
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

    proc tpg_generate {drv_handle} {
        global end_mappings
        global remo_mappings
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        set tpg_count [get_count "tpg_count"]
        if { [llength $tpg_count] == 0 } {
                set tpg_count 0
        }
        pldt append $node compatible "\ \, \"xlnx,v-tpg-8.0\""  
        set ip [hsi::get_cells -hier $drv_handle]
        set s_axi_ctrl_addr_width [hsi get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,s-axi-ctrl-addr-width" $s_axi_ctrl_addr_width int $dts_file 1
        set s_axi_ctrl_data_width [hsi get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,s-axi-ctrl-data-width" $s_axi_ctrl_data_width int $dts_file 1
        set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        set pixels_per_clock [hsi get_property CONFIG.SAMPLES_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,ppc" $pixels_per_clock int $dts_file
        set max_cols [hsi get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
        set max_rows [hsi get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
        set proctype [get_hw_family]
        set ports_node [create_node -n "ports" -l tpg_ports$drv_handle -p $node -d $dts_file]
            add_prop "$ports_node" "#address-cells" 1 int $dts_file
            add_prop "$ports_node" "#size-cells" 0 int $dts_file
        set port1_node [create_node -n "port" -l tpg_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
            add_prop "$port1_node" "reg" 1 int $dts_file
            add_prop "$port1_node" "xlnx,video-format" 2 int $dts_file
            add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file

        set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "S_AXIS_VIDEO"]
        if {![llength $connect_ip]} {
                dtg_warning "$drv_handle pin S_AXIS_VIDEO is not connected..check your design"
        }
        foreach connected_ip $connect_ip {
                if {[llength $connected_ip] != 0} {
                        set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                        set ports_node ""
                        set sink_periph ""
                        if {[llength $connected_ip_type] != 0} {
                                if {[string match -nocase $connected_ip_type "system_ila"]} {
                                        continue
                        }
                            if {[string match -nocase $connected_ip_type "v_vid_in_axi4s"]} {
                                    set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $connected_ip "vid_active_video"]]]
                                puts "pins:$pins"
                                    foreach pin $pins {
                                            set sink_periph [hsi::get_cells -of_objects $pin]
                                        set sink_ip [hsi get_property IP_NAME $sink_periph]
                                        if {[string match -nocase $sink_ip "v_tc"]} {
                                                add_prop "$node" "xlnx,vtc" "$sink_periph" reference $dts_file
                                                }
                                        }
                                }
                        }
                }
        }

           set connect_out_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
           if {![llength $connect_out_ip]} {
                   dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected ...check your design"
           }

        foreach out_ip $connect_out_ip {
                if {[llength $out_ip] != 0} {
                set connected_out_ip_type [hsi get_property IP_NAME $out_ip]
                    if {[llength $connected_out_ip_type] != 0} {
                            if {[string match -nocase $connected_out_ip_type "system_ila"] || [string match -nocase $connected_out_ip_type "axi_dbg_hub"]} {
                                    continue
                            }
                            set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $out_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                            set ip_mem_handles [hsi::get_mem_ranges $out_ip]
                            if {[llength $ip_mem_handles]} {
                                    set ip_name [hsi get_property IP_NAME $out_ip]
                                    set tpg_node [create_node -n "endpoint" -l tpg_out$drv_handle -p $port1_node -d $dts_file]
                                    gen_endpoint $drv_handle "tpg_out$drv_handle"
                                    gen_remoteendpoint $drv_handle "$out_ip$drv_handle"
                                    if {[string match -nocase $ip_name "v_mix"] || [string match -nocase $ip_name "v_tpg"]} {
                                            continue
                                    }
                                    add_prop "$tpg_node" "remote-endpoint" $out_ip reference $dts_file
                                    if {[string match -nocase [hsi get_property IP_NAME $out_ip] "v_frmbuf_wr"] || [string match -nocase [hsi get_property IP_NAME $out_ip] "axi_vdma"]} {
                                            tpg_gen_frmbuf_node $out_ip $drv_handle $dts_file
                                    }
                             } else {
                                    set connectip [get_connect_ip $out_ip $master_intf $dts_file]
                                if {[llength $connectip]} {
                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "axi_dbg_hub"]} {
                                                continue
                                        }
                                }
                                    if {[llength $connectip]} {
                                            set ip_mem_handles [hsi::get_mem_ranges $connectip]
                                            if {[llength $ip_mem_handles]} {
                                                    set tpg_node [create_node -n "endpoint" -l tpg_out$drv_handle -p $port1_node -d $dts_file]
                                                    gen_endpoint $drv_handle "tpg_out$drv_handle"
                                                    add_prop "$tpg_node" "remote-endpoint" $connectip reference $dts_file
                                                    gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                                                    if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"] || [string match -nocase [hsi get_property IP_NAME $connectip] "axi_vdma"]} {
                                                            tpg_gen_frmbuf_node $connectip $drv_handle $dts_file
                                                    }
                                            }
                                    }
                            }
                    }
            } else {
                    dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected ...check your design"
            }
    }

    }

    proc tpg_gen_frmbuf_node {ip drv_handle dts_file} {
            set bus_node [detect_bus_name $drv_handle]
            set vcap [create_node -n "vcap_sdirx$drv_handle" -p $bus_node -d $dts_file]
            add_prop $vcap "compatible" "xlnx,video" string $dts_file
            add_prop $vcap "dmas" "$ip 0" reference $dts_file
            add_prop $vcap "dma-names" "port0" string $dts_file
            set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dts_file]
            add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
            add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
            set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
            add_prop "$vcap_port_node" "reg" 0 int $dts_file
            add_prop "$vcap_port_node" "direction" input string $dts_file
            set vcap_in_node [create_node -n "endpoint" -l $ip$drv_handle -p $vcap_port_node -d $dts_file]
            add_prop "$vcap_in_node" "remote-endpoint" tpg_out$drv_handle reference $dts_file
    }


