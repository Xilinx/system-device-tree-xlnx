#
# (C) Copyright 2024-2025 Advanced Micro Devices, Inc. All Rights Reserved.
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
proc preprocess_gen_reset_gpio {drv_handle node dts_file} {
	set ip [hsi get_cells -hier $drv_handle]
	set pins [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier $ip] "ap_rst_n"]]
	foreach pin $pins {
	set sink_periph [::hsi::get_cells -of_objects $pin]
		if {[llength $sink_periph]} {
			set sink_ip [hsi get_property IP_NAME $sink_periph]
			if {[string match -nocase $sink_ip "axi_gpio"]} {
				add_prop "$node" "reset-gpios" "$sink_periph 0 1" reference $dts_file
			}
			if {$sink_ip in {"xlslice" "ilslice"}} {
				set gpio [hsi get_property CONFIG.DIN_FROM $sink_periph]
				set pins [hsi::get_pins -of_objects [hsi::get_nets -of_objects [hsi::get_pins -of_objects $sink_periph "Din"]]]
			foreach pin $pins {
				set periph [::hsi::get_cells -of_objects $pin]
				if {[llength $periph]} {
					set ip [hsi get_property IP_NAME $periph]
					set proc_type [get_hw_family]
					if {$proc_type == "versal"} {
						if { $ip in { "versal_cips" "ps_wizard" }} {
							# As in versal there is only bank0 for MIOs
							set gpio [expr $gpio + 26]
							add_prop "$node" "reset-gpios" "gpio0 $gpio 0" reference $dts_file
							break
						}
					}
					if {$proc_type == "zynqmp"} {
						if {[string match -nocase $ip "zynq_ultra_ps_e"]} {
							set gpio [expr $gpio + 78]
							add_prop "$node" "reset-gpios" "gpio $gpio 0" reference $dts_file
							break
						}
					}
					if {[string match -nocase $ip "axi_gpio"]} {
						add_prop "$node" "reset-gpios" "$periph $gpio 1" reference $dts_file
					}
					} else {
						dtg_warning "periph for the pin:$pin is NULL $periph...check the design"
					}
				}
			}
		} else {
			dtg_warning "peripheral for the pin:$pin is NULL $sink_periph...check the design"
		}
	}
}

proc preprocess_generate {drv_handle} {
	set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	set ip_name [hsi get_property IP_NAME [hsi get_cells -hier $drv_handle]]
	pldt unset $node compatible
	pldt set   $node compatible "\"xlnx,preprocess-1.0\""
	# pldt replace $node compatible "\ \, \"xlnx,preprocess-1.0\""

	preprocess_gen_reset_gpio "$drv_handle" "$node" $dts_file
	set rgb2rgba [hsi get_property CONFIG.RGB2RGBA_X [hsi::get_cells -hier $drv_handle]]
	set int8 [hsi get_property CONFIG.XF_INT8_X [hsi::get_cells -hier $drv_handle]]
	set bf_16 [hsi get_property CONFIG.XF_BF16_X [hsi::get_cells -hier $drv_handle]]
	set fp_16 [hsi get_property CONFIG.XF_FP16_X [hsi::get_cells -hier $drv_handle]]
	set fp_32 [hsi get_property CONFIG.XF_FP32_X [hsi::get_cells -hier $drv_handle]]

	set vid_formats ""
	if {$rgb2rgba == 1} {
		if {$int8 == 1} {
			append vid_formats " " "rgba8888"
		}
		if {$bf_16 == 1} {
			append vid_formats " " "rgba_bf16161616"
		}
		if {$fp_16 == 1} {
			append vid_formats " " "rgba_fp16161616"
		}
		if {$fp_32 == 1} {
			append vid_formats " " "rgba32323232"
		}
	} else {
		if {$int8 == 1} {
			append vid_formats " " "bgr888"
		}
		if {$bf_16 == 1} {
			append vid_formats " " "rgb_bf161616"
		}
		if {$fp_16 == 1} {
			append vid_formats " " "rgb_fp161616"
		}
		if {$fp_32 == 1} {
			append vid_formats " " "rgb323232"
		}
	}

	if {![string match $vid_formats ""]} {
		add_prop "${node}" "xlnx,vid-formats" $vid_formats stringlist $dts_file
	}

	# generating ports node for preprocess ip
	set preprocess_ports_node [create_node -n "ports" -l preprocess_ports$drv_handle -p $node -d $dts_file]
	add_prop "$preprocess_ports_node" "#address-cells" 1 int $dts_file
	add_prop "$preprocess_ports_node" "#size-cells" 0 int $dts_file
	# find input ip which is connected to s_axis_video
	set inip [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "s_axis_video"]
	if {[llength $inip]} {
		if {[string match -nocase [hsi get_property IP_NAME $inip] "axis_subset_converter"]} {
			set inip [get_connected_stream_ip [hsi get_cells -hier $inip] "S_AXIS"]
		}
		if {[string match -nocase [hsi get_property IP_NAME $inip] "axis_data_fifo"]} {
			set inip [get_connected_stream_ip [hsi get_cells -hier $inip] "S_AXIS"]
		}
		# generating port0 node for preprocess ip
		set port0_node [create_node -n "port" -l preprocess_port0$drv_handle -u 0 -p $preprocess_ports_node -d $dts_file]
		add_prop "$port0_node" "reg" 0 int $dts_file
		set preprocess_port_node_endpoint [create_node -n "endpoint" -l $drv_handle$inip -p $port0_node -d $dts_file]

		if {[string match -nocase [hsi get_property IP_NAME $inip] "v_tpg"]} {
			# generating remote-endpoint  only when it is connected to v_proc_ss ip
			add_prop "$preprocess_port_node_endpoint" "remote-endpoint" "tpg_out$inip" reference $dts_file
		} else  {
			add_prop "$preprocess_port_node_endpoint" "remote-endpoint" preprocess_in$drv_handle reference $dts_file
		}
	}
	# find scanoutip which is connected to m_axis_video
	set scanoutip [get_connected_stream_ip [hsi get_cells -hier $drv_handle] "m_axis_video"]
	set port1_node [create_node -n "port" -l preprocess_port1$drv_handle -u 1 -p $preprocess_ports_node -d $dts_file]
	add_prop "$port1_node" "reg" 1 int $dts_file
	if {[llength $scanoutip]} {
		# generating port1 node for preprocess ip
		if {[string match -nocase [hsi get_property IP_NAME $scanoutip] "axis_broadcaster"]} {
			set port1_node_endpoint [create_node -n "endpoint" -l $drv_handle$scanoutip -p $port1_node -d $dts_file]
			gen_endpoint $drv_handle "$drv_handle$scanoutip"
			add_prop "$port1_node_endpoint" "remote-endpoint" $scanoutip$drv_handle reference $dts_file
			gen_remoteendpoint $drv_handle "$scanoutip$drv_handle"
		}
		if {[string match -nocase [hsi get_property IP_NAME $scanoutip] "axis_switch"]} {
			set ip_mem_handles [hsi::get_mem_ranges $scanoutip]
			if {[llength $ip_mem_handles]} {
				set port1_node_endpoint [create_node -n "endpoint" -l $drv_handle$scanoutip -p $port1_node -d $dts_file]
				gen_axis_switch_in_endpoint $drv_handle "$drv_handle$scanoutip"
				add_prop "$port1_node_endpoint" "remote-endpoint" $scanoutip$drv_handle reference $dts_file
				gen_axis_switch_in_remo_endpoint $drv_handle "$scanoutip$drv_handle"
			}
		}
	}
	foreach outip $scanoutip {
		if {[llength $outip]} {
			if {[string match -nocase [hsi get_property IP_NAME $outip] "system_ila"]} {
				continue
			}
			set master_intf [::hsi::get_intf_pins -of_objects [hsi get_cells -hier $outip] -filter {TYPE==MASTER || TYPE ==INITIATOR}]
			set ip_mem_handles [hsi::get_mem_ranges $outip]
			if {[llength $ip_mem_handles]} {
				set port1_node_endpoint [create_node -n "endpoint" -l $drv_handle$outip -p $port1_node -d $dts_file]
				if {[string match -nocase [hsi get_property IP_NAME $outip] "v_proc_ss"]} {
					# generating remote-endpoint  only when it is connected to v_proc_ss ip
					add_prop "$port1_node_endpoint" "remote-endpoint" "v_proc_ss$drv_handle" reference $dts_file
				} else {
					gen_endpoint $drv_handle "$drv_handle$outip"
					add_prop "$port1_node_endpoint" "remote-endpoint" $outip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle "$outip$drv_handle"
				}
			} else {
				set connectip [get_connect_ip $outip $master_intf $dts_file]
				if {[llength $connectip]} {
					set port1_node_endpoint [create_node -n "endpoint" -l preprocess_out$drv_handle -p $port1_node -d $dts_file]
					gen_endpoint $drv_handle "$drv_handle$outip"
					add_prop "$port1_node_endpoint" "remote-endpoint" $connectip$drv_handle reference $dts_file
					gen_remoteendpoint $drv_handle "$connectip$drv_handle"
				}
			}
		} else {
			dtg_warning "$drv_handle pin m_axis_video is not connected..check your design"
		}
	}
}
