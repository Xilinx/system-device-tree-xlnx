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
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
	pldt append $node compatible "\ \, \"xlnx,v-demosaic\""
       	set s_axi_ctrl_addr_width [get_property CONFIG.C_S_AXI_CTRL_ADDR_WIDTH [hsi::get_cells -hier $drv_handle]]
	set s_axi_ctrl_data_width [get_property CONFIG.C_S_AXI_CTRL_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	set max_data_width [get_property CONFIG.MAX_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	set max_rows [get_property CONFIG.MAX_ROWS [hsi::get_cells -hier $drv_handle]]
	add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
	set ports_node [create_node -n "ports" -l demosaic_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
	set port1_node [create_node -n "port" -l demosaic_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
	add_prop "$port1_node" "reg" 1 int $dts_file 1
	add_prop "$port1_node" "xlnx,cfa-pattern" rggb string $dts_file 1

	set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "m_axis_video"]
        set outipname [get_property IP_NAME $outip]
        set valid_mmip_list "mipi_csi2_rx_subsystem v_tpg v_hdmi_rx_ss v_smpte_uhdsdi_rx_ss v_smpte_uhdsdi_tx_ss v_demosaic v_gamma_lut v_proc_ss v_frmbuf_rd v_frmbuf_wr v_hdmi_tx_ss v_uhdsdi_audio audio_formatter i2s_receiver i2s_transmitter mipi_dsi_tx_subsystem v_mix v_multi_scaler v_scenechange"
        if {[lsearch  -nocase $valid_mmip_list $outipname] >= 0} {
		foreach ip $outip {
			if {[llength $ip]} {
		        	set master_intf [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
		        	set ip_mem_handles [hsi::get_mem_ranges $ip]
		        	if {[llength $ip_mem_handles]} {
		               	 	set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
		                	set demonode [create_node -n "endpoint" -l demo_out$drv_handle -p $port1_node -d $dts_file]
		                	gen_endpoint $drv_handle "demo_out$drv_handle"
		                	add_prop "$demonode" "remote-endpoint" $ip$drv_handle reference $dts_file
		                	gen_remoteendpoint $drv_handle "$ip$drv_handle"
		                	if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
		                        	gen_frmbuf_wr_node $ip $drv_handle $dts_file
		                	}
		        	} else {
		                	if {[string match -nocase [get_property IP_NAME $ip] "system_ila"]} {
		                       	 continue
		               		}
		                	set connectip [get_connect_ip $ip $master_intf $dts_file]
		                	if {[llength $connectip]} {
		                      	  	set demonode [create_node -n "endpoint" -l demo_out$drv_handle -p $port1_node -d $dts_file]
		                       		 gen_endpoint $drv_handle "demo_out$drv_handle"
		                       	 	add_prop "$demonode" "remote-endpoint" $connectip$drv_handle reference $dts_file
		                       	 	gen_remoteendpoint $drv_handle "$connectip$drv_handle"
		                        	if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
		                                	gen_frmbuf_wr_node $connectip $drv_handle $dts_file
		                        	}
		               		}
		        	}
			} else {
                		dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
        		}
		}
	}
	gen_gpio_reset $drv_handle $node
}

proc gen_frmbuf_wr_node {outip drv_handle dts_file} {
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
	gen_endpoint $drv_handle "demo_out$drv_handle"
	add_prop "$vcap_in_node" "remote-endpoint" demo_out$drv_handle reference $dts_file
	gen_remoteendpoint $drv_handle "$outip$drv_handle"
}

proc gen_gpio_reset {drv_handle node} {
	set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "ap_rst_n"]]
	set proc_type [get_hw_family]
	foreach pin $pins {
        set sink_periph [hsi::get_cells -of_objects $pin]
        if {[llength $sink_periph]} {
                set sink_ip [get_property IP_NAME $sink_periph]
                if {[string match -nocase $sink_ip "xlslice"]} {
                        set gpio [get_property CONFIG.DIN_FROM $sink_periph]
                        set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
                        foreach pin $pins {
                                set periph [hsi::get_cells -of_objects $pin]
                                if {[llength $periph]} {
                                        set ip [get_property IP_NAME $periph]
                                        if {[string match -nocase $proc_type "versal"] } {
                                                if {[string match -nocase $ip "versal_cips"]} {
                                                        # As versal has only bank0 for MIOs
                                                        set gpio [expr $gpio + 26]
                                                        add_prop "$node" "reset-gpios" "gpio0 $gpio 1" reference "pl.dtsi"
                                                        break
                                                }
                                        }
                                        if {[string match -nocase $proc_type "psu_cortexa53"] } {
                                                if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
                                                        set gpio [expr $gpio + 78]
                                                        add_prop "$node" "reset-gpios" "gpio $gpio 1" reference "pl.dtsi"
                                                        break
                                                }
                                        }
                                        if {[string match -nocase $ip "axi_gpio"]} {
                                                add_prop "$node" "reset-gpios" "$periph $gpio 0 1" reference "pl.dtsi"
                                        }
                                } else {
                                        dtg_warning "$drv_handle: peripheral is NULL for the $pin $periph"
                                }
                        }
                }
        } else {
                dtg_warning "$drv_handle: peripheral is NULL for the $pin $sink_periph"
        }
}
}
