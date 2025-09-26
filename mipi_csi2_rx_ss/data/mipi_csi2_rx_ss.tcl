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

proc mipi_csi2_rx_ss_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,mipi-csi2-rx-subsystem-5.0\""
	set dphy_en_reg_if [hsi get_property CONFIG.DPY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dpy-en-reg-if" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dpy-en-reg-if" 0 int $dts_file 1
	}

	set cmn_inc_iic [hsi get_property CONFIG.CMN_INC_IIC [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $cmn_inc_iic]} {
                add_prop "${node}" "xlnx,cmn-inc-iic" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $cmn_inc_iic]} {
                add_prop "${node}" "xlnx,cmn-inc-iic" 0 int $dts_file 1
	}

	set csi_en_crc [hsi get_property CONFIG.C_CSI_EN_CRC [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $csi_en_crc]} {
                add_prop "${node}" "xlnx,csi-en-crc" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $csi_en_crc]} {
                add_prop "${node}" "xlnx,csi-en-crc" 0 int $dts_file 1
	}

	set en_csi_v2_0 [hsi get_property CONFIG.C_EN_CSI_V2_0 [hsi::get_cells -hier $drv_handle]]
        set en_vcx [hsi get_property CONFIG.C_EN_VCX [hsi::get_cells -hier $drv_handle]]

	if  {[string match -nocase "true" $en_vcx]} {
                add_prop "${node}" "xlnx,en-vcx" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $en_vcx]} {
                add_prop "${node}" "xlnx,en-vcx" 0 int $dts_file 1
	}

        set cmn_vc [hsi get_property CONFIG.CMN_VC [hsi::get_cells -hier $drv_handle]]

	if  {[string match -nocase "true" $en_csi_v2_0]} {
                add_prop "${node}" "xlnx,en-csi-v2" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $en_csi_v2_0]} {
                add_prop "${node}" "xlnx,en-csi-v2" 0 int $dts_file 1
	}

	set cphymode [hsi get_property CONFIG.C_PHY_MODE [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "dphy" $cphymode]} {
                add_prop "${node}" "xlnx,mipi-rx-phy-mode" 1 int $dts_file 1
        } else {
                add_prop "${node}" "xlnx,mipi-rx-phy-mode" 0 int $dts_file 1
	}

	set csi_en_activelanes [hsi get_property CONFIG.C_CSI_EN_ACTIVELANES [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase "true" $csi_en_activelanes]} {
		add_prop "${node}" "xlnx,en-active-lanes" 1 boolean $dts_file 1
	} else {
		add_prop "${node}" "xlnx,en-active-lanes" 0 boolean $dts_file 1
	}

	set dphy_lanes [hsi get_property CONFIG.C_DPHY_LANES [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,max-lanes" $dphy_lanes int $dts_file
	for {set lane 1} {$lane <= $dphy_lanes} {incr lane} {
		lappend lanes $lane
	}

	set cmn_inc_vfb [hsi get_property CONFIG.CMN_INC_VFB [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $cmn_inc_vfb "true"]} {
		add_prop "${node}" "xlnx,vfb" "" boolean $dts_file
	}

	set cmn_num_pixels [hsi get_property CONFIG.CMN_NUM_PIXELS [hsi::get_cells -hier $drv_handle]]
		add_prop "${node}" "xlnx,ppc" "$cmn_num_pixels" int $dts_file

	set en_csi_v2_0 [hsi get_property CONFIG.C_EN_CSI_V2_0 [hsi get_cells -hier $drv_handle]]
	set en_vcx [hsi get_property CONFIG.C_EN_VCX [hsi get_cells -hier $drv_handle]]
	set cmn_vc [hsi get_property CONFIG.CMN_VC [hsi get_cells -hier $drv_handle]]
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

        if { [string match -nocase "true" $en_csi_v2_0] && [string match -nocase "true" $en_vcx] && [string match -nocase $cmn_vc "ALL"]} {
                add_prop "${node}" "xlnx,cmn-vc" 16  int $dts_file 1
        } elseif {[string match -nocase "true" $en_csi_v2_0] && [string match -nocase "false" $en_vcx]  && [string match -nocase $cmn_vc "ALL"]} {
                add_prop "${node}" "xlnx,cmn-vc" 4  int $dts_file 1
        } elseif {[string match -nocase "false" $en_csi_v2_0] && [string match -nocase $cmn_vc "ALL"]} {
                add_prop "${node}" "xlnx,cmn-vc" 4  int $dts_file 1
        }
        if {[llength $en_csi_v2_0] == 0} {
                add_prop "${node}" "xlnx,cmn-vc" $cmn_vc int $dts_file 1
        }

	set highaddr [hsi get_property CONFIG.C_HIGHADDR  [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" $highaddr hexint $dts_file 1

	set emb [hsi get_property CONFIG.CSI_EMB_NON_IMG  [hsi get_cells -hier $drv_handle]]
	if  {[string match -nocase "true" $emb]} {
		add_prop "${node}" "xlnx,csi-emb-non-img" 1 int $dts_file 1
	} elseif  {[string match -nocase "false" $emb]} {
		add_prop "${node}" "xlnx,csi-emb-non-img" 0 int $dts_file 1
	}

	set cmn_pxl_format [hsi get_property CONFIG.CMN_PXL_FORMAT [hsi::get_cells -hier $drv_handle]]
	set cmn_pixel [mipi_csi2_rx_gen_pixel_format $cmn_pxl_format $node $dts_file]
	add_prop "${node}" "xlnx,cmn-pxl-format" $cmn_pixel hexint $dts_file 1

	set ports_node [create_node -n "ports" -l mipi_csi_ports$drv_handle -p $node -d $dts_file]
	add_prop "$ports_node" "#address-cells" 1 int $dts_file 1
	add_prop "$ports_node" "#size-cells" 0 int $dts_file 1
	set port_node [create_node -n "port" -l mipi_csi_port1$drv_handle -u 1 -p $ports_node -d $dts_file]
	add_prop "$port_node" "reg" 1 int $dts_file 1
	add_prop "$port_node" "xlnx,cfa-pattern" "rggb" int $dts_file 1
	add_prop "$port_node" "xlnx,video-format" 12 int $dts_file 1
	add_prop "$port_node" "xlnx,video-width" 8 int $dts_file 1

	set port0_node [create_node -n "port" -l mipi_csi_port0$drv_handle -u 0 -p $ports_node -d $dts_file]
	add_prop "$port0_node" "reg" 0 int $dts_file 1
	add_prop "$port0_node" "xlnx,cfa-pattern" "rggb" int $dts_file 1
	add_prop "$port0_node" "xlnx,video-format" 12 int $dts_file 1
	add_prop "$port0_node" "xlnx,video-width" 8 int $dts_file 1
#	add_prop "${port0_node}" "/* User need to add something like remote-endpoint=<&out> under the node csiss_in:endpoint */" "" comment $dts_file 1
	set csiss_rx_node [create_node -n "endpoint" -l mipi_csi_in$drv_handle -p $port0_node -d $dts_file]
	if {[llength $lanes]} {
		add_prop "${csiss_rx_node}" "data-lanes" $lanes intlist $dts_file 1
	}

	set outip [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "VIDEO_OUT"]
	foreach ip_type $outip {
		if {[llength $ip_type]} {
			if {[string match -nocase [hsi get_property IP_NAME $ip_type] "axis_ila"]} {
				continue
			}
			if {[string match -nocase [hsi get_property IP_NAME $ip_type] "axis_broadcaster"]} {
				set mipi_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
				gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
				add_prop "$mipi_node" "remote-endpoint" $ip_type$drv_handle reference $dts_file 1
				gen_remoteendpoint $drv_handle "$ip_type$drv_handle"
			}
			if {[string match -nocase [hsi get_property IP_NAME $ip_type] "axis_switch"]} {
				set ip_mem_handles [hsi get_mem_ranges $ip_type]
				if {[llength $ip_mem_handles]} {
					set mipi_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
					gen_axis_switch_in_endpoint $drv_handle "mipi_csirx_out$drv_handle"
					add_prop "$mipi_node" "remote-endpoint" $ip_type$drv_handle reference $dts_file 1
					gen_axis_switch_in_remo_endpoint $drv_handle "$ip_type$drv_handle"
				}
			}
		}
	}

	foreach ip $outip {
		if {[llength $ip]} {
			set intfpins [hsi get_intf_pins -of_objects [hsi get_cells -hier $ip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi get_mem_ranges $ip]
		        if {[string match -nocase [hsi get_property IP_NAME $ip] "axi_vdma"]} {
                               #puts "VDMA use case is not supported for SDT linux flow with mipi csi2 rx IP"
                                break
                        }
			if {[llength $ip_mem_handles]} {
				set base [string tolower [hsi get_property BASE_VALUE $ip_mem_handles]]
				set csi_rx_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
				gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
				add_prop "$csi_rx_node" "remote-endpoint" $ip$drv_handle reference $dts_file 1
				gen_remoteendpoint $drv_handle $ip$drv_handle
				if {[string match -nocase [hsi get_property IP_NAME $ip] "v_frmbuf_wr"]} {
						mipi_csi2_rx_ss_gen_frmbuf_node $ip $drv_handle $dts_file
                                }
			} else {
				set connectip [get_connect_ip $ip $intfpins $dts_file]
				if {[llength $connectip]} {
					if {[string match -nocase [hsi get_property IP_NAME $connectip] "axis_switch"]} {
						set ip_mem_handles [hsi get_mem_ranges $connectip]
						if {[llength $ip_mem_handles]} {
							set mipi_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
							gen_axis_switch_in_endpoint $drv_handle "mipi_csirx_out$drv_handle"
							add_prop "$mipi_node" "remote-endpoint" $connectip$drv_handle reference $dts_file 1
							gen_axis_switch_in_remo_endpoint $drv_handle "$connectip$drv_handle"
						}

					} elseif {[string match -nocase [hsi get_property IP_NAME $connectip] "ISPPipeline_accel"]} {
						set isppipeline_node [create_node -n "endpoint" -l isppipeline_in$connectip -p $port_node -d $dts_file]
						add_prop "$isppipeline_node" "remote-endpoint" $connectip$drv_handle reference $dts_file 1

					} else {
					set csi_rx_node [create_node -n "endpoint" -l mipi_csirx_out$drv_handle -p $port_node -d $dts_file]
					gen_endpoint $drv_handle "mipi_csirx_out$drv_handle"
					add_prop "$csi_rx_node" "remote-endpoint" $connectip$drv_handle reference $dts_file 1
					gen_remoteendpoint $drv_handle $connectip$drv_handle
					if {[string match -nocase [hsi get_property IP_NAME $connectip] "v_frmbuf_wr"]} {
						mipi_csi2_rx_ss_gen_frmbuf_node $connectip $drv_handle $dts_file
					}
				}
			}
		}
	}
	}
	csirx2_add_hier_instances $drv_handle
	mipi_csi2_rx_ss_gen_gpio_reset $drv_handle $node $dts_file
}

proc csirx2_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set subsystem_base_addr [get_baseaddr $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set dphy_en_reg_if [hsi get_property CONFIG.DPY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]

	#Example :
	#hsi::get_cells -hier -filter {IP_NAME==mipi_csi2_rx_ctrl}
	#csirx_0_rx
	#

	set ip_subcores [dict create]
	dict set ip_subcores "mipi_csi2_rx_ctrl" "csirx"
	dict set ip_subcores "mipi_dphy" "dphy"
	dict set ip_subcores "mipi_rx_phy" "rxphy"
	foreach ip [dict keys $ip_subcores] {

		if { $ip eq "mipi_dphy" || $ip eq "mipi_rx_phy" } {
			if {[string match -nocase "false" $dphy_en_reg_if]} {
				continue
			}
		}
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
proc mipi_csi2_rx_gen_pixel_format {pxl_format node dts_file} {
	set pixel_format ""
            switch $pxl_format {
                   "YUV422_8bit" {
                           set pixel_format 0x18
                   }
                   "YUV422_10bit" {
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
		add_prop "$node" "xlnx,csi-pxl-format" $pixel_format hexint $dts_file
	}
	return $pixel_format
}

proc mipi_csi2_rx_ss_gen_frmbuf_node {outip drv_handle dts_file} {
	global env
	set path $env(CUSTOM_SDT_REPO)
	set common_file "$path/device_tree/data/config.yaml"
	set bus_node "amba_pl: amba_pl"
        set vcap [create_node -n "vcap_$drv_handle" -p $bus_node -d $dts_file]
        add_prop $vcap "compatible" "xlnx,video" string $dts_file
        add_prop $vcap "dmas" "$outip 0" reference $dts_file
        add_prop $vcap "dma-names" "port0" string $dts_file
        set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d  $dts_file]
        add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
        add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
        set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
        add_prop "$vcap_port_node" "reg" 0 int $dts_file
        add_prop "$vcap_port_node" "direction" input string $dts_file
        set vcap_in_node [create_node -n "endpoint" -l $outip$drv_handle -p $vcap_port_node -d $dts_file]
        add_prop "$vcap_in_node" "remote-endpoint" mipi_csirx_out$drv_handle reference $dts_file
}

proc mipi_csi2_rx_ss_gen_gpio_reset {drv_handle node dts_file} {
	set pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier [hsi get_cells -hier $drv_handle]] "video_aresetn"]]
	foreach pin $pins {
		set sink_periph [hsi get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [hsi get_property IP_NAME $sink_periph]
			if {$sink_ip in {"xlslice" "ilslice"}} {
				set gpio [hsi get_property CONFIG.DIN_FROM $sink_periph]
				set pins [hsi get_pins -of_objects [hsi get_nets -of_objects [hsi get_pins -of_objects $sink_periph "Din"]]]
				foreach pin $pins {
					set periph [hsi get_cells -of_objects $pin]
					if {[llength $periph]} {
						set ip [hsi get_property IP_NAME $periph]
						if { $ip in { "versal_cips" "ps_wizard" }} {
							# As versal has only bank0 for MIOs
							set gpio [expr $gpio + 26]
							add_prop "$node" "video-reset-gpios" "gpio0 $gpio 1" reference $dts_file
							break
						}
						if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
							set gpio [expr $gpio + 78]
							add_prop "$node" "video-reset-gpios" "gpio $gpio 1" reference $dts_file
							break
						}
						if {[string match -nocase $ip "axi_gpio"]} {
							add_prop "$node" "video-reset-gpios" "$periph $gpio 1" reference $dts_file
						}
					} else {
						dtg_warning "$drv_handle peripheral is NULL for the $pin $periph"
					}
				}
			} else {
				# If no axi-slice connected b/w axi_gpio and reset pin
				# add video-reset-gpios property with gpio number 0
				if {[string match -nocase $sink_ip "axi_gpio"]} {
					set gpio "0"
					set periph [hsi get_cells -of_objects $pin]
					if {[llength $gpio]} {
						add_prop "$node" "video-reset-gpios" "$periph $gpio 1" reference $dts_file
					}
				}
			}
		} else {
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}
}
