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

    proc mipi_tx_phy_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
        pldt append $node compatible "\ \, \"xlnx,dsi\""
        set phy_mode [hsi get_property CONFIG.C_PHY_MODE [hsi::get_cells -hier $drv_handle]]
        puts "phy_mode = $phy_mode"
        if {[string match -nocase $phy_mode "dphy"]} {
		add_prop "$node" "xlnx,phy-mode" 1 int $dts_file 1
        } else {
		add_prop "$node" "xlnx,phy-mode" 0 int $dts_file 1
	}
    }
