#
# (C) Copyright 2018-2021 Xilinx, Inc.
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

proc generate {drv_handle} {

	set node [get_node $drv_handle]
	if {$node == 0} {
		return
	}
	set dts_file [set_drv_def_dts $drv_handle]
	set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
	add_hier_instances $drv_handle
	if {$topology == 0} {
	#scaler
		set name [hsi get_property NAME [hsi::get_cells -hier $drv_handle]]
		pldt append $node compatible "\ \, \"xlnx,vpss-scaler-2.2\"\ \, \"xlnx,v-vpss-scaler-2.2\"\ \, \"xlnx,vpss-scaler\""
		set ip [hsi::get_cells -hier $drv_handle]
		if 0 {
		set csc_enable_window [hsi get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
		set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set v_scaler_phases [hsi get_property CONFIG.C_V_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int $dts_file
		set v_scaler_taps [hsi get_property CONFIG.C_V_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int $dts_file
		add_prop "${node}" "xlnx,num-vert-taps" $v_scaler_taps int $dts_file
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
		}
		set ports_node [create_node -n "ports" -l scaler_ports$drv_handle -p $node -d $dts_file]
		add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
		add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
		set port1_node [create_node -n "port" -l scaler_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
		add_prop "$port1_node" "reg" 1 int $dts_file 1
		add_prop "$port1_node" "xlnx,video-format" 3 int $dts_file 1
		set scaoutip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis"]
		if {[llength $scaoutip]} {
			if {[string match -nocase [hsi get_property IP_NAME $scaoutip] "axis_broadcaster"]} {
				set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
				gen_endpoint $drv_handle "sca_out$drv_handle"
				add_prop "$sca_node" "remote-endpoint" $scaoutip$drv_handle reference $dts_file
				gen_remoteendpoint $drv_handle "$scaoutip$drv_handle"
			}
		}
		foreach outip $scaoutip {
			if {[llength $outip]} {
				if {[string match -nocase [hsi get_property IP_NAME $outip] "system_ila"]} {
					continue
				}
                        set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                        set ip_mem_handles [hsi::get_mem_ranges $outip]
                        if {[llength $ip_mem_handles]} {
                                set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
				puts "sca_node:$sca_node"
                                gen_endpoint $drv_handle "sca_out$drv_handle"
                                add_prop "$sca_node" "remote-endpoint" $outip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle "$outip$drv_handle"
                                if {[string match -nocase [hsi get_property IP_NAME $outip] "v_frmbuf_wr"] || [string match -nocase [hsi get_property IP_NAME $outip] "axi_vdma"]} {
                                        gen_sca_frm_buf_node $outip $drv_handle $dts_file
                                }
                        } else {
                                set connectip [get_connect_ip $outip $master_intf $dts_file]
				puts "connectip:$connectip"
                                if {[llength $connectip]} {
                                        set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
                                        gen_endpoint $drv_handle "sca_out$drv_handle"
                                        add_prop "$sca_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                        gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"] || [string match -nocase [hsi get_property IP_NAME $connectip] "axi_vdma"]} {
                                                gen_sca_frm_buf_node $connectip $drv_handle $dts_file
                                        }
                                }
                        }
                } else {
                        dtg_warning "$drv_handle pin m_axis is not connected..check your design"
                }
        }


	}
	if {$topology == 3} {
	#CSC
		set name [hsi get_property NAME [hsi::get_cells -hier $drv_handle]]
		pldt append $node compatible "\ \, \"xlnx,vpss-csc\"\ \, \"xlnx,v-vpss-csc\""
		set ip [hsi::get_cells -hier $drv_handle]
		if 0 {
		set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set color_support [hsi get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
		set csc_enable_window [hsi get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
		set max_cols [hsi get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
		set max_data_width [hsi get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
		set max_rows [hsi get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
		set num_video_comp [hsi get_property CONFIG.C_NUM_VIDEO_COMPONENTS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,num-video-components" $num_video_comp int $dts_file
		set samples_per_clk [hsi get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
		set topology [hsi get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,topology" $topology int $dts_file
		set use_uram [hsi get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
		}
		set ports_node [create_node -n "ports" -l csc_ports$drv_handle -p $node -d $dts_file]
		add_prop "$ports_node" "#address-cells" 1 int $dts_file
		add_prop "$ports_node" "#size-cells" 0 int $dts_file
		set port1_node [create_node -n "port" -l csc_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
		add_prop "$port1_node" "reg" 1 int $dts_file
		add_prop "$port1_node" "xlnx,video-format" 3 int $dts_file
		set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis"]
		if {[llength $outip]} {
			if {[string match -nocase [hsi get_property IP_NAME $outip] "axis_broadcaster"]} {
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
                                set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
                                set cscoutnode [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
                                gen_endpoint $drv_handle "csc_out$drv_handle"
                                add_prop "$cscoutnode" "remote-endpoint" $ip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle "$ip$drv_handle"
                                if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"]} {
                                        gen_csc_frm_buf_node $ip $drv_handle $dts_file
                                }
                        } else {
                                if {[string match -nocase [hsi get_property IP_NAME $ip] "system_ila"]} {
                                        continue
                                }
                                set connectip [get_connect_ip $ip $master_intf $dts_file]
                                if {[llength $connectip]} {
                                        set cscoutnode [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
                                        gen_endpoint $drv_handle "csc_out$drv_handle"
                                        add_prop "$cscoutnode" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                        gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                                        if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                                gen_csc_frm_buf_node $connectip $drv_handle $dts_file
                                        }
                                }
                        }
                } else {
                        dtg_warning "$drv_handle pin m_axis is not connected..check your design"
                }
        }


	}
}
proc gen_sca_frm_buf_node {outip drv_handle dts_file} {
	set bus_node [detect_bus_name $drv_handle]
	set vcap [create_node -n "vcap_sdirx$drv_handle" -p $bus_node -d $dts_file]
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
proc gen_csc_frm_buf_node {outip drv_handle dts_file} {
	set bus_node [detect_bus_name $drv_handle]
	set vcap [create_node -n "vcap_sdirx$drv_handle" -p $bus_node -d $dts_file]
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
proc add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	hsi::current_hw_instance $drv_handle
	set gpios [hsi::get_cells -filter {IP_NAME==axi_gpio}]

	foreach gpio $gpios {
		set name [hsi get_property NAME [hsi::get_cells $gpio]]
		if {[regexp ".axis" $name match]} {
			add_prop "$node" "rstaxis-connected" $gpio reference $dts_file
		}
		if {[regexp ".axi_mm" $name match]} {
			add_prop "$node" "rstaximm-connected" $gpio reference $dts_file
		}
	}
	set vdma [hsi::get_cells -filter {IP_NAME==axi_vdma}]
	if {$vdma != ""} {
		add_prop "$node" "vdma-connected" $vdma reference $dts_file
	}
	set sw [hsi::get_cells -filter {IP_NAME==axis_switch}]
	if {$sw != ""} {
		add_prop "$node" "router-connected" $sw reference $dts_file
	}
	set csc [hsi::get_cells -filter {IP_NAME==v_csc}]
	if {$csc != ""} {
		add_prop "$node" "csc-connected" $csc reference $dts_file
	}
	set deint [hsi::get_cells -filter {IP_NAME==v_deinterlacer}]
	if {$deint != ""} {
		add_prop "$node" "deint-connected" $deint reference $dts_file
	}
	set hcr [hsi::get_cells -hier -filter {IP_NAME==v_hcresampler}]
	if {$hcr != ""} {
		add_prop "$node" "hcrsmplr-connected" $hcr reference $dts_file
	}
	set hsr [hsi::get_cells  -filter {IP_NAME==v_hscaler}]
	if {$hsr != ""} {
		add_prop "$node" "hscale-connected" $hsr reference $dts_file
	}
	set letter [hsi::get_cells  -filter {IP_NAME==v_letterbox}]
	if {$letter != ""} {
		add_prop "$node" "lbox-connected" $letter reference $dts_file
	}
	set vcrs [hsi::get_cells  -filter {IP_NAME==v_vcresampler}]
	foreach vcr $vcrs {
		set name [hsi get_property NAME [hsi::get_cells $vcr]]
		if {[regexp "._o" $name match]} {
			add_prop "$node" "vcrsmplrout-connected" $vcr reference $dts_file
		}
		if {[regexp "._i" $name match]} {
			add_prop "$node" "vcrsmplrin-connected" $vcr reference $dts_file
		}
	}
	set vsc [hsi::get_cells  -filter {IP_NAME==v_vscaler}]
	if {$vsc != ""} {
		add_prop "$node" "vscale-connected" $vsc reference $dts_file
	}
	hsi::current_hw_instance
	set tpg [hsi::get_cells  -filter {IP_NAME==v_tpg}]
	if {$tpg != ""} {
		add_prop "$node" "tpg-connected" $tpg reference $dts_file
	}
	set vtc [hsi::get_cells  -filter {IP_NAME==v_tc}]
	if {$vtc != ""} {
		add_prop "$node" "vtc-connected" $vtc reference $dts_file
	}

}
