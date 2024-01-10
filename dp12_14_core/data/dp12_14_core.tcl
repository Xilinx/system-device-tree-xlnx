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

proc dp12_14_core_generate {drv_handle} {
	set node [get_node $drv_handle]
        if {$node == 0} {
                return
        }
	set dts_file [set_drv_def_dts $drv_handle]
	set protocol_slection [hsi get_property VLNV [hsi::get_cells -hier $drv_handle]]

	#IP name : displayport is common for dp12 rx, dp 12 tx, dp14 rx and dp14 tx. for this first we are checking its DP 12 or DP 14. later in loop we are checking flow direction. if flow is 0 then its TX otherwise its RX.
	if { $protocol_slection == "xilinx.com:ip:displayport:7.0"} {

		set tx_or_rx [hsi get_property CONFIG.C_FLOW_DIRECTION [hsi::get_cells -hier $drv_handle]]

		if { $tx_or_rx == 0} {
			#currently no specific code for it
		} elseif { $tx_or_rx == 1} {
			#currently no specific code for it
		} else {
			puts "invalid condition. Expected IP name : displayport is common for dp12 rx, dp 12 tx, dp14 rx and dp14 tx. for this first we are checking its DP 12 or DP 14. later in loop we are checking flow direction. if flow is 0 then its TX otherwise its RX "
			die
		}

		#common code for both RX and TX
		set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
		if {[llength $freq] == 0} {
			set freq "100000000"
			puts "WARNING: Clock frequency information is not available in the design, \
			for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
			If this is incorrect, the peripheral $drv_handle will be non-functional"
		}
	        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1
	} elseif { $protocol_slection == "xilinx.com:ip:displayport:8.1"} {

		#IP name : displayport is common for dp12 rx, dp 12 tx, dp14 rx and dp14 tx. for this first we are checking its DP 12 or DP 14. later in loop we are checking flow direction. if flow is 0 then its TX otherwise its RX.
		set tx_or_rx [hsi get_property CONFIG.C_FLOW_DIRECTION [hsi::get_cells -hier $drv_handle]]

		if { $tx_or_rx == 0} {
			#currently no specific code for it
		} elseif { $tx_or_rx == 1} {
			#currently no specific code for it
		} else {
			puts "invalid condition. Expected IP name : displayport is common for dp12 rx, dp 12 tx, dp14 rx and dp14 tx. for this first we are checking its DP 12 or DP 14. later in loop we are checking flow direction. if flow is 0 then its TX otherwise its RX "
			die
		}

		#common code for both RX and TX
		set freq [get_clk_pin_freq  $drv_handle "S_AXI_ACLK"]
		if {[llength $freq] == 0} {
			set freq "100000000"
			puts "WARNING: Clock frequency information is not available in the design, \
			for peripheral $drv_handle. Assuming a default frequency of 100MHz. \
			If this is incorrect, the peripheral $drv_handle will be non-functional"
		}
	        add_prop "${node}" "xlnx,axi-aclk-freq-mhz" $freq hexint $dts_file 1
	} else {
		puts "Invalid condition. Expected ip name is displayport & protocol selection should be neither DP_1_2 or DP_1_4"
		die
	}


 }
