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

    proc mixer_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,mixer-3.0\"\ \, \"xlnx,mixer-4.0\"\ \, \"xlnx,v-mix-5.3\"\ \, \"xlnx,mixer-5.0\"\ \, \"xlnx,v-mix-6.0\""
        set mixer_ip [hsi::get_cells -hier $drv_handle]
        set num_layers [hsi get_property CONFIG.NR_LAYERS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-layers" $num_layers int $dts_file
        set samples_per_clock [hsi get_property CONFIG.SAMPLES_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,ppc" $samples_per_clock int $dts_file
        set dma_addr_width [hsi get_property CONFIG.AXIMM_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,dma-addr-width" $dma_addr_width int $dts_file
        set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bpc" $max_data_width int $dts_file
        set tile_mode [hsi get_property CONFIG.IS_TILE_FORMAT [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $tile_mode "1"]} {
                add_prop "${node}" "xlnx,tile-formats" $tile_mode boolean $dts_file 1
        } else {
                pldt unset $node "xlnx,tile-formats"
        }
        if {$tile_mode == ""} {
                set tile_mode 0
        }
        set logo_layer [hsi get_property CONFIG.LOGO_LAYER [hsi::get_cells -hier $drv_handle]]
        if {[string match -nocase $logo_layer "true"]} {
                add_prop "$node" "xlnx,logo-layer" boolean $dts_file
        }
        set enable_csc_coefficient_registers [hsi get_property CONFIG.ENABLE_CSC_COEFFICIENT_REGISTERS [hsi::get_cells -hier $drv_handle]]
        if {$enable_csc_coefficient_registers == 1} {
                add_prop "$node" "xlnx,enable-csc-coefficient-register" boolean $dts_file
        }

        set mix_outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_video"]
        if {![llength $mix_outip]} {
                dtg_warning "$drv_handle pin m_axis_video is not connected ...check your design"
        }

        set mixer_port_node [create_node -n "port" -l crtc_mixer_port$drv_handle -u 0 -p $node -d $dts_file]
        add_prop "$mixer_port_node" "reg" 0 int $dts_file


        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $mix_outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
	foreach outip $mix_outip {
            if {[llength $outip] != 0} {
                if {![string match -nocase [hsi::get_property IP_NAME $outip] "v_frmbuf_wr"]} {
                    set mixer_port_node [create_node -n "port" -l crtc_mixer_port$drv_handle -u 0 -p $node -d $dts_file]
                    add_prop "$mixer_port_node" "reg" 0 int $dts_file
                    set mixer_crtc [create_node -n "endpoint" -l mixer_crtc$drv_handle -p $mixer_port_node -d $dts_file]
                } else {
                    set ports_node [create_node -n "ports" -l crtc_mixer_ports$drv_handle -p $node -d $dts_file]
                    add_prop "$ports_node" "#address-cells" 1 int $dts_file
                    add_prop "$ports_node" "#size-cells" 0 int $dts_file
                    set mixer_port0 [create_node -n "port" -l crtc_mixer_port$drv_handle -u 0 -p $ports_node -d $dts_file]
                    add_prop "$mixer_port0" "reg" 0 int $dts_file
                    set mixer0_endpoint [create_node -n "endpoint" -l mixer_crtc$drv_handle -p $mixer_port0 -d $dts_file]
                    set mixer_port1 [create_node -n "port" -l crtc_mixer_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
                    add_prop "$mixer_port1" "reg" 1 int $dts_file
                    set mixer1_endpoint [create_node -n "endpoint" -l mixer_out$drv_handle -p $mixer_port1 -d $dts_file]
                }

                set ip_mem_handles [hsi::get_mem_ranges $outip]
                if {[llength $ip_mem_handles]} {
                    gen_endpoint $drv_handle "mixer_crtc$drv_handle"
                    if {[string match -nocase [hsi::get_property IP_NAME $outip] "v_dp_txss1"]} {
                        add_prop "$mixer_crtc" "remote-endpoint" "dptx_out$outip" reference $dts_file
                        gen_remoteendpoint $drv_handle "dptx_out$outip"
                    } elseif {[string match -nocase [hsi::get_property IP_NAME $outip] "v_frmbuf_wr"]} {
                        set mix_inip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
                        if {[llength $mix_inip]} {
                            add_prop "$mixer0_endpoint" "remote-endpoint" "sca_out$mix_inip" reference $dts_file
                        }
                        add_prop "$mixer1_endpoint" "remote-endpoint" "v_frmbuf_wr$outip" reference $dts_file
                    } else {
                        add_prop "$mixer_crtc" "remote-endpoint" $outip$drv_handle reference $dts_file
                        gen_remoteendpoint $drv_handle "$outip$drv_handle"
                    }
                } else {
                    if {[string match -nocase [hsi::get_property IP_NAME $outip] "system_ila"]} {
                        continue
                    }
                    set connectip [get_connect_ip $outip $master_intf $dts_file]
                    if {[llength $connectip]} {
                        gen_endpoint $drv_handle "mixer_crtc$drv_handle"
                        if {[string match -nocase [hsi::get_property IP_NAME $outip] "v_dp_txss1"]} {
                            add_prop "$mixer_crtc" "remote-endpoint" "dptx_out$outip" reference $dts_file
                            gen_remoteendpoint $drv_handle "dptx_out$outip"
                        } else {
                            add_prop "$mixer_crtc" "remote-endpoint" $connectip$drv_handle reference $dts_file
                            gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                        }
                    }
                }
            } else {
                dtg_warning "$drv_handle pin m_axis_video is not connected ...check your design"
            }
        }
        for {set layer 0} {$layer < $num_layers} {incr layer} {
                        switch $layer {
                                "0" {
                                        set mixer_node0 [create_node -n "layer_$layer" -l xx_mix_master$drv_handle -p $node -d $dts_file]
                                        add_prop "$mixer_node0" "xlnx,layer-id" $layer int $dts_file
                                        set maxwidth [hsi get_property CONFIG.MAX_COLS [hsi::get_cells -hier $drv_handle]]
                                        add_prop "$mixer_node0" "xlnx,layer-max-width" $maxwidth int $dts_file
                                        set maxheight [hsi get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
                                        add_prop "$mixer_node0" "xlnx,layer-max-height" $maxheight int $dts_file
                                        add_prop "$mixer_node0" "xlnx,layer-primary" "" boolean $dts_file
                                        set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
                                        foreach connected_ip $connect_ip {
                                        if {[llength $connected_ip] != 0} {
                                                set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                                if {[llength $ip_mem_handles]} {
                                                        add_prop $mixer_node0 "dmas" "$connected_ip 0" reference $dts_file
                                                        add_prop $mixer_node0 "dma-names" "dma0" string $dts_file
                                                        add_prop "$mixer_node0" "xlnx,layer-streaming" "" boolean $dts_file
                                                } else {
                                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                        set inip [get_in_connect_ip $connected_ip $master_intf]
                                                        if {[llength $inip]} {
                                                                add_prop $mixer_node0 "dmas" "$inip 0" reference $dts_file
                                                        }
                                                        add_prop $mixer_node0 "dma-names" "dma0" string $dts_file
                                                        add_prop "$mixer_node0" "xlnx,layer-streaming" "" boolean $dts_file

                                                }
                                        }
                                }
                                set layer0_video_format [hsi get_property CONFIG.VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                                mixer_gen_video_format $layer0_video_format $mixer_node0 $drv_handle $max_data_width $dts_file
                        }
                        "1" {
                                set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                                add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                                set layer1_alpha [hsi get_property CONFIG.LAYER1_ALPHA [hsi::get_cells -hier $drv_handle]]
                                if {[string match -nocase $layer1_alpha "true"]} {
                                        add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                                }
                                set layer1_maxwidth [hsi get_property CONFIG.LAYER1_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                                add_prop "$mixer_node1" "xlnx,layer-max-width" $layer1_maxwidth int $dts_file
                                set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video1"]
                                foreach connected_ip $connect_ip {
                                        if {[llength $connected_ip]} {
                                                set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                                if {[llength $ip_mem_handles]} {
                                                        add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                        add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                        add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                                } else {
                                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                        set inip [get_in_connect_ip $connected_ip $master_intf]
                                                        if {[llength $inip]} {
                                                                add_prop $mixer_node1 "dmas" "$inip 0" reference $dts_file
                                                        }
                                                        add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                        add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                                }
                                        }
                                }
                                set sample [hsi get_property CONFIG.LAYER1_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                                if {[string match -nocase $sample "true"]} {
                                        add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                                }
                                set layer1_video_format [hsi get_property CONFIG.LAYER1_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                                        if {$tile_mode} {
                                                mixer_gen_tile_vid_formats $layer1_video_format $mixer_node1 $dts_file
                                        } else {
                                                mixer_gen_video_format $layer1_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                                        }
                        }
                        "2" {
                                set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                                add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                                set layer2_alpha [hsi get_property CONFIG.LAYER2_ALPHA [hsi::get_cells -hier $drv_handle]]
                                if {[string match -nocase $layer2_alpha "true"]} {
                                        add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                                }
                                set layer2_maxwidth [hsi get_property CONFIG.LAYER2_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                                add_prop "$mixer_node1" "xlnx,layer-max-width" $layer2_maxwidth int $dts_file
                                set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video2"]
                                foreach connected_ip $connect_ip {
                                        if {[llength $connected_ip]} {
                                                set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                                if {[llength $ip_mem_handles]} {
                                                        add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                        add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                        add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                                } else {
                                                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                        set inip [get_in_connect_ip $connected_ip $master_intf]
                                                        if {[llength $inip]} {
                                                                add_prop $mixer_node1 "dmas" "$inip 0" reference $dts_file
                                                        }
                                                        add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                        add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                                }
                                        }
                                }
                                set sample [hsi get_property CONFIG.LAYER2_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                                if {[string match -nocase $sample "true"]} {
                                        add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                                }
                                set layer2_video_format [hsi get_property CONFIG.LAYER2_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                                        if {$tile_mode} {
                                                mixer_gen_tile_vid_formats $layer2_video_format $mixer_node1 $dts_file
                                        } else {
                                                mixer_gen_video_format $layer2_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                                        }
                        }
                         "3" {
                                set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                                add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                                set layer3_alpha [hsi get_property CONFIG.LAYER3_ALPHA [hsi::get_cells -hier $drv_handle]]
                                if {[string match -nocase $layer3_alpha "true"]} {
                                        add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                                }
                                set layer3_maxwidth [hsi get_property CONFIG.LAYER3_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                                add_prop "$mixer_node1" "xlnx,layer-max-width" $layer3_maxwidth int $dts_file
                                set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video3"]
                                foreach connected_ip $connect_ip {
                                if {[llength $connected_ip]} {
                                        set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                        if {[llength $ip_mem_handles]} {
                                                add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                        } else {
                                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                set inip [get_in_connect_ip $connected_ip $master_intf]
                                                if {[llength $inip]} {
                                                        add_prop $mixer_node1 "dmas" "$inip 0" reference $dts_file
                                                }
                                                add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                            }
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER3_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer3_video_format [hsi get_property CONFIG.LAYER3_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer3_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer3_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "4" {
                        set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer4_alpha [hsi get_property CONFIG.LAYER4_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer4_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer4_maxwidth [hsi get_property CONFIG.LAYER4_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer4_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video4"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                            if {[llength $ip_mem_handles]} {
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                            } else {
                                                    set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                    set inip [get_in_connect_ip $connected_ip $master_intf]
                                                    if {[llength $inip]} {
                                                        add_prop $mixer_node1 "dmas" "$inip 0" reference $dts_file
                                                    }
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                            }
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER4_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer4_video_format [hsi get_property CONFIG.LAYER4_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer4_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer4_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "5" {
                        set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer5_alpha [hsi get_property CONFIG.LAYER5_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer5_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer5_maxwidth [hsi get_property CONFIG.LAYER5_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer5_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video5"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                            if {[llength $ip_mem_handles]} {
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                                    set layer0_video_format [hsi get_property CONFIG.VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                                                    if {$tile_mode} {
                                                            mixer_gen_tile_vid_formats $layer0_video_format $mixer_node1 $dts_file
                                                    } else {
                                                            mixer_gen_video_format $layer0_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                                                    }
                                            } else {
                                                    set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                    set inip [get_in_connect_ip $connected_ip $master_intf]
                                                    if {[llength $inip]} {
                                                        add_param $mixer_node1 "dmas" "$inip 0" reference $dts_file
                                                    }
                                                    add_param $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_param "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                            }
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER5_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer5_video_format [hsi get_property CONFIG.LAYER5_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer5_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer5_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                "6" {
                        set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer6_alpha [hsi get_property CONFIG.LAYER6_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer6_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer6_maxwidth [hsi get_property CONFIG.LAYER6_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer6_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video6"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set ip_mem_handles [hsi::get_mem_ranges $connected_ip]
                                            if {[llength $ip_mem_handles]} {
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                                    set layer0_video_format [hsi get_property CONFIG.VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                                                    if {$tile_mode} {
                                                            mixer_gen_tile_vid_formats $layer0_video_format $mixer_node1 $dts_file
                                                    } else {
                                                            mixer_gen_video_format $layer0_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                                                    }
                                            } else {
                                                    set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_ip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
                                                    set inip [get_in_connect_ip $connected_ip $master_intf]
                                                    if {[llength $inip]} {
                                                        add_prop $mixer_node1 "dmas" "$inip 0" reference $dts_file
                                                    }
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                            }
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER6_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer6_video_format [hsi get_property CONFIG.LAYER6_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer6_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer6_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "7" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer7_alpha [hsi get_property CONFIG.LAYER7_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer7_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer7_maxwidth [hsi get_property CONFIG.LAYER7_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer7_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video7"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER7_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer7_video_format [hsi get_property CONFIG.LAYER7_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer7_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer7_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                "8" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer8_alpha [hsi get_property CONFIG.LAYER8_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer8_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer8_maxwidth [hsi get_property CONFIG.LAYER8_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer8_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video8"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER8_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer8_video_format [hsi get_property CONFIG.LAYER8_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer8_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer8_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "9" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer9_alpha [hsi get_property CONFIG.LAYER9_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer9_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer9_maxwidth [hsi get_property CONFIG.LAYER9_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer9_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video9"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER9_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer9_video_format [hsi get_property CONFIG.LAYER9_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer9_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer9_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "10" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer10_alpha [hsi get_property CONFIG.LAYER10_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer10_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer10_maxwidth [hsi get_property CONFIG.LAYER10_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer10_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video10"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER10_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer10_video_format [hsi get_property CONFIG.LAYER10_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer10_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer10_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                "11" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer11_alpha [hsi get_property CONFIG.LAYER11_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer11_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer11_maxwidth [hsi get_property CONFIG.LAYER11_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer11_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video11"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER11_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer11_video_format [hsi get_property CONFIG.LAYER11_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer11_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer11_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "12" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer12_alpha [hsi get_property CONFIG.LAYER12_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer12_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer12_maxwidth [hsi get_property CONFIG.LAYER12_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer12_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video12"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER12_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer12_video_format [hsi get_property CONFIG.LAYER12_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer12_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer12_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                 "13" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer13_alpha [hsi get_property CONFIG.LAYER13_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer13_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer13_maxwidth [hsi get_property CONFIG.LAYER13_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer13_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video13"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER13_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer13_video_format [hsi get_property CONFIG.LAYER13_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer13_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer13_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                "14" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer14_alpha [hsi get_property CONFIG.LAYER14_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer14_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer14_maxwidth [hsi get_property CONFIG.LAYER14_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer14_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video14"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER14_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer14_video_format [hsi get_property CONFIG.LAYER14_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer14_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer14_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                "15" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer15_alpha [hsi get_property CONFIG.LAYER15_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer15_alpha "true"]} {
                                   add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer15_maxwidth [hsi get_property CONFIG.LAYER15_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer15_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video15"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "v_frmbuf_rd"]} {
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                            }
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER15_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer15_video_format [hsi get_property CONFIG.LAYER15_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer15_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer15_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                "16" {
                            set mixer_node1 [create_node -n "layer_$layer" -l xx_mix_overlay_$layer$drv_handle -p $node -d $dts_file]
                            add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
                            set layer16_alpha [hsi get_property CONFIG.LAYER16_ALPHA [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $layer16_alpha "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-alpha" "" boolean $dts_file
                            }
                            set layer16_maxwidth [hsi get_property CONFIG.LAYER16_MAX_WIDTH [hsi::get_cells -hier $drv_handle]]
                            add_prop "$mixer_node1" "xlnx,layer-max-width" $layer16_maxwidth int $dts_file
                            set connect_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video16"]
                            foreach connected_ip $connect_ip {
                                    if {[llength $connected_ip]} {
                                            set connected_ip_type [hsi get_property IP_NAME $connected_ip]
                                            if {[string match -nocase $connected_ip_type "system_ila"]} {
                                                    continue
                                            }
                                                    add_prop $mixer_node1 "dmas" "$connected_ip 0" reference $dts_file
                                                    add_prop $mixer_node1 "dma-names" "dma0" string $dts_file
                                                    add_prop "$mixer_node1" "xlnx,layer-streaming" "" boolean $dts_file
                                    }
                            }
                            set sample [hsi get_property CONFIG.LAYER16_UPSAMPLE [hsi::get_cells -hier $drv_handle]]
                            if {[string match -nocase $sample "true"]} {
                                    add_prop "$mixer_node1" "xlnx,layer-scale" "" boolean $dts_file
                            }
                            set layer16_video_format [hsi get_property CONFIG.LAYER16_VIDEO_FORMAT [hsi::get_cells -hier $drv_handle]]
                            if {$tile_mode} {
                                    mixer_gen_tile_vid_formats $layer16_video_format $mixer_node1 $dts_file
                            } else {
                                    mixer_gen_video_format $layer16_video_format $mixer_node1 $drv_handle $max_data_width $dts_file
                            }
                    }
                    default {
                    }

                }
        }
        set mixer_node1 [create_node -n "logo" -l xx_mix_logo$drv_handle -p $node -d $dts_file]
        add_prop "$mixer_node1" "xlnx,layer-id" $layer int $dts_file
        set logo_width [hsi get_property CONFIG.MAX_LOGO_COLS [hsi::get_cells -hier $drv_handle]]
        add_prop "$mixer_node1" "xlnx,logo-width" $logo_width int $dts_file
        set logo_height [hsi get_property CONFIG.MAX_LOGO_ROWS [hsi::get_cells -hier $drv_handle]]
        add_prop "$mixer_node1" "xlnx,logo-height" $logo_height int $dts_file
	mixer_gen_gpio_reset $drv_handle $node $dts_file
    }

    proc mixer_gen_tile_vid_formats {num node dts_file} {
            set vid_formats ""
            switch $num {
                    "24" {
                            set vid_formats "T5M8, T6M8"
                    }
                    "25" {
                            set vid_formats "T5MA, T6MA"
                    }
                    "34" {
                            set vid_formats "T5MC, T6MC"
                    }
                    "18" {
                            set vid_formats "T528, T628"
                    }
                    "22" {
                            set vid_formats "T52A, T62A"
                    }
                    "32" {
                            set vid_formats "T52C, T62C"
                    }
                    "19" {
                            set vid_formats "T508, T608"
                    }
                    "23" {
                            set vid_formats "T50A, T60A"
                    }
                    "33" {
                            set vid_formats "T50C, T60C"
                    }
                    "42" {
                            set vid_formats "T548, T648"
                    }
                    "43" {
                            set vid_formats "T54A, T64A"
                    }
                    "44" {
                            set vid_formats "T54C, T64C"
                    }
                    default {
                            dtg_warning "Tile format mapping not supported for format id:$num"
                    }
            }
            if {![string match -nocase $vid_formats ""]} {
                    add_prop "$node" "xlnx,vformat" [list $vid_formats] stringlist $dts_file
            }
    }

    proc mixer_gen_video_format {num node drv_handle max_data_width dts_file} {
            set vid_formats ""
            switch $num {
                    "0" {
                            append vid_formats " " "BG24"
                    }
                    "1" {
                            append vid_formats " " "YUYV"
                    }
                    "2" {
                            if {$max_data_width == 10} {
                                    append vid_formats " " "XV20"
                            } else {
                                    append vid_formats " " "NV16"
                            }
                    }
                    "3" {
                            if {$max_data_width == 10} {
                                    append vid_formats " " "XV15"
                            } else {
                                    append vid_formats " " "NV12"
                            }
                    }
                    "5" {
                            append vid_formats " " "AB24"
                    }
                    "6" {
                            append vid_formats " " "AVUY"
                    }
                 "10" {
                            append vid_formats " " "XB24"
                    }
                    "11" {
                            append vid_formats " " "XVUY"
                    }
                    "12" {
                            append vid_formats " " "YUYV"
                    }
                    "13" {
                            append vid_formats " " "AB24"
                    }
                    "14" {
                            append vid_formats " " "AVUY"
                    }
                    "15" {
                            append vid_formats " " "XB30"
                    }
                    "16" {
                            append vid_formats " " "XV30"
                    }
                    "17" {
                            append vid_formats " " "BG16"
                    }
                    "18" {
                            append vid_formats " " "NV16"
                    }
                    "19" {
                            append vid_formats " " "NV12"
                    }
                    "20" {
                            append vid_formats " " "BG24"
                    }
                    "21" {
                            append vid_formats " " "VU24"
                    }
                    "22" {
                            append vid_formats " " "XV20"
                    }
                    "23" {
                            append vid_formats " " "XV15"
                    }
                    "24" {
                            append vid_formats " " "GREY"
                    }
                "25" {
                            append vid_formats " " "Y10 "
                    }
                    "26" {
                            append vid_formats " " "AR24"
                    }
                    "27" {
                            append vid_formats " " "XR24"
                    }
                    "28" {
                            append vid_formats " " "UYVY"
                    }
                    "29" {
                            append vid_formats " " "RG24"
                    }
                    "42" {
                            append vid_formats " " "YU24"
                    }
                    "43" {
                            append vid_formats " " "X403"
                    }
                    "44" {
                            append vid_formats " " "X423"
                    }
                    "54" {
                            append vid_formats " " "P210"
                    }
                    "55" {
                            append vid_formats " " "P010"
                    }
                    "59" {
                            append vid_formats " " "P012"
                    }
                    default {
                            dtg_warning "Not supported format:$num"
                    }
            }
            if {![string match -nocase $vid_formats ""]} {
                    add_prop "$node" "xlnx,vformat" $vid_formats stringlist $dts_file
            }
    }

    proc mixer_gen_gpio_reset {drv_handle node dts_file} {
        set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "ap_rst_n"]]
        foreach pin $pins {
            set sink_periph [hsi::get_cells -of_objects $pin]
            if {[llength $sink_periph]} {
                set sink_ip [hsi::get_property IP_NAME $sink_periph]
                if {$sink_ip in {"xlslice" "ilslice"}} {
                    set gpio [hsi::get_property CONFIG.DIN_FROM $sink_periph]
                    set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
                    foreach pin $pins {
                        set periph [hsi::get_cells -of_objects $pin]
                        if {[llength $periph]} {
                            set ip [hsi::get_property IP_NAME $periph]
                            if { $ip in { "versal_cips" "ps_wizard" }} {
                                # As versal has only one bank0 for MIOs
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
                            dtg_warning "$drv_handle:peripheral is NULL for the $pin $periph"
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
                dtg_warning "$drv_handle:peripheral is NULL for the $pin $sink_periph"
            }
        }
    }
