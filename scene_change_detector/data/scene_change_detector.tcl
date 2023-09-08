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

    proc scene_change_detector_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,v-scd\""
        set ip [hsi::get_cells -hier $drv_handle]
        set max_data_width [hsi get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,max-data-width" $max_data_width int $dts_file
        set memory_scd [hsi get_property CONFIG.MEMORY_BASED [hsi::get_cells -hier $drv_handle]]
        if {$memory_scd == 1} {
                set max_nr_streams [hsi get_property CONFIG.MAX_NR_STREAMS [hsi::get_cells -hier $drv_handle]]
                add_prop "$node" "xlnx,numstreams" $max_nr_streams int $dts_file
                add_prop $node "#address-cells" 1 int $dts_file
                add_prop $node "#size-cells" 0 int $dts_file
                add_prop $node "xlnx,memorybased" boolean $dts_file
                add_prop "$node" "#dma-cells" 1 int $dts_file
                set aximm_addr_width [hsi get_property CONFIG.AXIMM_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
                add_prop "$node" "xlnx,addrwidth" $aximm_addr_width hexint $dts_file
                for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
                        set scd_node [create_node -n "subdev" -u $stream -p $node -d $dts_file]
                        set port_node [create_node -n "port" -u 0 -l "port_$stream" -p $scd_node -d $dts_file]
                        set endpoint [create_node -n "endpoint" -l "scd_in$stream" -p $port_node -d $dts_file]
                        add_prop "$endpoint" "remote-endpoint" "vcap0_out$stream" reference $dts_file
                }
                set dt_overlay ""
                set bus_node [detect_bus_name $drv_handle]
                set dma_names ""
                set dmas ""
                set vcap_scd [create_node -n "video_cap" -l videocap -p $bus_node -d $dts_file]
                for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
                        append dma_names " " "port$stream"
                        set peri "$drv_handle $stream"
                        set dmas [lappend dmas $peri]
                }
                add_prop "$vcap_scd" "dma-names" $dma_names stringlist $dts_file
                scene_change_detector_generate_dmas $vcap_scd $dmas $dts_file
                set ports_vcap [create_node -n "ports" -l ports_vcap -p $vcap_scd -d $dts_file]
                add_prop $ports_vcap "#address-cells" 1 int $dts_file
                add_prop $ports_vcap "#size-cells" 0 int $dts_file
                add_prop $vcap_scd "compatible" "xlnx,video" string $dts_file
                for {set stream 0} {$stream < $max_nr_streams} {incr stream} {
                        set port_vcap_node [create_node -n "port" -u $stream -l port$stream -p $ports_vcap -d $dts_file]
                        add_prop "$port_vcap_node" "reg" $stream int $dts_file
                        add_prop "$port_vcap_node" "direction" output string $dts_file
                        set vcap_endpoint [create_node -n "endpoint" -l vcap0_out$stream -p $port_vcap_node -d $dts_file]
                        add_prop "$vcap_endpoint" "remote-endpoint" scd_in$stream reference $dts_file
                }
        } else {
                set max_nr_streams [hsi get_property CONFIG.MAX_NR_STREAMS [hsi::get_cells -hier $drv_handle]]
                add_prop "$node" "xlnx,numstreams" $max_nr_streams int $dts_file
                add_prop $node "#address-cells" 1 int $dts_file
                add_prop $node "#size-cells" 0 int $dts_file
                set scd_ports_node [create_node -n "scd" -l scd_ports$drv_handle -p $node -d $dts_file]
                add_prop "$scd_ports_node" "#address-cells" 1 int $dts_file
                add_prop "$scd_ports_node" "#size-cells" 0 int $dts_file
                set connect_out_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "M_AXIS_VIDEO"]
                if {![llength $connect_out_ip]} {
                        dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected... check your design"
                }
                foreach connected_out_ip $connect_out_ip {
                        if {[llength $connected_out_ip]} {
                                if {[string match -nocase [hsi get_property IP_NAME $connected_out_ip] "system_ila"]} {
                                        continue
                                }
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $connected_out_ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                                set ip_mem_handles [hsi::get_mem_ranges $connected_out_ip]
                                if {[llength $ip_mem_handles]} {
                                        set scd_port1_node [create_node -n "port" -l scd_port1$drv_handle -u 1 -p $scd_ports_node -d $dts_file]
                                        add_prop "$scd_port1_node" "reg" 1 int $dts_file
                                        set scd_node [create_node -n "endpoint" -l scd_out$drv_handle -p $scd_port1_node -d $dts_file]
                                        add_prop "$scd_node" "remote-endpoint" $connected_out_ip$drv_handle reference $dts_file
                                        if {[string match -nocase [hsi get_property IP_NAME $connected_out_ip] "v_frmbuf_wr"]} {
                                                scene_change_detector_gen_frmbuf_node $connected_out_ip $drv_handle $dts_file
                                        }
                                } else {
                                        set connectip [get_connect_ip $connected_out_ip $master_intf $dts_file]
                                        if {[llength $connectip]} {
                                                set scd_port1_node [create_node -n "port" -l scd_port1$drv_handle -u 1 -p $scd_ports_node -d $dts_file]
                                                add_prop "$scd_port1_node" "reg" 1 int $dts_file
                                                set scd_node [create_node -n "endpoint" -l scd_out$drv_handle -p $scd_port1_node -d $dts_file]
                                                add_prop "$scd_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                                        scene_change_detector_gen_frmbuf_node $connectip $drv_handle $dts_file
                                                }
                                        }
                                }
                        } else {
                                dtg_warning "$drv_handle pin M_AXIS_VIDEO is not connected... check your design"
                        }
                }

        }
        scene_change_detector_add_handles $drv_handle
    }

    proc scene_change_detector_generate_dmas {vcap_scd dmas dts_file} {
        set len [llength $dmas]
        switch $len {
                "1" {
                        set refs [lindex $dmas 0]
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "2" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "3" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "4" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "5" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "6" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "7" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]>, <&[lindex $dmas 6]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
                "8" {
                        set refs [lindex $dmas 0]
                        append refs ">, <&[lindex $dmas 1]>, <&[lindex $dmas 2]>, <&[lindex $dmas 3]>, <&[lindex $dmas 4]>, <&[lindex $dmas 5]>, <&[lindex $dmas 6]>, <&[lindex $dmas 7]"
                        add_prop "$vcap_scd" "dmas" $refs reference $dts_file
                }
        }
    }

    proc scene_change_detector_add_handles {drv_handle} {
            set node [get_node $drv_handle]
            set dts_file [set_drv_def_dts $drv_handle]
            set prop [hsi get_property CONFIG.MEMORY_BASED [hsi::get_cells -hier $drv_handle]]
            if {$prop == 0} {
                set tpg [hsi::get_cells -hier -filter {IP_NAME==v_tpg}]
                if {$tpg != ""} {
                        add_prop "$node" "tpg-connected" $tpg reference $dts_file
                }
                set frmbufwr [hsi::get_cells -hier -filter {IP_NAME==v_frmbuf_wr}]
                if {$frmbufwr != ""} {
                        add_prop "$node" "frmbuf-wr-connected" $frmbufwr reference $dts_file
                }
            }
                
    }
    proc scene_change_detector_gen_frmbuf_node {ip drv_handle dts_file} {
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
    add_prop "$vcap_in_node" "remote-endpoint" scd_out$drv_handle reference $dts_file
    }


