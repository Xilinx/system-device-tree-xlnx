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

    proc mipi_dphy_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

	set iclk_period [hsi get_property CONFIG.C_TXPLL_CLKIN_PERIOD [hsi::get_cells -hier $drv_handle]]
        #add_prop "${node}" "xlnx,txpll-clkin-period" $iclk_period stringlist $dts_file 1

	set dphymode [hsi get_property CONFIG.C_DPHY_MODE [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "master" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 1 int $dts_file 1
        } elseif {[string match -nocase "slave" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 0 int $dts_file 1
	}
	set highaddr [hsi get_property CONFIG.C_HIGHADDR  [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" $highaddr hexint $dts_file 1
}
