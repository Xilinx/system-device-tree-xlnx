#
# (C) Copyright 2020-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

proc sdi_txss_generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	sdi_tx_add_hier_instances $drv_handle

        set dtsi_file [set_drv_def_dts $drv_handle]
        set compatible [get_comp_str $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,sdi-tx\""

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
	set Isstd_352 [hsi get_property CONFIG.C_TX_INSERT_C_STR_ST352 [hsi get_cells -hier $drv_handle]]
	if {$Isstd_352 == "flase"} {
		add_prop "${node}" "xlnx,Isstd_352" 0 int $dts_file 1
		add_prop "${node}" "xlnx,tx-insert-c-str-st352" false int $dts_file 1
	} else {
		add_prop "${node}" "xlnx,Isstd_352" 1 int $dts_file 1
		add_prop "${node}" "xlnx,tx-insert-c-str-st352" true int $dts_file 1
	}
}

proc sdi_txss_update_endpoints {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {[string_is_empty $node]} {
                return
        }

        global end_mappings
        global remo_mappings

	set ports_node [create_node -n "ports" -l sditx_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
	set sdi_port_node [create_node -n "port" -l encoder_sdi_port$drv_handle -u 0 -p $ports_node -d $dts_file]
	add_prop "$sdi_port_node" "reg" 0 int $dts_file 1
	set sditx_in_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_IN"]
	if {![llength $sditx_in_ip]} {
		dtg_warning "$drv_handle pin VIDEO_IN is not connected...check your design"
	}
	set inip ""
	foreach inip $sditx_in_ip {
		if {[llength $inip]} {
			set master_intf [hsi get_intf_pins -of_objects [hsi get_cells -hier $inip] -filter {TYPE==SLAVE || TYPE ==TARGET}]
			set ip_mem_handles [hsi get_mem_ranges $inip]
			if {[llength $ip_mem_handles]} {
				set base [string tolower [hsi::get_property BASE_VALUE $ip_mem_handles]]
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
					gen_frmbuf_rd_node $inip $drv_handle $sdi_port_node $dts_file
				}
			} else {
				if {[string match -nocase [hsi::get_property IP_NAME $inip] "system_ila"]} {
					continue
				}
				set inip [get_in_connect_ip $inip $master_intf]
				if {[llength $inip] && [string match -nocase [hsi::get_property IP_NAME $inip] "v_frmbuf_rd"]} {
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
			add_prop "$sditx_node" "remote-endpoint" $sditx_in_end reference $dts_file 1
		}
	}

	set audio_connected_ip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "SDI_TX_ANC_DS_OUT"]
        if {[llength $audio_connected_ip] != 0} {
                set audio_connected_ip_type [hsi::get_property IP_NAME $audio_connected_ip]
                if {[string match -nocase $audio_connected_ip_type "v_uhdsdi_audio"]} {
                        set sdi_audio_port [create_node -n "port" -l sdi_audio_port -u 1 -p $ports_node -d $dts_file]
                        add_prop "$sdi_audio_port" "reg" 1 int $dts_file 1
                        set sdi_audio_node [create_node -n "endpoint" -l sdi_audio_sink_port -p $sdi_audio_port -d $dts_file]
                        add_prop "$sdi_audio_node" "remote-endpoint" sditx_audio_embed_src reference $dts_file 1
                }
        } else {
                dtg_warning "$drv_handle:connected ip for audio port pin SDI_TX_ANC_DS_OUT is NULL"
        }

}
proc gen_frmbuf_rd_node {ip drv_handle hdmi_port_node dts_file} {
	set frmbuf_rd_node [create_node -n "endpoint" -l encoder$drv_handle -p $hdmi_port_node -d $dts_file]
	add_prop "$frmbuf_rd_node" "remote-endpoint" $ip$drv_handle reference $dts_file 1
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
	set pl_display [create_node -n "drm-pl-disp-drv$drv_handle" -l "v_pl_disp$drv_handle" -p $bus_node -d $dts_file]
	add_prop $pl_display "compatible" "xlnx,pl-disp" string $dts_file 1
	add_prop $pl_display "dmas" "$ip 0" reference $dts_file 1
	add_prop $pl_display "dma-names" "dma0" string $dts_file 1
#	add_prop "${pl_display}" "/* Fill the field xlnx,vformat based on user requirement */" "" comment
	add_prop $pl_display "xlnx,vformat" "YUYV" string $dts_file 1
	add_prop $pl_display "#address-cells" 1 int $dts_file 1
        add_prop $pl_display "#size-cells" 0 int $dts_file 1
	set pl_display_port_node [create_node -n "port" -l pl_display_port$drv_handle -u 0 -p $pl_display -d $dts_file]
	add_prop "$pl_display_port_node" "reg" 0 int $dts_file 1
	set pl_disp_crtc_node [create_node -n "endpoint" -l $ip$drv_handle -p $pl_display_port_node -d $dts_file]
	add_prop "$pl_disp_crtc_node" "remote-endpoint" encoder$drv_handle reference $dts_file 1
}

proc sdi_tx_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set ip_subcores [dict create]
	dict set ip_subcores "v_smpte_uhdsdi_tx" "sditx"
	dict set ip_subcores "v_tc" "sdivtc"

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
