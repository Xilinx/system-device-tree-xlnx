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
                add_prop $node "xlnx,dc-stream1-pixel-mode" $stream1_pixel_mode string $dts_file
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
                add_prop $node "xlnx,dc-stream2-pixel-mode" $stream2_pixel_mode string $dts_file
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
                add_prop $node "xlnx,dc-stream3-pixel-mode" $stream3_pixel_mode string $dts_file
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
    }
