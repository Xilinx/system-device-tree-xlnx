#
# (C) Copyright 2018-2021 Xilinx, Inc.
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

proc generate {drv_handle} {
	set node [get_node $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}

	set tx_no_of_channels [get_property CONFIG.C_Tx_No_Of_Channels [hsi::get_cells -hier $drv_handle]]
	for {set ch 0} {$ch < $tx_no_of_channels} {incr ch} {
		set phy_node [create_node -n "vphy_lane" -u $ch -l vphy_lane$ch -p $node -d $dts_file]
		add_prop "$phy_node" "#phy-cells" 4 int $dts_file
	}
	set transceiver [get_property CONFIG.Transceiver [hsi::get_cells -hier $drv_handle]]
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
}
