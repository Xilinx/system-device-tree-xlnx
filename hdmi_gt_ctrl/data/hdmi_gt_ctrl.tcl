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
	set afreq  0
	set rfreq  0
	set transceiver [hsi get_property CONFIG.Transceiver [hsi get_cells -hier $drv_handle]]
        switch $transceiver {
                        "GTXE2" {
                                add_prop "${node}" "xlnx,transceiver" 1 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTHE2" {
                                add_prop "${node}" "xlnx,transceiver" 2 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTPE2" {
                                add_prop "${node}" "xlnx,transceiver" 3 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
                        }
                        "GTHE3" {
                                add_prop "${node}" "xlnx,transceiver" 4 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTHE4" {
                                add_prop "${node}" "xlnx,transceiver" 5 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTYE4" {
                                add_prop "${node}" "xlnx,transceiver" 6 hexint $dts_file 1
				set rfreq [get_clk_pin_freq  $drv_handle "drpclk"]
                        }
                        "GTYE5" {
                                add_prop "${node}" "xlnx,transceiver" 7 hexint $dts_file 1
				set afreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
				set rfreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
                        }
                        "GTYP" {
                                add_prop "${node}" "xlnx,transceiver" 8 hexint $dts_file 1
				set afreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
				set rfreq [ get_clk_pin_freq  $drv_handle "axi4lite_aclk"]
                        }
			default {
				puts "#error Video PHY currently supports only GTYP, GTYE5, GTYE4, GTHE4, GTHE3, GTHE2, GTPE2 and GTXE2; $transceiver not supported "
				set afreq [get_clk_pin_freq  $drv_handle "vid_phy_axi4lite_aclk"]
			}
        }
	if {$afreq == 0} {
		set afreq "100000000"
		puts "WARNING: AXIlite clock frequency information is not available in the design, \
		      for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		      If this is incorrect, the peripheral $drv_handle will be non-functional"
	}
	if {$rfreq == 0} {
		set rfreq "100000000"
		puts "WARNING: AXIlite clock frequency information is not available in the design, \
		      for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
		      If this is incorrect, the peripheral $drv_handle will be non-functional"
	}

	set axi_lite_freq [format "%X" $afreq]
	add_prop "${node}" "xlnx,axi-lite-freq-hz" $axi_lite_freq hexint $dts_file 1

	set drpclk_freq [format "%X" $rfreq]
        add_prop "${node}" "xlnx,drpclk-freq" $drpclk_freq hexint $dts_file 1

        set gt_direction [hsi get_property CONFIG.C_GT_DIRECTION [hsi get_cells -hier $drv_handle]]
        switch $gt_direction {
                        "SIMPLEX_TX" {
                                add_prop "${node}" "xlnx,gt-direction" $gt_direction  stringlist $dts_file 1
                        }
                        "SIMPLEX_RX" {
                                add_prop "${node}" "xlnx,gt-direction" $gt_direction  stringlist $dts_file 1
                        }
                        "DUPLEX" {
                                add_prop "${node}" "xlnx,gt-direction" $gt_direction  stringlist $dts_file 1
                        }
        }


    }


