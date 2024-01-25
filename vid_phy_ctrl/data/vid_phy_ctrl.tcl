#
# (C) Copyright 2018-2022 Xilinx, Inc.
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

    proc vid_phy_ctrl_generate {drv_handle} {
        set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
        set dts_file [set_drv_def_dts $drv_handle]
        pldt append $node compatible "\ \, \"xlnx,vid-phy-controller-2.1\""
        if {0} {
        set input_pixels_per_clock [hsi get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock int $dts_file
        set nidru [hsi get_property CONFIG.C_NIDRU [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,nidru" $nidru int $dts_file
        set nidru_refclk_sel [hsi get_property CONFIG.C_NIDRU_REFCLK_SEL [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,nidru-refclk-sel" $nidru_refclk_sel int $dts_file
        set Rx_No_Of_Channels [hsi get_property CONFIG.C_Rx_No_Of_Channels [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-no-of-channels" $Rx_No_Of_Channels int $dts_file
        set rx_pll_selection [hsi get_property CONFIG.C_RX_PLL_SELECTION [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-pll-selection" $rx_pll_selection int $dts_file
        set rx_protocol [hsi get_property CONFIG.C_Rx_Protocol [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-protocol" $rx_protocol int $dts_file
        set rx_refclk_sel [hsi get_property CONFIG.C_RX_REFCLK_SEL [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-refclk-sel" $rx_refclk_sel int $dts_file
        set tx_no_of_channels [hsi get_property CONFIG.C_Tx_No_Of_Channels [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-no-of-channels" $tx_no_of_channels int $dts_file
        set tx_pll_selection [hsi get_property CONFIG.C_TX_PLL_SELECTION [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-pll-selection" $tx_pll_selection int $dts_file
        set tx_protocol [hsi get_property CONFIG.C_Tx_Protocol [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-protocol" $tx_protocol int $dts_file
        set tx_refclk_sel [hsi get_property CONFIG.C_TX_REFCLK_SEL [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-refclk-sel" $tx_refclk_sel int $dts_file
        set hdmi_fast_switch [hsi get_property CONFIG.C_Hdmi_Fast_Switch [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,hdmi-fast-switch" $hdmi_fast_switch int $dts_file
        set tx_buffer_bypass [hsi get_property CONFIG.Tx_Buffer_Bypass [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-buffer-bypass" $tx_buffer_bypass int $dts_file
        set transceiver_width [hsi get_property CONFIG.Transceiver_Width [hsi::get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,transceiver-width" $transceiver_width int $dts_file
        }
        set use_gt_ch4_hdmi [hsi get_property CONFIG.C_Use_GT_CH4_HDMI [hsi::get_cells -hier $drv_handle]]
        

        set tx_no_of_channels [hsi get_property CONFIG.C_Tx_No_Of_Channels [hsi::get_cells -hier $drv_handle]]
        for {set ch 0} {$ch < $tx_no_of_channels} {incr ch} {
                set phy_node [create_node -n "vphy_lane" -u $ch -l vphy_lane$ch -p $node -d $dts_file]
                add_prop "$phy_node" "#phy-cells" 4 int $dts_file
        }
	set rfreq 0
	set afreq 0
        set transceiver [hsi get_property CONFIG.Transceiver [hsi::get_cells -hier $drv_handle]]
        switch $transceiver {
                        "GTXE2" {
                                add_prop "${node}" "xlnx,transceiver-type" 1 int $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTHE2" {
                                add_prop "${node}" "xlnx,transceiver-type" 2 int $dts_file 1
				 set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTPE2" {
                                add_prop "${node}" "xlnx,transceiver-type" 3 int $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTHE3" {
                                add_prop "${node}" "xlnx,transceiver-type" 4 int $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTHE4" {
                                add_prop "${node}" "xlnx,transceiver-type" 5 int $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTYE4" {
                                add_prop "${node}" "xlnx,transceiver-type" 6 int $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTHE5" {
                                add_prop "${node}" "xlnx,transceiver-type" 6 int $dts_file
                        }
			default {
				puts "#error \"Video PHY currently supports only GTYE4, GTHE4, GTHE3, GTHE2, GTPE2 and GTXE2; $transceiver not supported\""
			}
	}

	set afreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
	if {$afreq == 0} {
		set afreq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		      for peripheral $drv_handle . Assuming a default frequency of 100MHz. \
		      If this is incorrect, the peripheral $drv_handle will be non-functional"
	}

	if {$rfreq == 0} {
		set rfreq "100000000"
		puts "WARNING: Clock frequency information is not available in the design, \
		      for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		      If this is incorrect, the peripheral $drv_handle will be non-functional"
	}

        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $afreq hexint $dts_file 1
        add_prop "${node}" "xlnx,drpclk-freq" $rfreq hexint $dts_file 1
    }


