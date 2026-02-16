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
    proc ai_layout_formatter_wr_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

		pldt unset $node compatible
		pldt set   $node compatible "\"xlnx,ai-layout-formatter-wr-v1\""
        set ip [hsi::get_cells -hier $drv_handle]
		set rgb2rgba [hsi get_property CONFIG._XF_RGBA_X [hsi::get_cells -hier $drv_handle]]
        set int8 [hsi get_property CONFIG.XF_INT8_X [hsi::get_cells -hier $drv_handle]]
        set bf_16 [hsi get_property CONFIG.XF_BF16_X [hsi::get_cells -hier $drv_handle]]
        set fp_16 [hsi get_property CONFIG.XF_FP16_X [hsi::get_cells -hier $drv_handle]]
        set fp_32 [hsi get_property CONFIG.XF_FP32_X [hsi::get_cells -hier $drv_handle]]

        set nhwc [hsi get_property CONFIG._XF_NHWC_X [hsi::get_cells -hier $drv_handle]]
        set nchw [hsi get_property CONFIG._XF_NCHW_X [hsi::get_cells -hier $drv_handle]]
        set hcwnc4 [hsi get_property CONFIG._XF_HCWNC4_X [hsi::get_cells -hier $drv_handle]]
        set hcwnc8 [hsi get_property CONFIG._XF_HCWNC8_X [hsi::get_cells -hier $drv_handle]]
	set has_y_uv12_420 [hsi get_property CONFIG.HAS_Y_UV12_420 [hsi::get_cells -hier $drv_handle]]

        set vid_formats ""
        if {$rgb2rgba} {
			if {$int8 == 1} {
				if {$nhwc == 1} {
					append vid_formats " " "rgba8888"
				}
				if {$nchw} {
					append vid_formats " " "rgba8888m"
					append vid_formats " " "RGB_24M_4_3"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_8_4_4"
					append vid_formats " " "HCWNC4_8_4_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_8_4_4"
					append vid_formats " " "HCWNC8_8_4_3"
				}
			}
			if {$bf_16 == 1} {

				if {$nhwc == 1} {
					append vid_formats " " "rgba_bf16161616"
				}
				if {$nchw} {
					append vid_formats " " "rgba_bf16161616m"
					append vid_formats " " "RGB_BF48M_4_3"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_BF16_4_4"
					append vid_formats " " "HCWNC4_BF16_4_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_BF16_4_4"
					append vid_formats " " "HCWNC8_BF16_4_3"
				}
			}
			if {$fp_16 == 1} {

				if {$nhwc == 1} {
					append vid_formats " " "rgba_fp16161616"
				}
				if {$nchw} {
					append vid_formats " " "rgba_fp16161616m"
					append vid_formats " " "RGB_FP48M_4_3"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_FP16_4_4"
					append vid_formats " " "HCWNC4_FP16_4_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_FP16_4_4"
					append vid_formats " " "HCWNC8_FP16_4_3"
				}
			}
			if {$fp_32 == 1} {
				if {$nhwc == 1} {
					append vid_formats " " "rgba32323232"
				}
				if {$nchw} {
					append vid_formats " " "rgba32323232m"
					append vid_formats " " "RGB_323232M_4_3"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_32_4_4"
					append vid_formats " " "HCWNC4_32_4_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_32_4_4"
					append vid_formats " " "HCWNC8_32_4_3"
				}
			}
		} else {

			if {$int8 == 1} {

				if {$nhwc == 1} {
					append vid_formats " " "rgb888"
					append vid_formats " " "bgr888"
				}
				if {$nchw} {
					append vid_formats " " "rgb888m"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_8_3_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_8_3_3"
				}
			}
			if {$bf_16 == 1} {

				if {$nhwc == 1} {
					append vid_formats " " "rgb_bf16"
				}
				if {$nchw} {
					append vid_formats " " "rgb_bf16m"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_BF16_3_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_BF16_3_3"
				}
			}
			if {$fp_16 == 1} {
				if {$nhwc == 1} {
					append vid_formats " " "rgb_fp16"
				}
				if {$nchw} {
					append vid_formats " " "rgb_fp16m"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_FP16_3_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_FP16_3_3"
				}
			}
			if {$fp_32 == 1} {
				if {$nhwc == 1} {
					append vid_formats " " "rgb323232"
				}
				if {$nchw} {
					append vid_formats " " "rgb323232m"
				}
				if {$hcwnc4} {
					append vid_formats " " "HCWNC4_32_3_3"
				}
				if {$hcwnc8} {
					append vid_formats " " "HCWNC8_32_3_3"
				}
			}
		}

		if {![string match $vid_formats ""]} {
			add_prop "${node}" "xlnx,vid-formats" $vid_formats stringlist $dts_file
		}

        set samples_per_clk [hsi get_property CONFIG.NPPCX_X [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,pixels-per-clock" $samples_per_clk int $dts_file
        set dma_align [expr $samples_per_clk * 8]
        add_prop "$node" "xlnx,dma-align" $dma_align int $dts_file

        set dma_addr_width [hsi get_property CONFIG.AXIMM_ADDR_WIDTH_X [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,dma-addr-width" $dma_addr_width int $dts_file
        add_prop "$node" "#dma-cells" 1 int $dts_file
        set max_rows [hsi get_property CONFIG.HEIGHT_X [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,max-height" $max_rows int $dts_file
        set max_cols [hsi get_property CONFIG.WIDTH_X [hsi::get_cells -hier $drv_handle]]
        add_prop "$node" "xlnx,max-width" $max_cols int $dts_file

	ai_layout_formatter_wr_gen_gpio_reset $drv_handle $node $dts_file

        set frmbuf_inips [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] "s_axis_video"]
        foreach inip $frmbuf_inips {
                if {[string match -nocase [hsi get_property IP_NAME $inip] "v_mix"] } {
                        set ports_node [create_node -n "ports" -l frmbuf_wr_ports$drv_handle -p $node -d $dts_file]
                        add_prop "$ports_node" "#address-cells" 1 int $dts_file
                        add_prop "$ports_node" "#size-cells" 0 int $dts_file
                        set port0_node [create_node -n "port" -l frmbuf_wr$drv_handle -u 0 -p $ports_node -d $dts_file]
                        add_prop "$port0_node" "reg" 0 int $dts_file
                        set frmbuf_crtc [create_node -n "endpoint" -l ai_layout_formatter_wr$drv_handle -p $port0_node -d $dts_file]
                        add_prop "$frmbuf_crtc" "remote-endpoint" "mixer_out$inip" reference $dts_file
                } elseif {[string match -nocase [hsi get_property IP_NAME $inip] "ISPPipeline_accel"] } {
                        ai_layout_formatter_wr_gen_frmbuf_node $inip $drv_handle $dts_file
                } elseif {[string match -nocase [hsi get_property IP_NAME $inip] "preprocess_accel"] } {
                        ai_layout_formatter_wr_gen_frmbuf_node $inip $drv_handle $dts_file
                }
        }

    }

proc ai_layout_formatter_wr_gen_frmbuf_node {ip drv_handle dts_file} {
        set proctype [get_hw_family]
        set bus_node [detect_bus_name $drv_handle]
        set vcap [create_node -n "vcap_$drv_handle" -p $bus_node -d $dts_file]
        add_prop $vcap "compatible" "xlnx,video" string $dts_file
        add_prop $vcap "dmas" "$drv_handle 0" reference $dts_file
        add_prop $vcap "dma-names" "port0" string $dts_file
        set vcap_ports_node [create_node -n "ports" -l vcap_ports$drv_handle -p $vcap -d $dts_file]
        add_prop "$vcap_ports_node" "#address-cells" 1 int $dts_file
        add_prop "$vcap_ports_node" "#size-cells" 0 int $dts_file
        if {$proctype == "ps7_cortexa9"} {
                #Workaround for issue (TBF)
                set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -p $vcap_ports_node -d $dts_file]
        } else {
                set vcap_port_node [create_node -n "port" -l vcap_port$drv_handle -u 0 -p $vcap_ports_node -d $dts_file]
        }
        add_prop "$vcap_port_node" "reg" 0 int $dts_file
        add_prop "$vcap_port_node" "direction" input string $dts_file
        set vcap_in_node [create_node -n "endpoint" -l $drv_handle$ip -p $vcap_port_node -d $dts_file]
        add_prop "$vcap_in_node" "remote-endpoint" $ip$drv_handle reference $dts_file
}


    proc ai_layout_formatter_wr_gen_gpio_reset {drv_handle node dts_file} {
	set pins [get_source_pins [hsi get_pins -of_objects [hsi get_cells -hier [hsi get_cells -hier $drv_handle]] "ap_rst_n"]]
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
						dtg_warning "$drv_handle peripheral is NULL for the $pin $periph"
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
			dtg_warning "$drv_handle peripheral is NULL for the $pin $sink_periph"
		}
	}
}
