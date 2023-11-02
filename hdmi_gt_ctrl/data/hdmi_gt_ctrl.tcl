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

        set transceiver [hsi get_property CONFIG.Transceiver [hsi get_cells -hier $drv_handle]]
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
                        "GTYP" {
                                add_prop "${node}" "xlnx,transceiver-type" 8 int $dts_file
                        }
        }

        set gt_direction [hsi get_property CONFIG.C_GT_DIRECTION [hsi get_cells -hier $drv_handle]]
        switch $gt_direction {
                        "SIMPLEX_TX" {
                                add_prop "${node}" "xlnx,gt-direction" 1  int $dts_file 1
                        }
                        "SIMPLEX_RX" {
                                add_prop "${node}" "xlnx,gt-direction" 2  int $dts_file 1
                        }
                        "DUPLEX" {
                                add_prop "${node}" "xlnx,gt-direction" 3  int $dts_file 1
                        }
        }
    }


