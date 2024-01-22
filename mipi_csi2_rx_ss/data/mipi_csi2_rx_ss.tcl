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

proc mipi_csi2_rx_ss_generate {drv_handle} {
        set node [get_node $drv_handle]
        set dts_file [set_drv_def_dts $drv_handle]
        if {$node == 0} {
                return
        }
	set dphy_en_reg_if [hsi get_property CONFIG.DPY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dpy-en-reg-if" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $dphy_en_reg_if]} {
                add_prop "${node}" "xlnx,dpy-en-reg-if" 0 int $dts_file 1
	}

	set cmn_inc_iic [hsi get_property CONFIG.CMN_INC_IIC [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $cmn_inc_iic]} {
                add_prop "${node}" "xlnx,cmn-inc-iic" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $cmn_inc_iic]} {
                add_prop "${node}" "xlnx,cmn-inc-iic" 0 int $dts_file 1
	}

	set csi_en_crc [hsi get_property CONFIG.C_CSI_EN_CRC [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "true" $csi_en_crc]} {
                add_prop "${node}" "xlnx,csi-en-crc" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $csi_en_crc]} {
                add_prop "${node}" "xlnx,csi-en-crc" 0 int $dts_file 1
	}

	set en_csi_v2_0 [hsi get_property CONFIG.C_EN_CSI_V2_0 [hsi::get_cells -hier $drv_handle]]
        set en_vcx [hsi get_property CONFIG.C_EN_VCX [hsi::get_cells -hier $drv_handle]]

	if  {[string match -nocase "true" $en_vcx]} {
                add_prop "${node}" "xlnx,en-vcx" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $en_vcx]} {
                add_prop "${node}" "xlnx,en-vcx" 0 int $dts_file 1
	}

        set cmn_vc [hsi get_property CONFIG.CMN_VC [hsi::get_cells -hier $drv_handle]]

	if  {[string match -nocase "true" $en_csi_v2_0]} {
                add_prop "${node}" "xlnx,en-csi-v2" 1 int $dts_file 1
        } elseif {[string match -nocase "false" $en_csi_v2_0]} {
                add_prop "${node}" "xlnx,en-csi-v2" 0 int $dts_file 1
	}

	set dphymode [hsi get_property CONFIG.C_DPHY_MODE [hsi::get_cells -hier $drv_handle]]
        if  {[string match -nocase "master" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 1 int $dts_file 1
        } elseif {[string match -nocase "slave" $dphymode]} {
                add_prop "${node}" "xlnx,dphy-mode" 0 int $dts_file 1
	}

        if { [string match -nocase "true" $en_csi_v2_0] && [string match -nocase "true" $en_vcx] && [string match -nocase $cmn_vc "ALL"]} {
                add_prop "${node}" "xlnx,cmn-vc" 16  int $dts_file 1
        } elseif {[string match -nocase "true" $en_csi_v2_0] && [string match -nocase "false" $en_vcx]  && [string match -nocase $cmn_vc "ALL"]} {
                add_prop "${node}" "xlnx,cmn-vc" 4  int $dts_file 1
        } elseif {[string match -nocase "false" $en_csi_v2_0] && [string match -nocase $cmn_vc "ALL"]} {
                add_prop "${node}" "xlnx,cmn-vc" 4  int $dts_file 1
        }
        if {[llength $en_csi_v2_0] == 0} {
                add_prop "${node}" "xlnx,cmn-vc" $cmn_vc int $dts_file 1
        }

	set highaddr [hsi get_property CONFIG.C_HIGHADDR  [hsi get_cells -hier $drv_handle]]
	add_prop "${node}" "xlnx,highaddr" $highaddr hexint $dts_file 1

	set emb [hsi get_property CONFIG.CSI_EMB_NON_IMG  [hsi get_cells -hier $drv_handle]]
	if  {[string match -nocase "true" $emb]} {
		add_prop "${node}" "xlnx,csi-emb-non-img" 1 int $dts_file 1
	} elseif  {[string match -nocase "false" $emb]} {
		add_prop "${node}" "xlnx,csi-emb-non-img" 0 int $dts_file 1
	}

	set cmn_pxl_format [hsi get_property CONFIG.CMN_PXL_FORMAT [hsi::get_cells -hier $drv_handle]]
	set cmn_pixel [mipi_csi2_rx_gen_pixel_format $cmn_pxl_format]
	add_prop "${node}" "xlnx,cmn-pxl-format" $cmn_pixel hexint $dts_file 1

	csirx2_add_hier_instances $drv_handle
}

proc csirx2_add_hier_instances {drv_handle} {
	set node [get_node $drv_handle]
	set subsystem_base_addr [get_baseaddr $drv_handle]
	set dts_file [set_drv_def_dts $drv_handle]
	set dphy_en_reg_if [hsi get_property CONFIG.DPY_EN_REG_IF [hsi::get_cells -hier $drv_handle]]
	hsi::current_hw_instance $drv_handle

	#Example :
	#hsi::get_cells -hier -filter {IP_NAME==mipi_csi2_rx_ctrl}
	#csirx_0_rx
	#

	set ip_subcores [dict create]
	dict set ip_subcores "mipi_csi2_rx_ctrl" "csirx"
	dict set ip_subcores "mipi_dphy" "dphy"
#	dict set ip_subcores "hdcp22_rx" "hdcp22"
	foreach ip [dict keys $ip_subcores] {

		if { $ip eq "mipi_dphy"} {
			if {[string match -nocase "false" $dphy_en_reg_if]} {
				continue
			}
		}
		set ip_handle [hsi::get_cells -hier -filter "IP_NAME==$ip"]
		set ip_prefix [dict get $ip_subcores $ip]
		if {![string_is_empty $ip_handle]} {
			add_prop "$node" "${ip_prefix}-present" 1 int $dts_file
			add_prop "$node" "${ip_prefix}-connected" $ip_handle reference $dts_file
		} else {
			add_prop "$node" "${ip_prefix}-present" 0 int $dts_file
		}
	}

	hsi::current_hw_instance
}
proc mipi_csi2_rx_gen_pixel_format {pxl_format} {
	set pixel_format ""
            switch $pxl_format {
                   "YUV422_8bit" {
                           set pixel_format 0x18
                   }
                   "YUV422_10bit" {
                           set pixel_format 0x1f
                   }
                   "RGB444" {
                           set pixel_format 0x20
                   }
                   "RGB555" {
                           set pixel_format 0x21
                   }
                   "RGB565" {
                           set pixel_format 0x22
                   }
                   "RGB666" {
                           set pixel_format 0x23
                   }
                   "RGB888" {
                           set pixel_format 0x24
                   }
                   "RAW6" {
                           set pixel_format 0x28
                   }
                   "RAW7" {
                           set pixel_format 0x29
                   }
                   "RAW8" {
                           set pixel_format 0x2a
                   }
                   "RAW10" {
                           set pixel_format 0x2b
                   }
                   "RAW12" {
                           set pixel_format 0x2c
                   }
                   "RAW14" {
                           set pixel_format 0x2d
                   }
                   "RAW16" {
                           set pixel_format 0x2e
                   }
                   "RAW20" {
                           set pixel_format 0x2f
                   }
            }
	return $pixel_format
}
