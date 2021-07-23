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
	set keyval [pldt append $node compatible "\ \, \"xlnx,mipi-csi2-rx-subsystem-5.0\""]
	set dphy_en_reg_if [get_property CONFIG.DPY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $dphy_en_reg_if "true"]} {
		add_prop "${node}" "xlnx,dphy-present" boolean $dts_file
	}
       	set en_vcx [get_property CONFIG.C_EN_VCX [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $en_vcx "true"]} {
       		add_prop "${node}" "xlnx,en-vcx" "" boolean $dts_file 1
	}
	set en_csi_v2_0 [get_property CONFIG.C_EN_CSI_V2_0 [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $en_csi_v2_0 "true"]} {
       		add_prop "${node}" "xlnx,en-csi-v2-0" "" boolean $dts_file 1
	}
	set dphy_lanes [get_property CONFIG.C_DPHY_LANES [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,max-lanes" $dphy_lanes int $dts_file
       	for {set lane 1} {$lane <= $dphy_lanes} {incr lane} {
       	        lappend lanes $lane
	}
	set en_csi_v2_0 [get_property CONFIG.C_EN_CSI_V2_0 [hsi::get_cells -hier $drv_handle]]
	set en_vcx [get_property CONFIG.C_EN_VCX [hsi::get_cells -hier $drv_handle]]
	set cmn_vc [get_property CONFIG.CMN_VC [hsi::get_cells -hier $drv_handle]]
	if {$en_csi_v2_0 == true && $en_vcx == true && [string match -nocase $cmn_vc "ALL"]} {
		add_prop "${node}" "xlnx,vc" 16  int $dts_file
	} elseif {$en_csi_v2_0 == true && $en_vcx == false && [string match -nocase $cmn_vc "ALL"]} {
		add_prop "${node}" "xlnx,vc" 4  int $dts_file
	} elseif {$en_csi_v2_0 == false && [string match -nocase $cmn_vc "ALL"]} {
		add_prop "${node}" "xlnx,vc" 4  int $dts_file
	}
	if {[llength $en_csi_v2_0] == 0} {
		add_prop "${node}" "xlnx,vc" $cmn_vc int $dts_file
	}
	set cmn_pxl_format [get_property CONFIG.CMN_PXL_FORMAT [hsi::get_cells -hier $drv_handle]]
	gen_pixel_format $node $cmn_pxl_format $dts_file
	set csi_en_activelanes [get_property CONFIG.C_CSI_EN_ACTIVELANES [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $csi_en_activelanes "true"]} {
		add_prop "${node}" "xlnx,en-active-lanes" boolean $dts_file
	}
	set cmn_inc_vfb [get_property CONFIG.CMN_INC_VFB [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $cmn_inc_vfb "true"]} {
		add_prop "${node}" "xlnx,vfb" boolean $dts_file
	}
	set cmn_num_pixels [get_property CONFIG.CMN_NUM_PIXELS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,ppc" "$cmn_num_pixels" int $dts_file
	set axis_tdata_width [get_property CONFIG.AXIS_TDATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,axis-tdata-width" "$axis_tdata_width" int $dts_file

	set ports_node [create_node -n "ports" -l mipi_csi_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file
	add_prop "$ports_node" "#size-cells" 0 int $dts_file
	set port_node [create_node -n "port" -l mipi_csi_port0$drv_handle -u 1 -p $ports_node -d $dts_file]
	add_prop "$port_node" "reg" 1 int $dts_file
	add_prop "$port_node" "xlnx,video-format" 12 int $dts_file
	add_prop "$port_node" "xlnx,video-width" 8 int $dts_file
	add_prop "$port_node" "xlnx,cfa-pattern" rggb string $dts_file

	set port1_node [create_node -n "port" -l mipi_csi_port1$drv_handle -u 0 -p $ports_node -d $dts_file]
	add_prop "$port1_node" "reg" 0 int $dts_file
#        add_new_dts_param "${port1_node}" "/* Fill cfa-pattern=rggb for raw data types, other fields video-format,video-width user needs to fill */" "" comment
#       add_new_dts_param "${port1_node}" "/* User need to add something like remote-endpoint=<&out> under the node csiss_in:endpoint */" "" comment
add_prop "$port1_node" "xlnx,video-format" 12 int $dts_file
add_prop "$port1_node" "xlnx,video-width" 8 int $dts_file
add_prop "$port1_node" "xlnx,cfa-pattern" rggb string $dts_file
set csiss_rx_node [create_node -n "endpoint" -l mipi_csi_in$drv_handle -p $port1_node -d $dts_file]
if {[llength $lanes]} {
       add_prop "${csiss_rx_node}" "data-lanes" $lanes int $dts_file
}
set outip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "VIDEO_OUT"]
if {[llength $outip]} {
        if {[string match -nocase [get_property IP_NAME $outip] "axis_broadcaster"]} {
                set mipi_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
                gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
                add_prop "$mipi_node" "remote-endpoint" $outip$drv_handle reference $dts_file
                gen_remoteendpoint $drv_handle "$outip$drv_handle"
        }
}
foreach ip $outip {
	if {[llength $ip]} {
                set intfpins [::hsi::get_intf_pins -of_objects [hsi::get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
                set ip_mem_handles [hsi::get_mem_ranges $ip]
                if {[llength $ip_mem_handles]} {
                        set base [string tolower [get_property BASE_VALUE $ip_mem_handles]]
                        set csi_rx_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
                        gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
                        add_prop "$csi_rx_node" "remote-endpoint" $ip$drv_handle reference $dts_file
                        gen_remoteendpoint $drv_handle $ip$drv_handle
                        if {[string match -nocase [get_property IP_NAME $ip] "v_frmbuf_wr"]} {
                                gen_frmbuf_node $ip $drv_handle $dts_file
                        }
                } else {
                        set connectip [get_connect_ip $ip $intfpins $dts_file]
                        if {[llength $connectip]} {
                                set csi_rx_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
                                gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
                                add_prop "$csi_rx_node" "remote-endpoint" $connectip$drv_handle reference $dts_file
                                gen_remoteendpoint $drv_handle $connectip$drv_handle
                                if {[string match -nocase [get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
                                        gen_frmbuf_node $connectip $drv_handle $dts_file
                                }
                        }
                }
        }
}
gen_gpio_reset $drv_handle $node

}
proc gen_pixel_format {node pxl_format dts_file} {
set pixel_format ""
switch $pxl_format {
       "YUV4228B" {
               set pixel_format 0x1e
       }
       "YUV42210B" {
               set pixel_format 0x1f
       }
       "RGB444" {
               set pixel_format 0x20
       }
       "RGB555" {
               set pixel_format 0x21
       }
       "RGB565" {
               set pixel_format 0x22
       }
       "RGB666" {
               set pixel_format 0x23
       }
       "RGB888" {
               set pixel_format 0x24
       }
       "RAW6" {
               set pixel_format 0x28
       }
       "RAW7" {
               set pixel_format 0x29
       }
       "RAW8" {
               set pixel_format 0x2a
       }
       "RAW10" {
               set pixel_format 0x2b
       }
       "RAW12" {
               set pixel_format 0x2c
       }
       "RAW14" {
               set pixel_format 0x2d
       }
       "RAW16" {
               set pixel_format 0x2e
       }
       "RAW20" {
               set pixel_format 0x2f
       }
}
if {[llength $pixel_format]} {
       add_prop "${node}" "xlnx,csi-pxl-format" $pixel_format hex $dts_file
}
}
proc gen_frmbuf_node {outip drv_handle dts_file} {
#        set dt_overlay [get_property CONFIG.dt_overlay [get_os]]
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
add_prop "$vcap_in_node" "remote-endpoint" mipi_csirx_out$drv_handle reference $dts_file
}


proc gen_gpio_reset {drv_handle node} {
set dts_file [set_drv_def_dts $drv_handle]
set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier [hsi::get_cells -hier $drv_handle]] "video_aresetn"]]
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
                                       #set proc_type [get_sw_proc_prop IP_NAME]
					set proc_type [get_hw_family]
                                       if {[string match -nocase $proc_type "versal"] } {
                                               if {[string match -nocase $ip "versal_cips"]} {
                                                       # As versal has only bank0 for MIOs
                                                       set gpio [expr $gpio + 26]
                                                       add_prop "$node" "video-reset-gpios" "gpio0 $gpio 1" reference $dts_file
                                                       break
                                               }
                                       }
                                       if {[string match -nocase $proc_type "zynqmp"] || [string match -nocase $proc_type "zynquplus"] } {
                                               if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
                                                       set gpio [expr $gpio + 78]
                                                       add_prop "$node" "video-reset-gpios" "gpio $gpio 1" reference $dts_file
                                                       break
                                               }
                                       }
                                       if {[string match -nocase $ip "axi_gpio"]} {
                                               add_prop "$node" "video-reset-gpios" "$periph $gpio 0 1" reference $dts_file
                                       }
                               } else {
                                       dtg_warning "$drv_handle peripheral is NULL for the $pin $periph"
                               }
                       }
              }
       } else {
               dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
       }
}
}

