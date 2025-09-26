#
# (C) Copyright 2024 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc mipi_dsi2_rx_ss_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }

	set dphy_en_reg_if [hsi get_property CONFIG.DPHY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dphy-en-reg-if" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dphy-en-reg-if" 0 int $dts_file 1
	}
	set dphymode [hsi get_property CONFIG.C_DPHY_MODE [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "master" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 1 int $dts_file 1
        } elseif {[string match -nocase "slave" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 0 int $dts_file 1
	}

        set dsi_datatype [hsi get_property CONFIG.DSI_DATATYPE [hsi::get_cells -hier $drv_handle]]
	set pixel [pixel_format $dsi_datatype]
        add_prop "$node" "xlnx,dsi-datatype" $pixel hexint $dts_file 1

	set highaddr [hsi get_property CONFIG.C_HIGHADDR  [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" $highaddr hexint $dts_file 1

	dsi2rx_add_hier_instances $drv_handle

    }

proc dsi2rx_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set subsystem_base_addr [get_baseaddr $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]

	#Example :
	#hsi::get_cells -hier -filter {IP_NAME==mipi_dsi2_rx_ctrl}
	#dsirx_0_rx
	#

	set ip_subcores [dict create]
	dict set ip_subcores "mipi_dsi2_rx_ctrl" "dsi-rx"
	dict set ip_subcores "mipi_dphy" "dphy"

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

}
proc pixel_format {pxl_format} {
	set pixel_format ""
            switch $pxl_format {
                   "RGB565" {
                           set pixel_format 0x0E
                   }
                   "RGB666_P" {
                           set pixel_format 0x1E
                   }
                   "RGB666_L" {
                           set pixel_format 0x2E
                   }
                   "RGB888" {
                           set pixel_format 0x3E
                   }
                   "Compressed" {
                           set pixel_format 0x0B
                   }
            }
	return $pixel_format
}
