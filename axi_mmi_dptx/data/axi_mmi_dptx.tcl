#
# (C) Copyright 2025 Advanced Micro Devices, Inc. All Rights Reserved.
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

    proc axi_mmi_dptx_generate {drv_handle} {
        # Generate properties required for mmi dptx node
        set node [get_node $drv_handle]
        if {$node == 0} {
           return
        }
        set dts_file [set_drv_def_dts $drv_handle]

        set hdcp_1x [hsi get_property CONFIG.C_HDCP1.3_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        if {[string match -nocase $hdcp_1x "1"]} {
            add_prop $node "xlnx,hdcp-1x" boolean $dts_file
        }

        set hdcp_2x [hsi get_property CONFIG.C_HDCP2.3_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        if {[string match -nocase $hdcp_2x "1"]} {
            add_prop $node "xlnx,hdcp-2x" boolean $dts_file
        }

        set hpd_mio [hsi get_property CONFIG.C_DP_HPD [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        add_prop $node "xlnx,dp-hpd" "$hpd_mio" string $dts_file

        set num_lanes [hsi get_property CONFIG.C_DP_LANES [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        if {[string match -nocase $num_lanes "x1"]} {
            add_prop $node "xlnx,dp-lanes" 1 int $dts_file
        }
        if {[string match -nocase $num_lanes "x2"]} {
            add_prop $node "xlnx,dp-lanes" 2 int $dts_file
        }
        if {[string match -nocase $num_lanes "x4"]} {
            add_prop $node "xlnx,dp-lanes" 4 int $dts_file
        }

        set mst_mode [hsi get_property CONFIG.C_MST_MODE_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        if {![string match -nocase $mst_mode "0"]} {
            add_prop $node "xlnx,mst-mode-en" boolean $dts_file
        }

        set edp_en [hsi get_property CONFIG.C_EDP_EN [hsi::get_cells -hier -filter IP_NAME==mmi_dc]]
        add_prop $node "xlnx,edp-en" $edp_en int $dts_file
    }
