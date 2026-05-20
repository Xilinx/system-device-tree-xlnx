#
# (C) Copyright 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc axi_mmi_dc_generate {drv_handle} {
        # Generate properties required for mmi dc node
        set node [get_node $drv_handle]
        if {$node == 0} {
           return
        }
        set dts_file [set_drv_def_dts $drv_handle]

        set operating_mode [hsi get_property CONFIG.C_DPDC_OPERATING_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        add_prop $node "xlnx,dc-operating-mode" $operating_mode string $dts_file

        set pres_mode [hsi get_property CONFIG.C_DPDC_PRESENTATION_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        add_prop $node "xlnx,dc-presentation-mode" $pres_mode string $dts_file

        set video_intfc [hsi get_property CONFIG.C_DC_VIDEO_INTERFACE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        if {$video_intfc != "None"} {
                add_prop $node "xlnx,vid-intfc-mode" $video_intfc string $dts_file
        }

        if {$operating_mode == "DC_Functional"} {
                if {$pres_mode == "Live" || $pres_mode == "Mixed"} {

                        set video_sel [hsi get_property CONFIG.C_DC_LIVE_VIDEO_SELECT [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                        add_prop $node "xlnx,dc-live-video-select" $video_sel string $dts_file

                        set video1_mode [hsi get_property CONFIG.C_DC_LIVE_VIDEO01_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                        if {$video1_mode != "None"} {
                            add_prop $node "xlnx,dc-live-video01-mode" $video1_mode string $dts_file
                        }

                        set video2_mode [hsi get_property CONFIG.C_DC_LIVE_VIDEO02_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                        if {$video2_mode != "None"} {
                            add_prop $node "xlnx,dc-live-video02-mode" $video2_mode string $dts_file
                        }

                        set alpha_en [hsi get_property CONFIG.C_DC_LIVE_VIDEO_ALPHA_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                        if {$alpha_en == 1} {
                                add_prop $node "xlnx,dc-live-video-alpha-en" boolean $dts_file
                        }

                        set video_sdp_en [hsi get_property CONFIG.C_DC_LIVE_VIDEO_SDP_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                        if {$video_sdp_en == 1} {
                                add_prop $node "xlnx,dc-live-video-sdp-en" boolean $dts_file
                        }
                }
        }

        if {$operating_mode == "DC_Bypass"} {
                set streams [hsi get_property CONFIG.C_DPDC_STREAMS [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                add_prop $node "xlnx,dc-streams" $streams int $dts_file

                set stream0_mode [hsi get_property CONFIG.C_DPDC_STREAM0_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream0_mode != "None"} {
                        add_prop $node "xlnx,dc-stream0-mode" $stream0_mode string $dts_file
                }

                set stream0_pixel_mode [hsi get_property CONFIG.C_DPDC_STREAM0_PIXEL_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream0_pixel_mode == "Quad"} {
                        add_prop $node "xlnx,dc-stream0-pixel-mode" 4 int $dts_file
                } elseif {$stream0_pixel_mode == "Dual"} {
                        add_prop $node "xlnx,dc-stream0-pixel-mode" 2 int $dts_file
                } elseif {$stream0_pixel_mode == "Single"} {
                        add_prop $node "xlnx,dc-stream0-pixel-mode" 1 int $dts_file
                }

                set stream0_sdp_en [hsi get_property CONFIG.C_DPDC_STREAM0_SDP_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream0_sdp_en == 1} {
                        add_prop $node "xlnx,dc-stream0-sdp-en" boolean $dts_file
                }

                set stream1_mode [hsi get_property CONFIG.C_DPDC_STREAM1_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream1_mode != "None"} {
                        add_prop $node "xlnx,dc-stream1-mode" $stream1_mode string $dts_file
                }

                set stream1_pixel_mode [hsi get_property CONFIG.C_DPDC_STREAM1_PIXEL_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream1_pixel_mode == "Quad"} {
                        add_prop $node "xlnx,dc-stream1-pixel-mode" 4 int $dts_file
                } elseif {$stream1_pixel_mode == "Dual"} {
                        add_prop $node "xlnx,dc-stream1-pixel-mode" 2 int $dts_file
                } elseif {$stream1_pixel_mode == "Single"} {
                        add_prop $node "xlnx,dc-stream1-pixel-mode" 1 int $dts_file
                }

                set stream1_sdp_en [hsi get_property CONFIG.C_DPDC_STREAM1_SDP_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream1_sdp_en == 1} {
                        add_prop $node "xlnx,dc-stream1-sdp-en" boolean $dts_file
                }

                set stream2_mode [hsi get_property CONFIG.C_DPDC_STREAM2_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream2_mode != "None"} {
                        add_prop $node "xlnx,dc-stream2-mode" $stream2_mode string $dts_file
                }

                set stream2_pixel_mode [hsi get_property CONFIG.C_DPDC_STREAM2_PIXEL_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream2_pixel_mode == "Quad"} {
                        add_prop $node "xlnx,dc-stream2-pixel-mode" 4 int $dts_file
                } elseif {$stream2_pixel_mode == "Dual"} {
                        add_prop $node "xlnx,dc-stream2-pixel-mode" 2 int $dts_file
                } elseif {$stream2_pixel_mode == "Single"} {
                        add_prop $node "xlnx,dc-stream2-pixel-mode" 1 int $dts_file
                }

                set stream2_sdp_en [hsi get_property CONFIG.C_DPDC_STREAM2_SDP_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream2_sdp_en == 1} {
                        add_prop $node "xlnx,dc-stream2-sdp-en" boolean $dts_file
                }

                set stream3_mode [hsi get_property CONFIG.C_DPDC_STREAM3_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream3_mode != "None"} {
                        add_prop $node "xlnx,dc-stream3-mode" $stream3_mode string $dts_file
                }

                set stream3_pixel_mode [hsi get_property CONFIG.C_DPDC_STREAM3_PIXEL_MODE [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream3_pixel_mode == "Quad"} {
                        add_prop $node "xlnx,dc-stream3-pixel-mode" 4 int $dts_file
                } elseif {$stream3_pixel_mode == "Dual"} {
                        add_prop $node "xlnx,dc-stream3-pixel-mode" 2 int $dts_file
                } elseif {$stream3_pixel_mode == "Single"} {
                        add_prop $node "xlnx,dc-stream3-pixel-mode" 1 int $dts_file
                }

                set stream3_sdp_en [hsi get_property CONFIG.C_DPDC_STREAM3_SDP_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
                if {$stream3_sdp_en == 1} {
                        add_prop $node "xlnx,dc-stream3-sdp-en" boolean $dts_file
                }
        }

        # Set the status okay for mmi_dcdma using the mmi_dc drv_handle
        set dcdma_node [create_node -n "&mmi_dcdma" -d "pcw.dtsi" -p root]
        add_prop $dcdma_node "status" "okay" string $dts_file

        # Map mmi_dcdma to the processor address map
        set proclist [hsi::get_cells -hier -filter IP_TYPE==PROCESSOR]
        set a78 0
        set reg_val "0x0 0xedd10000 0x0 0x1000"
        foreach procc $proclist {
                set proc_name [get_ip_property $procc IP_NAME]
                # If the mappings have already been found for a78_0, then ignore the process for a78_1
                if {$a78 == 1 && ($proc_name in {"cortexa78"} )} {
                        continue
                }
                if {$proc_name in {"cortexa78"}} {
                        set a78 1
                }
                set mmi_dc_instances [hsi::get_mem_ranges -of_objects [hsi::get_cells -hier $procc] -filter INSTANCE==$drv_handle]
                if {![string_is_empty $mmi_dc_instances]} {
                        switch $proc_name {
                                "cortexr52" - "microblaze" - "microblaze_riscv" {
                                        set_memmap "mmi_dcdma" $procc $reg_val
                                }
                                "cortexa78" {
                                        set_memmap "mmi_dcdma" a53 $reg_val
                                }
                                "asu" {
                                        set_memmap "mmi_dcdma" asu $reg_val
                                }
                                default {
                                }
                        }
                }
        }

        # Check if video pins are connected on ps_wizard_0 or ps_wizard_0_mmi_0
        set video_s0_connected 0
        set video_s1_connected 0
        set live_video0_connected 0
        set live_video1_connected 0
        set aud_index -1
        set index -1
        set bypass_index -1

        set ps_wiz_cell [hsi::get_cells -hier ps_wizard_0 -quiet]
        set ps_wiz_mmi_cell [hsi::get_cells -hier ps_wizard_0_mmi_0 -quiet]

        # Data-driven video pin connectivity checks
        # Each entry: {flag_var intf_pin fallback_pin intf_label pin_label}
        set video_pin_checks {
            {video_s0_connected    video_s0       video_s0_active_video     {video_s0} {video_s0}}
            {video_s1_connected    video_s1       video_s1_active_video     {video_s1} {video_s1}}
            {live_video0_connected vp0_axi_video  s0_timing_in_active_video {live_video0 (vp0_axi_video)} {live_video0 (s0_timing_in_active_video)}}
            {live_video1_connected vp1_axi_video  vp1_video_in_tdata        {live_video1 (vp1_axi_video)} {live_video1 (vp1_video_in_tdata)}}
        }

        foreach check $video_pin_checks {
            lassign $check flag_var intf_name fallback_pin intf_label pin_label
            foreach cell [list $ps_wiz_cell $ps_wiz_mmi_cell] {
                if {$cell eq "" || [set $flag_var]} continue
                # Check interface pin
                set intf [hsi::get_intf_pins $intf_name -of_objects $cell -quiet]
                if {$intf ne ""} {
                    set intf_net [hsi::get_intf_nets -of_objects $intf -quiet]
                    if {[llength $intf_net] > 0} {
                        set $flag_var 1
                        dtg_debug "$intf_label is connected on $cell (intf)"
                        continue
                    }
                }
                # Fallback: check individual pin
                set pin [hsi::get_pins $fallback_pin -of_objects $cell -quiet]
                if {$pin ne ""} {
                    set src_pins [get_source_pins $pin]
                    if {[llength $src_pins] > 0} {
                        set $flag_var 1
                        dtg_debug "$pin_label is connected on $cell (pin)"
                    }
                }
            }
        }

        # Resolve PL clock indices from clkx5_wiz for video and audio clocks
        # Each entry: pin_name result_index_var result_ip_var
        foreach {pin_name result_idx_var result_ip_var} {
            pl_mmi_dc_2x_clk     index        connected_ip
            pl_mmi_dc_1x_clk     bypass_index bypass_connected_ip
            pl_mmi_dc_i2s_s0_clk aud_index    aud_clk_connected_ip
        } {
            set $result_idx_var -1
            set $result_ip_var ""
            set pl_pin [hsi::get_pins $pin_name -of_objects [hsi::get_cells -hier ps_wizard_0_mmi_0] -quiet]
            if {$pl_pin eq ""} {
                dtg_warning "$pin_name pin not found on ps_wizard_0_mmi_0"
                continue
            }
            set src_pin [get_source_pins [hsi::get_pins -of_objects [hsi::get_cells -hier ps_wizard_0_mmi_0] $pl_pin]]
            if {[llength $src_pin] == 0} {
                dtg_warning "$pin_name has no source pin connected"
                continue
            }
            set pinobj [hsi::get_pins $src_pin]
            if {$pinobj eq ""} continue
            set ip [hsi::get_cells -of_objects $pinobj -quiet]
            if {$ip eq "" || [hsi get_property IP_NAME $ip] != "clkx5_wiz"} {
                dtg_warning "clkx5_wiz IP is not connected to $pin_name source pin"
                continue
            }
            set $result_ip_var $ip
            set is_clk_wiz_dyn_reconfig [hsi get_property CONFIG.USE_DYN_RECONFIG $ip]
            if {$is_clk_wiz_dyn_reconfig == "false"} {
                dtg_warning "clkx5_wiz IP is not dynamic reconfigurable"
                continue
            }
            set clkout_list [split [hsi get_property CONFIG.CLKOUT_PORT $ip] ","]
            set idx [lsearch -exact $clkout_list $src_pin]
            if {$idx < 0} {
                # Check if the string ends with "_oN" (N=1-4)
                if {[string match "*_o\[1-4\]" $src_pin]} {
                    set cleaned [string range $src_pin 0 end-3]
                    set idx_list [lsearch -all $clkout_list $cleaned]
                    set drives_list [split [hsi get_property CONFIG.CLKOUT_DRIVES $ip] ","]
                    foreach i $idx_list {
                        if {[lindex $drives_list $i] eq "MBUFGCE"} {
                            set idx $i
                        }
                    }
                }
                if {$idx < 0} {
                    dtg_warning "$pin_name clock index not found in $ip"
                }
            }
            set $result_idx_var $idx
        }

        if {$index < 0 && ($live_video0_connected || $live_video1_connected || $video_s0_connected || $video_s1_connected)} {
            error "pl_mmi_dc_2x_clk has no source pin connected which is required in case of live video"
        }

        # Build clock-names and clocks dynamically based on connected PL clocks
        set clk_names [list "mmi_pll" "ps_vid_clk" "stc_ref_clk"]
        set clk_refs [list "<&versal2_clk MMIPLL>" "<&versal2_clk DC_PIXEL>" "<&versal2_clk MMI_AUX1_REF>"]

        if {$index >= 0} {
            lappend clk_names "pl_vid_func_clk"
            lappend clk_refs "<&$connected_ip $index>"
        }
        if {$bypass_index >= 0} {
            lappend clk_names "pl_vid_bypass_clk"
            lappend clk_refs "<&$bypass_connected_ip $bypass_index>"
        }
        if {$aud_index >= 0} {
            lappend clk_names "pl_aud_clk"
            lappend clk_refs "<&$aud_clk_connected_ip $aud_index>"
        }

        if {$index >= 0 || $bypass_index >= 0 || $aud_index >= 0} {
            add_prop $node clock-names "[join $clk_names " "]" stringlist $dts_file
            add_prop $node clocks "[join $clk_refs ", "]" noformating $dts_file
        }
    }
