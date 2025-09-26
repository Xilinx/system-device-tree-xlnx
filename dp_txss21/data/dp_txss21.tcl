#
# (C) Copyright 2020-2022 Xilinx, Inc.
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

proc dp_txss21_generate {drv_handle} {
	set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }

	dp_tx_21_add_hier_instances $drv_handle

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
	set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
	if {[llength $freq] == 0} {
		set freq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1
}



proc dp_tx_21_add_hier_instances {drv_handle} {

	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	set ip_subcores [dict create]
	dict set ip_subcores "v_dual_splitter" "dual-splitter"
	dict set ip_subcores "dptx" "dp21"
	dict set ip_subcores "hdcp" "hdcp14"
	dict set ip_subcores "hdcp22_tx_dp" "hdcp22"

	foreach ip [dict keys $ip_subcores] {
		set ip_handle [set_ip_handles_for_ss_subcores $ip $drv_handle]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

	set timers [set_ip_handles_for_ss_subcores axi_timer $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_timer}
	#processor_hier_0_axi_timer_0 dp_rx_hier_0_v_dp_rxss1_0_timer dp_tx_hier_0_v_dp_txss1_0_timer

	if {[string_is_empty $timers]} {
		add_prop "$node" "hdcptimer-present" 0 int $dts_file
	} else {
		foreach timer $timers {
			set name [hsi get_property NAME [hsi::get_cells -hier $timer]]
			if {[regexp "tx" $name match]} {
				add_prop "$node" "hdcptimer-present" 1 int $dts_file
				add_prop "$node" "hdcptimer-connected" $timer reference $dts_file
			} else {
				add_prop "$node" "hdcptimer-present" 0 int $dts_file
			}
		}
	}
	set vtcs [set_ip_handles_for_ss_subcores v_tc $drv_handle]
	#hsi::get_cells -hier -filter {IP_NAME==axi_time_tcr}
	#dp_tx_hier_0_v_dp_txss1_0_vtc1 dp_tx_hier_0_v_dp_txss1_0_vtc2 dp_tx_hier_0_v_dp_txss1_0_vtc3 dp_tx_hier_0_v_dp_txss1_0_vtc4

	if {[string_is_empty $vtcs]} {
		add_prop "$node" "vtc1-present" 0 int $dts_file
		add_prop "$node" "vtc2-present" 0 int $dts_file
		add_prop "$node" "vtc3-present" 0 int $dts_file
		add_prop "$node" "vtc4-present" 0 int $dts_file
	} else {
		foreach vtc $vtcs {
			if {[regexp "_vtc1" $vtc match]} {
				add_prop "$node" "vtc1-present" 1 int $dts_file
				add_prop "$node" "vtc1-connected" $vtc reference $dts_file
			}
			if {[regexp "_vtc2" $vtc match]} {
				add_prop "$node" "vtc2-present" 1 int $dts_file
				add_prop "$node" "vtc2-connected" $vtc reference $dts_file
			}
			if {[regexp "_vtc3" $vtc match]} {
				add_prop "$node" "vtc3-present" 1 int $dts_file
				add_prop "$node" "vtc3-connected" $vtc reference $dts_file
			}
			if {[regexp "_vtc4" $vtc match]} {
				add_prop "$node" "vtc4-present" 1 int $dts_file
				add_prop "$node" "vtc4-connected" $vtc reference $dts_file
			}
		}
	}

}
