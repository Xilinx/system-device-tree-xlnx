#
# (C) Copyright 2018 Xilinx, Inc.
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

namespace eval ::tclapp::xilinx::devicetree::vproc_ss {
namespace import ::tclapp::xilinx::devicetree::common::\*
	proc generate {drv_handle} {

		set node [get_node $drv_handle]
		if {$node == 0} {
			return
		}
		set dts_file [set_drv_def_dts $drv_handle]
		set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
		if {$topology == 0} {
		#scaler
			set name [get_property NAME [hsi::get_cells -hier $drv_handle]]
			pldt append $node compatible "\ \, \"xlnx,vpss-scaler-2.2\"\ \, \"xlnx,v-vpss-scaler-2.2\"\ \, \"xlnx,vpss-scaler\""
			set ip [hsi::get_cells -hier $drv_handle]
			if 0 {
			set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
			set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,topology" $topology int $dts_file
			set v_scaler_phases [get_property CONFIG.C_V_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,v-scaler-phases" $v_scaler_phases int $dts_file
			set v_scaler_taps [get_property CONFIG.C_V_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,v-scaler-taps" $v_scaler_taps int $dts_file
			add_prop "${node}" "xlnx,num-vert-taps" $v_scaler_taps int $dts_file
			set h_scaler_phases [get_property CONFIG.C_H_SCALER_PHASES [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,h-scaler-phases" $h_scaler_phases int $dts_file
			add_prop "${node}" "xlnx,max-num-phases" $h_scaler_phases int $dts_file
			set h_scaler_taps [get_property CONFIG.C_H_SCALER_TAPS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,h-scaler-taps" $h_scaler_taps int $dts_file
			add_prop "${node}" "xlnx,num-hori-taps" $h_scaler_taps int $dts_file
			set max_cols [get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
			set max_rows [get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
			set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
			add_prop "${node}" "xlnx,pix-per-clk" $samples_per_clk int $dts_file
			set scaler_algo [get_property CONFIG.C_SCALER_ALGORITHM [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,scaler-algorithm" $scaler_algo int $dts_file
			set enable_csc [get_property CONFIG.C_ENABLE_CSC [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,enable-csc" $enable_csc string $dts_file
			set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
			set use_uram [get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
			set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
			}
			set ports_node [create_node -n "ports" -l scaler_ports$drv_handle -p $node -d $dts_file]
			add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
			add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
			set port1_node [create_node -n "port" -l scaler_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
			#add_new_dts_param "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
			add_prop "$port1_node" "reg" 1 int $dts_file 1
			add_prop "$port1_node" "xlnx,video-format" 3 int $dts_file 1
			#add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file
			set scaoutip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis"]
			if {[llength $scaoutip]} {
				if {[string match -nocase [get_property IP_NAME $scaoutip] "axis_broadcaster"]} {
					set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
					gen_endpoint $drv_handle "sca_out$drv_handle"
					add_prop "$sca_node" "remote-endpoint" $scaoutip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle "$scaoutip$drv_handle"
				}
			}
			foreach outip $scaoutip {
				if {[llength $outip]} {
					if {[string match -nocase [get_property IP_NAME $outip] "system_ila"]} {
						continue
					}
                                set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                                set ip_mem_handles [hsi::get_mem_ranges $outip]
                                if {[llength $ip_mem_handles]} {
                                        set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
                                        set sca_node [create_node -n "endpoint" -l sca_out$drv_handle -p $port1_node -d $dts_file]
					puts "sca_node:$sca_node"
                                        gen_endpoint $drv_handle "sca_out$drv_handle"
                                        add_prop "$sca_node" "remote-endpoint" $outip$drv_handle reference $dts_file
                                        gen_remoteendpoint $drv_handle "$outip$drv_handle"
                                        if {[string match -nocase [get_property IP_NAME $outip] "v_frmbuf_wr"] || [string match -nocase [get_property IP_NAME $outip] "axi_vdma"]} {
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
                                                if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"] || [string match -nocase [get_property IP_NAME $connectip] "axi_vdma"]} {
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
			set name [get_property NAME [hsi::get_cells -hier $drv_handle]]
			pldt append $node compatible "\ \, \"xlnx,vpss-csc\"\ \, \"xlnx,v-vpss-csc\""
			set ip [hsi::get_cells -hier $drv_handle]
			if 0 {
			set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,topology" $topology int $dts_file
			set color_support [get_property CONFIG.C_COLORSPACE_SUPPORT [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,colorspace-support" $color_support int $dts_file
			set csc_enable_window [get_property CONFIG.C_CSC_ENABLE_WINDOW [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,csc-enable-window" $csc_enable_window string $dts_file
			set max_cols [get_property CONFIG.C_MAX_COLS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,max-width" $max_cols int $dts_file
			set max_data_width [get_property CONFIG.C_MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,video-width" $max_data_width int $dts_file
			set max_rows [get_property CONFIG.C_MAX_ROWS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,max-height" $max_rows int $dts_file
			set num_video_comp [get_property CONFIG.C_NUM_VIDEO_COMPONENTS [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,num-video-components" $num_video_comp int $dts_file
			set samples_per_clk [get_property CONFIG.C_SAMPLES_PER_CLK [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,samples-per-clk" $samples_per_clk int $dts_file
			set topology [get_property CONFIG.C_TOPOLOGY [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,topology" $topology int $dts_file
			set use_uram [get_property CONFIG.C_USE_URAM [hsi::get_cells -hier $drv_handle]]
			add_prop "${node}" "xlnx,use-uram" $use_uram int $dts_file
			}
			set ports_node [create_node -n "ports" -l csc_ports$drv_handle -p $node -d $dts_file]
			add_prop "$ports_node" "#address-cells" 1 int $dts_file
			add_prop "$ports_node" "#size-cells" 0 int $dts_file
			set port1_node [create_node -n "port" -l csc_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
			#add_prop "${port1_node}" "/* For xlnx,video-format user needs to fill as per their requirement */" "" comment
			add_prop "$port1_node" "reg" 1 int $dts_file
			add_prop "$port1_node" "xlnx,video-format" 3 int $dts_file
			#add_prop "$port1_node" "xlnx,video-width" $max_data_width int $dts_file
			set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis"]
			if {[llength $outip]} {
				if {[string match -nocase [get_property IP_NAME $outip] "axis_broadcaster"]} {
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
                                        set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
                                        set cscoutnode [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
                                        gen_endpoint $drv_handle "csc_out$drv_handle"
                                        add_prop "$cscoutnode" "remote-endpoint" $ip$drv_handle reference $dts_file
                                        gen_remoteendpoint $drv_handle "$ip$drv_handle"
                                        if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
                                                gen_csc_frm_buf_node $ip $drv_handle $dts_file
                                        }
                                } else {
                                        if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
                                                continue
                                        }
                                        set connectip [get_connect_ip $ip $master_intf $dts_file]
                                        if {[llength $connectip]} {
                                                set cscoutnode [create_node -n "endpoint" -l csc_out$drv_handle -p $port1_node -d $dts_file]
                                                gen_endpoint $drv_handle "csc_out$drv_handle"
                                                add_prop "$cscoutnode" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                                gen_remoteendpoint $drv_handle "$connectip$drv_handle"
                                                if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
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
