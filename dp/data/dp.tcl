#
# (C) Copyright 2014-2022 Xilinx, Inc.
# (C) Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc dp_generate {drv_handle} {
        set node [get_node $drv_handle]
        dp_generate_dp_param $drv_handle $node
    }

    proc dp_generate_dp_param {drv_handle node} {
        set periph_list [hsi::get_cells -hier]
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        foreach periph $periph_list {
        set zynq_ultra_ps [hsi get_property IP_NAME $periph]
                if {[string match -nocase $zynq_ultra_ps "zynq_ultra_ps_e"] } {
                        set dp_sel [hsi get_property CONFIG.PSU__DP__LANE_SEL [hsi::get_cells -hier $periph]]
                        set mode [lindex $dp_sel 0]
                        set lan_sel [lindex $dp_sel 1]
                        set dp_freq [hsi get_property CONFIG.PSU__DP__REF_CLK_FREQ [hsi::get_cells -hier $periph]]
                        set dp_freq "${dp_freq}000000"
                        set ref_clk_list [hsi get_property CONFIG.PSU__DP__REF_CLK_SEL [hsi::get_cells -hier $periph]]
                        regsub -all {[^0-9]} [lindex $ref_clk_list 1] "" val
                        if {[string match -nocase $mode "Single"]} {
                                if {[string match -nocase $lan_sel "Lower"]} {
                                        set lan_name "dp-phy0"
                                        set lan_phy_type "psgtr 1 6 0 $val"
                                        set_drv_prop $drv_handle phy-names "$lan_name" $node stringlist
                                        set_drv_prop $drv_handle phys "$lan_phy_type" $node reference
                                } else {
                                        set lan_name "dp-phy0"
                                        set lan_phy_type "psgtr 3 6 0 $val"
                                        set_drv_prop $drv_handle phy-names "$lan_name" $node stringlist
                                        set_drv_prop $drv_handle phys "$lan_phy_type" $node reference
                                }
                                set_drv_prop $drv_handle xlnx,max-lanes 1 $node int
                        } elseif {[string match -nocase $mode "Dual"]} {
                                if {[string match -nocase $lan_sel "Lower"]} {
                                        set lan0_phy_type "psgtr 1 6 0 $val"
                                        set lan1_phy_type "psgtr 0 6 1 $val"
                                        add_prop $node phy-names "dp-phy0  dp-phy1" stringlist $dts_file
                                        set phy_ids "$lan0_phy_type>, <&$lan1_phy_type"
                                        set_drv_prop $drv_handle phys "$phy_ids" $node reference
                                } else {
                                        set lan0_phy_type "psgtr 3 6 0 $val"
                                        set lan1_phy_type "psgtr 2 6 1 $val"
                                        add_prop $node phy-names "dp-phy0  dp-phy1" stringlist $dts_file
                                        set phy_ids "$lan0_phy_type>, <&$lan1_phy_type"
                                        set_drv_prop $drv_handle phys "$phy_ids" $node reference
                                }
                                set_drv_prop $drv_handle xlnx,max-lanes 2 $node int
                        }
                }
        }
        global env
        set path $env(REPO)

        set drvname [get_drivers $drv_handle]

        set common_file "$path/device_tree/data/config.yaml"
        set mainline_ker [get_user_config $common_file -mainline_kernel]
        if {[string match -nocase $mainline_ker "none"]} {
                set dp_list "zynqmp_dp_snd_pcm0 zynqmp_dp_snd_pcm1 zynqmp_dp_snd_card0 zynqmp_dp_snd_codec0"
                foreach dp_name ${dp_list} {
                        add_prop $node "status" "okay" string "pcw.dtsi"
                }
        }
    }

    proc dp_rx_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set audio_channels [hsi get_property CONFIG.AUDIO_CHANNELS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,audio-channels" $audio_channels int $dts_file
        set audio_enable [hsi get_property CONFIG.AUDIO_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dts_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dts_file
        set hdcp22_enable [hsi get_property CONFIG.HDCP22_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,hdcp22-enable" $hdcp22_enable int $dts_file
        set hdcp_enable [hsi get_property CONFIG.HDCP_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,hdcp-enable" $hdcp_enable int $dts_file
        set include_fec_ports [hsi get_property CONFIG.INCLUDE_FEC_PORTS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dts_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,lane-count" $lane_count int $dts_file
        set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
        set link_rate [expr {${link_rate} * 1000}]
        set link_rate [expr int ($link_rate)]
        add_prop "${node}" "xlnx,linkrate" $link_rate int $dts_file
        set mode [hsi get_property CONFIG.MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mode" $mode int $dts_file
        set num_streams [hsi get_property CONFIG.NUM_STREAMS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-streams" $num_streams int $dts_file
        set phy_data_width [hsi get_property CONFIG.PHY_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,phy-data-width" $phy_data_width int $dts_file
        set pixel_mode [hsi get_property CONFIG.PIXEL_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,pixel-mode" $pixel_mode int $dts_file
        set sim_mode [hsi get_property CONFIG.SIM_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,sim-mode" $sim_mode string $dts_file
        set video_interface [hsi get_property CONFIG.VIDEO_INTERFACE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,video-interface" $video_interface int $dts_file
    }

    proc dp_tx_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        set num_audio_channels [hsi get_property CONFIG.Number_of_Audio_Channels [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-audio-channels" $num_audio_channels int $dts_file
        set audio_enable [hsi get_property CONFIG.AUDIO_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,audio-enable" $audio_enable int $dts_file
        set bits_per_color [hsi get_property CONFIG.BITS_PER_COLOR [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,bits-per-color" $bits_per_color int $dts_file
        set hdcp22_enable [hsi get_property CONFIG.HDCP22_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,hdcp22-enable" $hdcp22_enable int $dts_file
        set hdcp_enable [hsi get_property CONFIG.HDCP_ENABLE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,hdcp-enable" $hdcp_enable int $dts_file
        set include_fec_ports [hsi get_property CONFIG.INCLUDE_FEC_PORTS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,include-fec-ports" $include_fec_ports int $dts_file
        set lane_count [hsi get_property CONFIG.LANE_COUNT [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,lane-count" $lane_count int $dts_file
        set link_rate [hsi get_property CONFIG.LINK_RATE [hsi::get_cells -hier $drv_handle]]
        set link_rate [expr {${link_rate} * 1000}]
        set link_rate [expr int ($link_rate)]
        add_prop "${node}" "xlnx,linkrate" $link_rate int $dts_file
        set mode [hsi get_property CONFIG.MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,mode" $mode int $dts_file
        set num_streams [hsi get_property CONFIG.NUM_STREAMS [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,num-streams" $num_streams int $dts_file
        set phy_data_width [hsi get_property CONFIG.PHY_DATA_WIDTH [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,phy-data-width" $phy_data_width int $dts_file
        set pixel_mode [hsi get_property CONFIG.PIXEL_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,pixel-mode" $pixel_mode int $dts_file
        set sim_mode [hsi get_property CONFIG.SIM_MODE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,sim-mode" $sim_mode string $dts_file
        set video_interface [hsi get_property CONFIG.VIDEO_INTERFACE [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,video-interface" $video_interface int $dts_file
        set vtcip [hsi get_cells -hier -filter {IP_NAME == "v_tc"}]
        if {[llength $vtcip]} {
                set baseaddr [hsi get_property CONFIG.C_BASEADDR [hsi get_cells -hier $vtcip]]
                if {[llength $baseaddr]} {
                        add_prop "${node}" "xlnx,vtc-offset" "$baseaddr" int $dts_file
                }
        }
    }


