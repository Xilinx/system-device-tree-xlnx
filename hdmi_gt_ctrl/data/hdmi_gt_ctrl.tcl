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

    proc hdmi_gt_ctrl_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

        set err_irq_en [hsi get_property CONFIG.C_Err_Irq_En [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,err-irq-en" $err_irq_en int $dts_file
        set tx_frl_refclk_sel [hsi get_property CONFIG.C_TX_FRL_REFCLK_SEL [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-frl-refclk-sel" $tx_frl_refclk_sel int $dts_file
        set rx_frl_refclk_sel [hsi get_property CONFIG.C_RX_FRL_REFCLK_SEL [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-frl-refclk-sel" $rx_frl_refclk_sel int $dts_file
        set input_pixels_per_clock [hsi get_property CONFIG.C_INPUT_PIXELS_PER_CLOCK [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,input-pixels-per-clock" $input_pixels_per_clock int $dts_file
        set nidru [hsi get_property CONFIG.C_NIDRU [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,nidru" $nidru int $dts_file
        set use_gt_ch4_hdmi [hsi get_property CONFIG.C_Use_GT_CH4_HDMI [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,use-gt-ch4-hdmi" $use_gt_ch4_hdmi int $dts_file
        set nidru_refclk_sel [hsi get_property CONFIG.C_NIDRU_REFCLK_SEL [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,nidru-refclk-sel" $nidru_refclk_sel int $dts_file
        set Rx_No_Of_Channels [hsi get_property CONFIG.C_Rx_No_Of_Channels [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-no-of-channels" $Rx_No_Of_Channels int $dts_file
        set rx_pll_selection [hsi get_property CONFIG.C_RX_PLL_SELECTION [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-pll-selection" $rx_pll_selection int $dts_file
        set rx_protocol [hsi get_property CONFIG.C_Rx_Protocol [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-protocol" $rx_protocol int $dts_file
        set rx_refclk_sel [hsi get_property CONFIG.C_RX_REFCLK_SEL [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,rx-refclk-sel" $rx_refclk_sel int $dts_file
        set tx_pll_selection [hsi get_property CONFIG.C_TX_PLL_SELECTION [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-pll-selection" $tx_pll_selection int $dts_file
        set tx_protocol [hsi get_property CONFIG.C_Tx_Protocol [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-protocol" $tx_protocol int $dts_file
        set tx_refclk_sel [hsi get_property CONFIG.C_TX_REFCLK_SEL [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-refclk-sel" $tx_refclk_sel int $dts_file
        set tx_no_of_channels [hsi get_property CONFIG.C_Tx_No_Of_Channels [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-no-of-channels" $tx_no_of_channels int $dts_file
        set tx_buffer_bypass [hsi get_property CONFIG.Tx_Buffer_Bypass [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,tx-buffer-bypass" $tx_buffer_bypass int $dts_file
        set transceiver_width [hsi get_property CONFIG.Transceiver_Width [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,transceiver-width" $transceiver_width int $dts_file
        set hdmi_fast_switch [hsi get_property CONFIG.C_Hdmi_Fast_Switch [hsi get_cells -hier $drv_handle]]
        add_prop "${node}" "xlnx,hdmi-fast-switch" $hdmi_fast_switch int $dts_file

        for {set ch 0} {$ch < $tx_no_of_channels} {incr ch} {
                set phy_node [create_node -n "vphy_lane" -u $ch -l vphy_lane$ch -p $node -d $dts_file]
                add_prop "$phy_node" "#phy-cells" 4 int $dts_file
        }
        set transceiver [hsi hsi get_property CONFIG.Transceiver [hsi get_cells -hier $drv_handle]]
        switch $transceiver {
                        "GTXE2" {
                                add_prop "${node}" "xlnx,transceiver-type" 1 int $dts_file
                        }
                        "GTHE2" {
                                add_prop "${node}" "xlnx,transceiver-type" 2 int $dts_file
                        }
                        "GTPE2" {
                                add_prop "${node}" "xlnx,transceiver-type" 3 int $dts_file
                        }
                        "GTHE3" {
                                add_prop "${node}" "xlnx,transceiver-type" 4 int $dts_file
                        }
                        "GTHE4" {
                                add_prop "${node}" "xlnx,transceiver-type" 5 int $dts_file
                        }
                        "GTYE4" {
                                add_prop "${node}" "xlnx,transceiver-type" 6 int $dts_file
                        }
                        "GTYE5" {
                                add_prop "${node}" "xlnx,transceiver-type" 7 int $dts_file
                        }
        }

        set gt_direction [hsi hsi get_property CONFIG.C_GT_DIRECTION [hsi get_cells -hier $drv_handle]]
        switch $gt_direction {
                        "SIMPLEX_TX" {
                                add_prop "${node}" "xlnx,gt-direction" 1  int $dts_file
                        }
                        "SIMPLEX_RX" {
                                add_prop "${node}" "xlnx,gt-direction" 2  int $dts_file
                        }
                        "DUPLEX" {
                                add_prop "${node}" "xlnx,gt-direction" 3  int $dts_file
                        }
        }
    }


