#
# (C) Copyright 2018 Xilinx, Inc.
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

namespace eval mipi_csi2_rx { 
proc generate {drv_handle} {
	set node [get_node $drv_handle]
#	set node [gen_peripheral_nodes $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	if {$node == 0} {
		return
	}
#	set compatible [get_comp_str $drv_handle]
#	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set dphy_en_reg_if [get_property CONFIG.DPY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $dphy_en_reg_if "true"]} {
		add_prop "${node}" "xlnx,dphy-present" boolean $dts_file
	}
	set dphy_lanes [get_property CONFIG.C_DPHY_LANES [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,max-lanes" $dphy_lanes int $dts_file
	set en_csi_v2_0 [get_property CONFIG.C_EN_CSI_V2_0 [hsi::get_cells -hier $drv_handle]]
	set en_vcx [get_property CONFIG.C_EN_VCX [hsi::get_cells -hier $drv_handle]]
	set cmn_vc [get_property CONFIG.CMN_VC [hsi::get_cells -hier $drv_handle]]
	if {$en_csi_v2_0 == true && $en_vcx == true && [string match -nocase $cmn_vc "ALL"]} {
		add_prop "${node}" "xlnx,vc" 16  int $dts_file
	} elseif {$en_csi_v2_0 == false && [string match -nocase $cmn_vc "ALL"]} {
		add_prop "${node}" "xlnx,vc" 4  int $dts_file
	}
	if {[llength $en_csi_v2_0] == 0} {
		add_prop "${node}" "xlnx,vc" $cmn_vc int $dts_file
	}
	set cmn_pxl_format [get_property CONFIG.CMN_PXL_FORMAT [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,csi-pxl-format" $cmn_pxl_format string $dts_file
	set csi_en_activelanes [get_property CONFIG.C_CSI_EN_ACTIVELANES [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $csi_en_activelanes "true"]} {
		add_prop "${node}" "xlnx,en-active-lanes" boolean $dts_file
	}
	set cmn_inc_vfb [get_property CONFIG.CMN_INC_VFB [hsi::get_cells -hier $drv_handle]]
	if {[string match -nocase $cmn_inc_vfb "true"]} {
		add_prop "${node}" "xlnx,vfb" boolean $dts_file
	}
	set cmn_num_pixels [get_property CONFIG.CMN_NUM_PIXELS [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,ppc" "$cmn_num_pixels" int $dts_file
	set axis_tdata_width [get_property CONFIG.AXIS_TDATA_WIDTH [hsi::get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,axis-tdata-width" "$axis_tdata_width" int $dts_file
}
}
