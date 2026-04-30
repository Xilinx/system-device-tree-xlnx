#
# (C) Copyright 2018-2022 Xilinx, Inc.
# (C) Copyright 2022-2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc dp_gt_ctrl_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

	set compatible [get_comp_str $drv_handle]
	pldt append $node compatible "\ \, \"xlnx,gt-quad-base-1.1\" "

	# Generate one xfmc node per dp_gt_ctrl instance
	set bus_node "amba_pl: amba_pl"
	set xfmc_node [create_node -n "xv_fmc$drv_handle" -l "xfmc$drv_handle" -p $bus_node -d $dts_file]
	add_prop $xfmc_node "compatible" "xilinx-vfmc" string $dts_file 1

	# Get the number of Rx and Tx interfaces
	set Rx_No_Of_Interfaces [hsi get_property CONFIG.INTF0_NO_OF_LANES [hsi::get_cells -hier $drv_handle]]
	set Tx_No_Of_Interfaces [hsi get_property CONFIG.INTF1_NO_OF_LANES [hsi::get_cells -hier $drv_handle]]

	# Create PHY nodes for both Rx and Tx interfaces
	for {set ch 0} {$ch < $Rx_No_Of_Interfaces} {incr ch} {
		create_rx_phy_node "rx" $ch $drv_handle $node $dts_file
	}
	for {set ch 0} {$ch < $Tx_No_Of_Interfaces} {incr ch} {
		create_tx_phy_node "tx" $ch $drv_handle $node $dts_file
	}
    }


proc create_rx_phy_node {channel_type ch drv_handle node dts_file} {
	set pinname "INTF0_RX${ch}_GT_IP_interface"
	set channelip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $pinname]
	if {[llength $channelip] && [llength [hsi::get_intf_pins -of_objects $channelip]]} {
		set phy_node [create_node -n "${pinname}${channelip}" -l "${drv_handle}${channel_type}phy_lane${ch}" -p $node -d $dts_file]
		add_prop "$phy_node" "#phy-cells" 4 int $dts_file 1
	}
}

proc create_tx_phy_node {channel_type ch drv_handle node dts_file} {
	set pinname "INTF1_TX${ch}_GT_IP_interface"
	set channelip [get_connected_stream_ip [hsi::get_cells -hier $drv_handle] $pinname]
	if {[llength $channelip] && [llength [hsi::get_intf_pins -of_objects $channelip]]} {
		set phy_node [create_node -n "${pinname}${channelip}" -l "${drv_handle}${channel_type}phy_lane${ch}" -p $node -d $dts_file]
		add_prop "$phy_node" "#phy-cells" 4 int $dts_file 1
	}
}
