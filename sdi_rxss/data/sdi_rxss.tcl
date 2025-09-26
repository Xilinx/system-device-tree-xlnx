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

source [file join [file dirname [info script]] "../../device_tree/data/video_utils.tcl"]

proc sdi_rxss_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	sdi_rx_add_hier_instances $drv_handle

        set dtsi_file [set_drv_def_dts $drv_handle]
        set compatible [get_comp_str $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,v-smpte-uhdsdi-rx-ss\""
	set dbpc [hsi get_property CONFIG.C_DYNAMIC_BPP_CHANGE [hsi get_cells -hier $drv_handle]]
	set dbpc [expr {$dbpc == "true" ? 1 : 0}]
	if {$dbpc == 1} {
		add_prop "${node}" "xlnx,dyn-bpc" $dbpc int $dts_file 1
	}
	set sdiline_rate [hsi get_property CONFIG.C_LINE_RATE [hsi get_cells -hier $drv_handle]]
	switch $sdiline_rate {
		"3G_SDI" {
			add_prop "${node}" "xlnx,sdiline-rate" 0 int $dts_file 1
		}
		"6G_SDI" {
			add_prop "${node}" "xlnx,sdiline-rate" 1 int $dts_file 1
		}
		"12G_SDI_8DS" {
			add_prop "${node}" "xlnx,sdiline-rate" 2 int $dts_file 1
		}
		"12G_SDI_16DS" {
			add_prop "${node}" "xlnx,sdiline-rate" 3 int $dts_file 1
		}
		default {
			add_prop "${node}" "xlnx,sdiline-rate" 4 int $dts_file 1
		}
	}
        set line_rate [hsi get_property CONFIG.C_LINE_RATE [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,line-rate"  $line_rate string $dts_file 1
        set ports_node [create_node -n "ports" -l sdirx_ports$drv_handle -p $node -d $dts_file]
        add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
        add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
        set port_node [create_node -n "port" -l sdirx_port$drv_handle -u 0 -p $ports_node -d $dts_file]
#        add_prop "${port_node}" "/* Fill the fields xlnx,video-format and xlnx,video-width based on user requirement */" "" comment $dts_file 1
        add_prop "$port_node" "xlnx,video-format" 0 int $dts_file 1
        add_prop "$port_node" "xlnx,video-width" 10 int $dts_file 1
        add_prop "$port_node" "reg" 0 int $dts_file 1

        set outip [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "VIDEO_OUT"]
	if {[llength $outip]} {
		if {[string match -nocase [hsi get_property IP_NAME $outip] "axis_broadcaster"]} {
			set sdirxnode [create_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node -d $dts_file]
	                gen_endpoint $drv_handle "sdirx_out$drv_handle"
		        add_prop "$sdirxnode" "remote-endpoint" $outip$drv_handle reference $dts_file
			gen_remoteendpoint $drv_handle "$outip$drv_handle"
		}
	}

        foreach ip $outip {
			if {[string match -nocase $ip "axis_data_fifo_Video"]} {
				 set cell [hsi::get_cells -of [hsi::get_intf_nets -of [hsi::get_intf_pins -of_objects [hsi get_cells -hier $ip] M_AXIS]]]
				 foreach rp $cell {
					 if { "v_frmbuf_wr_0" eq $rp } {
                                             set sdi_rx_node [create_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node -d $dts_file]
                                             gen_endpoint $drv_handle "sdirx_out$drv_handle"
                                             add_prop "$sdi_rx_node" "remote-endpoint" $rp$drv_handle reference $dts_file
			                     gen_frmbuf_node $rp $drv_handle $dts_file
                                             break
					}
				}
		} else {
                if {[llength $ip]} {
                        set intfpins [hsi::get_intf_pins -of_objects [hsi get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                        set ip_mem_handles [hsi::get_mem_ranges $ip]
                        if {[llength $ip_mem_handles]} {
                                set sdi_rx_node [create_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node -d $dts_file]
                                gen_endpoint $drv_handle "sdirx_out$drv_handle"
                                add_prop "$sdi_rx_node" "remote-endpoint" $ip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle $ip$drv_handle
                                if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"]} {
					#gen_frmbuf_wr_node $ip $drv_handle
					gen_frmbuf_node $ip $drv_handle $dts_file
                                }
                        } else {
				if {[string match -nocase [hsi get_property IP_NAME $ip] "system_ila"] || ![regexp -nocase ".*frmbuf_wr" $ip]} {
					continue
				}
                                set connectip [get_connect_ip $ip $intfpins $dts_file]

                                set sdi_rx_node [create_node -n "endpoint" -l sdirx_out$drv_handle -p $port_node -d $dts_file]
                                gen_endpoint $drv_handle "sdirx_out$drv_handle"
                                add_prop "$sdi_rx_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle $connectip$drv_handle
                                if {[string match -nocase [hsi get_property IP_NAME $connectip] "axi_vdma"] || [string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
				        gen_frmbuf_node $ip $drv_handle $dts_file
                                        #gen_frmbuf_wr_node $connectip $drv_handle
                                }
                               }
                        }
                }
	}
}


proc gen_frmbuf_node {ip drv_handle dts_file} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
        set bus_node "amba_pl: amba_pl"
        set vcap [create_node -n "vcap_$drv_handle" -p $bus_node -d $dts_file]
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
        add_prop "$vcap_in_node" "remote-endpoint" sdirx_out$drv_handle reference $dts_file
}

proc sdi_rx_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "v_smpte_uhdsdi_rx" "sdirx"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
			update_subcore_absolute_addr $drv_handle $ip_handle $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

}
